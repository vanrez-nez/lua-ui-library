local luaunit = require('luaunit')
local Rule = require('lib.ui.utils.rule')
local Schema = require('lib.ui.utils.schema')
local CustomRules = require('lib.ui.schema.custom_rules')

local TestSchema = {}

-- Schema.create

function TestSchema.test_create_returns_schema_with_rules()
  local schema = Schema.create({
    x = Rule.number({ default = 0 }),
    y = Rule.number({ default = 0 }),
  })

  luaunit.assertNotNil(schema:get_rule('x'))
  luaunit.assertNotNil(schema:get_rule('y'))
end

function TestSchema.test_create_does_not_bind_or_mutate_target()
  local target = {}

  Schema.create({
    x = Rule.number({ default = 10 }),
  })

  luaunit.assertNil(target.x)
end

function TestSchema.test_create_copies_rule_map()
  local rules = {
    x = Rule.number({ default = 10 }),
  }
  local schema = Schema.create(rules)

  rules.x = nil

  luaunit.assertNotNil(schema:get_rule('x'))
end

-- Schema.extend

function TestSchema.test_extend_returns_schema_with_base_and_override_rules()
  local base = Schema.create({
    x = Rule.number({ default = 10 }),
  })

  local child = Schema.extend(base, {
    y = Rule.string({ default = 'hello' }),
  })

  luaunit.assertEquals(child:get_rule('x').kind, 'number')
  luaunit.assertEquals(child:get_rule('y').kind, 'string')
end

function TestSchema.test_extend_does_not_mutate_base_schema()
  local base = Schema.create({
    x = Rule.number({ default = 10 }),
  })

  Schema.extend(base, {
    y = Rule.string({ default = 'hello' }),
  })

  luaunit.assertNil(base:get_rule('y'))
end

function TestSchema.test_extend_overrides_base_rule()
  local base = Schema.create({
    x = Rule.number({ default = 10 }),
  })

  local child = Schema.extend(base, {
    x = Rule.string({ default = 'hello' }),
  })

  luaunit.assertEquals(child:get_rule('x').kind, 'string')
  luaunit.assertEquals(base:get_rule('x').kind, 'number')
end

function TestSchema.test_extend_accepts_nil_overrides()
  local base = Schema.create({
    x = Rule.number({ default = 10 }),
  })

  local child = Schema.extend(base)

  luaunit.assertEquals(child:get_rule('x').kind, 'number')
end

-- get_rules

function TestSchema.test_get_rules_returns_copy()
  local schema = Schema.create({
    x = Rule.number({ default = 0 }),
  })

  local rules = schema:get_rules()
  rules.x = nil

  luaunit.assertNotNil(schema:get_rule('x'))
end

-- set_defaults

function TestSchema.test_set_defaults_writes_default_values_to_target()
  local target = {}
  local schema = Schema.create({
    x = Rule.number({ default = 10 }),
    y = Rule.number({ default = 20 }),
  })

  schema:set_defaults(target)

  luaunit.assertEquals(target.x, 10)
  luaunit.assertEquals(target.y, 20)
end

function TestSchema.test_set_defaults_does_not_overwrite_existing_values()
  local target = { x = 5 }
  local schema = Schema.create({
    x = Rule.number({ default = 10 }),
  })

  schema:set_defaults(target)

  luaunit.assertEquals(target.x, 5)
end

function TestSchema.test_set_defaults_force_overwrites_existing()
  local target = { x = 5 }
  local schema = Schema.create({
    x = Rule.number({ default = 10 }),
  })

  schema:set_defaults(target, true)

  luaunit.assertEquals(target.x, 10)
end

function TestSchema.test_set_defaults_skips_rules_without_default()
  local target = {}
  local schema = Schema.create({
    x = Rule.number({ default = 1 }),
    y = Rule.number(),
  })

  schema:set_defaults(target)

  luaunit.assertEquals(target.x, 1)
  luaunit.assertNil(target.y)
end

function TestSchema.test_set_defaults_writes_empty_string_default()
  local target = {}
  local schema = Schema.create({
    name = Rule.string({ default = '' }),
  })

  schema:set_defaults(target)

  luaunit.assertEquals(target.name, '')
end

-- validate_rule

function TestSchema.test_validate_rule_passes_on_valid_value()
  local target = { x = 5 }
  local schema = Schema.create({
    x = Rule.number({ min = 0, max = 10 }),
  })

  schema:validate_rule('x', target)
end

