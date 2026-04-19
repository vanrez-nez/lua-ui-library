local luaunit = require('luaunit')
local Rule = require('lib.ui.utils.rule')
local Schema = require('lib.ui.utils.schema')
local CustomRules = require('lib.ui.schema.custom_rules')

local TestSchema = {}

-- Schema.create

function TestSchema.test_create_returns_schema_with_bindings()
  local host = {}
  local schema = Schema.create(host, {
    x = Rule.number({ default = 0 }),
    y = Rule.number({ default = 0 }),
  })

  luaunit.assertNotNil(schema:get_rule('x'))
  luaunit.assertNotNil(schema:get_rule('y'))
end

function TestSchema.test_create_does_not_mutate_host()
  local host = {}
  Schema.create(host, {
    x = Rule.number({ default = 10 }),
  })

  luaunit.assertNil(host.x)
end

-- set_defaults

function TestSchema.test_set_defaults_writes_default_values()
  local host = {}
  local schema = Schema.create(host, {
    x = Rule.number({ default = 10 }),
    y = Rule.number({ default = 20 }),
  })

  schema:set_defaults()

  luaunit.assertEquals(host.x, 10)
  luaunit.assertEquals(host.y, 20)
end

function TestSchema.test_set_defaults_does_not_overwrite_existing_values()
  local host = { x = 5 }
  local schema = Schema.create(host, {
    x = Rule.number({ default = 10 }),
  })

  schema:set_defaults()

  luaunit.assertEquals(host.x, 5)
end

function TestSchema.test_set_defaults_force_overwrites_existing()
  local host = { x = 5 }
  local schema = Schema.create(host, {
    x = Rule.number({ default = 10 }),
  })

  schema:set_defaults(true)

  luaunit.assertEquals(host.x, 10)
end

function TestSchema.test_set_defaults_skips_rules_without_default()
  local host = {}
  local schema = Schema.create(host, {
    x = Rule.number({ default = 1 }),
    y = Rule.number(),
  })

  schema:set_defaults()

  luaunit.assertEquals(host.x, 1)
  luaunit.assertNil(host.y)
end

function TestSchema.test_set_defaults_writes_nil_default()
  local host = {}
  local schema = Schema.create(host, {
    name = Rule.string({ default = '' }),
  })

  schema:set_defaults()

  luaunit.assertEquals(host.name, '')
end

-- validate

function TestSchema.test_validate_passes_on_valid_values()
  local host = { x = 5, y = 10 }
  local schema = Schema.create(host, {
    x = Rule.number({ min = 0, max = 100 }),
    y = Rule.number({ min = 0, max = 100 }),
  })

  schema:validate()
end

function TestSchema.test_validate_raises_on_invalid_value()
  local host = { x = 200 }
  local schema = Schema.create(host, {
    x = Rule.number({ min = 0, max = 100 }),
  })

  luaunit.assertError(function()
    schema:validate()
  end)
end

function TestSchema.test_validate_accepts_nil_on_optional_field()
  local host = {}
  local schema = Schema.create(host, {
    label = Rule.string({ optional = true }),
  })

  schema:validate()
end

function TestSchema.test_validate_accepts_nil_on_defaulted_field()
  local host = {}
  local schema = Schema.create(host, {
    x = Rule.number({ default = 0 }),
  })

  schema:validate()
end

function TestSchema.test_validate_raises_on_nil_required_field()
  local host = {}
  local schema = Schema.create(host, {
    x = Rule.number(),
  })

  luaunit.assertError(function()
    schema:validate()
  end)
end

-- Binding:set_default

function TestSchema.test_binding_set_default_writes_when_nil()
  local host = {}
  local schema = Schema.create(host, {
    x = Rule.number({ default = 42 }),
  })

  local binding = schema:get_rule('x')
  binding:set_default()

  luaunit.assertEquals(host.x, 42)
end

function TestSchema.test_binding_set_default_skips_when_value_exists()
  local host = { x = 7 }
  local schema = Schema.create(host, {
    x = Rule.number({ default = 42 }),
  })

  local binding = schema:get_rule('x')
  binding:set_default()

  luaunit.assertEquals(host.x, 7)
end

function TestSchema.test_binding_set_default_force_overwrites()
  local host = { x = 7 }
  local schema = Schema.create(host, {
    x = Rule.number({ default = 42 }),
  })

  local binding = schema:get_rule('x')
  binding:set_default(true)

  luaunit.assertEquals(host.x, 42)
end

-- Binding:validate

function TestSchema.test_binding_validate_passes_on_valid()
  local host = { x = 5 }
  local schema = Schema.create(host, {
    x = Rule.number({ min = 0, max = 10 }),
  })

  local binding = schema:get_rule('x')
  binding:validate()
end

function TestSchema.test_binding_validate_raises_on_invalid()
  local host = { x = 15 }
  local schema = Schema.create(host, {
    x = Rule.number({ min = 0, max = 10 }),
  })

  local binding = schema:get_rule('x')
  luaunit.assertError(function()
    binding:validate()
  end)
end

-- Schema:get_bindings

function TestSchema.test_get_bindings_returns_copy()
  local host = {}
  local schema = Schema.create(host, {
    x = Rule.number({ default = 0 }),
  })

  local bindings = schema:get_bindings()
  bindings.x = nil

  luaunit.assertNotNil(schema:get_rule('x'))
end

-- Schema:copy_from

function TestSchema.test_copy_from_merges_bindings()
  local host = {}
  local parent = Schema.create({}, {
    x = Rule.number({ default = 0 }),
  })
  local child = Schema.create(host, {
    y = Rule.number({ default = 0 }),
  })

  child:copy_from(parent)

  luaunit.assertNotNil(child:get_rule('x'))
  luaunit.assertNotNil(child:get_rule('y'))
end

function TestSchema.test_copy_from_no_overwrite_by_default()
  local host = {}
  local parent = Schema.create({}, {
    x = Rule.number({ default = 0 }),
  })
  local child = Schema.create(host, {
    x = Rule.string({ default = 'hello' }),
  })

  child:copy_from(parent, false)

  local binding = child:get_rule('x')
  luaunit.assertEquals(binding.rule.kind, 'string')
end

function TestSchema.test_copy_from_overwrite_when_flagged()
  local host = {}
  local parent = Schema.create({}, {
    x = Rule.number({ default = 0 }),
  })
  local child = Schema.create(host, {
    x = Rule.string({ default = 'hello' }),
  })

  child:copy_from(parent, true)

  local binding = child:get_rule('x')
  luaunit.assertEquals(binding.rule.kind, 'number')
end

-- Full lifecycle

function TestSchema.test_full_lifecycle_create_defaults_validate()
  local host = { width = '50%' }
  local schema = Schema.create(host, {
    width  = CustomRules.size_value({ default = 'fill' }),
    height = CustomRules.size_value({ default = 'fill' }),
    alpha  = Rule.number({ min = 0, max = 1, default = 1 }),
  })

  schema:set_defaults()
  luaunit.assertEquals(host.width, '50%')
  luaunit.assertEquals(host.height, 'fill')
  luaunit.assertEquals(host.alpha, 1)

  schema:validate()

  host.alpha = 2
  luaunit.assertError(function()
    schema:validate()
  end)
end

local M = {}

function M.run()
  local runner = luaunit.LuaUnit.new()
  return runner:runSuiteByInstancesNoCmdLineParsing({
    { 'TestSchema', TestSchema },
  })
end

return M