function TestSchema.test_validate_rule_raises_on_invalid_value()
  local target = { x = 15 }
  local schema = Schema.create({
    x = Rule.number({ min = 0, max = 10 }),
  })

  luaunit.assertError(function()
    schema:validate_rule('x', target)
  end)
end

function TestSchema.test_validate_rule_raises_on_unknown_property()
  local schema = Schema.create({})

  luaunit.assertErrorMsgContains('schema rule not found', function()
    schema:validate_rule('missing', {})
  end)
end

-- validate_all

function TestSchema.test_validate_all_passes_on_valid_values()
  local target = { x = 5, y = 10 }
  local schema = Schema.create({
    x = Rule.number({ min = 0, max = 100 }),
    y = Rule.number({ min = 0, max = 100 }),
  })

  schema:validate_all(target)
end

function TestSchema.test_validate_all_raises_on_invalid_value()
  local target = { x = 200 }
  local schema = Schema.create({
    x = Rule.number({ min = 0, max = 100 }),
  })

  luaunit.assertError(function()
    schema:validate_all(target)
  end)
end

function TestSchema.test_validate_all_accepts_nil_on_optional_field()
  local target = {}
  local schema = Schema.create({
    label = Rule.string({ optional = true }),
  })

  schema:validate_all(target)
end

function TestSchema.test_validate_all_accepts_nil_on_defaulted_field()
  local target = {}
  local schema = Schema.create({
    x = Rule.number({ default = 0 }),
  })

  schema:validate_all(target)
end

function TestSchema.test_validate_all_raises_on_nil_required_field()
  local target = {}
  local schema = Schema.create({
    x = Rule.number(),
  })

  luaunit.assertError(function()
    schema:validate_all(target)
  end)
end

-- Full lifecycle

function TestSchema.test_full_lifecycle_create_defaults_validate()
  local target = { width = '50%' }
  local schema = Schema.create({
    width = CustomRules.size_value({ default = 'fill' }),
    height = CustomRules.size_value({ default = 'fill' }),
    alpha = Rule.number({ min = 0, max = 1, default = 1 }),
  })

  schema:set_defaults(target)
  luaunit.assertEquals(target.width, '50%')
  luaunit.assertEquals(target.height, 'fill')
  luaunit.assertEquals(target.alpha, 1)

  schema:validate_all(target)

  target.alpha = 2
  luaunit.assertError(function()
    schema:validate_all(target)
  end)
end

-- Base initialization

function TestSchema.test_container_new_applies_schema_defaults()
  local Container = require('lib.ui.core.container')
  local node = Container.new({})

  luaunit.assertEquals(node.width, 0)
  luaunit.assertEquals(node.height, 0)
  luaunit.assertEquals(node.visible, true)
  luaunit.assertEquals(node.enabled, true)
end

function TestSchema.test_constructor_opts_override_schema_defaults()
  local Container = require('lib.ui.core.container')
  local node = Container.new({
    width = 42,
    height = 'fill',
    visible = false,
  })

  luaunit.assertEquals(node.width, 42)
  luaunit.assertEquals(node.height, 'fill')
  luaunit.assertEquals(node.visible, false)
end

function TestSchema.test_invalid_schema_backed_opts_fail_during_base_initialization()
  local Container = require('lib.ui.core.container')

  luaunit.assertError(function()
    Container.new({
      x = 'bad',
    })
  end)
end

function TestSchema.test_instances_do_not_raw_own_schema()
  local Container = require('lib.ui.core.container')
  local node = Container.new({})

  luaunit.assertNil(rawget(node, 'schema'))
  luaunit.assertNotNil(Container.schema)
end

function TestSchema.test_derived_class_schema_includes_parent_and_local_rules()
  local Drawable = require('lib.ui.core.drawable')

  luaunit.assertNotNil(Drawable.schema:get_rule('width'))
  luaunit.assertNotNil(Drawable.schema:get_rule('padding'))
end

function TestSchema.test_omitted_spec_optional_fields_do_not_fail_validate_all()
  local Drawable = require('lib.ui.core.drawable')
  local node = Drawable.new({})

  luaunit.assertNil(node.id)
  luaunit.assertNil(node.paddingTop)
  luaunit.assertNil(node.backgroundColor)
end

local M = {}

function M.run()
  local runner = luaunit.LuaUnit.new()
  return runner:runSuiteByInstancesNoCmdLineParsing({
    { 'TestSchema', TestSchema },
  })
end

return M
