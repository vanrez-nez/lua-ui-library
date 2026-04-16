local Rule = require('lib.ui.utils.rule')
local Schema = require('lib.ui.utils.schema')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error(message .. ': expected nil, got ' .. tostring(value), 2)
    end
end

local function assert_error(fn, needle, message)
    local ok, err = pcall(fn)

    if ok then
        error(message .. ': expected an error', 2)
    end

    local text = tostring(err)

    if needle and not text:find(needle, 1, true) then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
    end
end

local function assert_valid(rule, name, value, message)
    local ok, err = pcall(Rule.validate, rule, name, value)

    if not ok then
        error(message .. ': unexpected error "' .. tostring(err) .. '"', 2)
    end
end

local function assert_invalid(rule, name, value, needle, message)
    assert_error(function()
        Rule.validate(rule, name, value)
    end, needle, message)
end

local function run_descriptor_tests()
    local string_rule = Rule.string({
        optional = true,
        default = 'fallback',
        non_empty = true,
        min_len = 2,
        max_len = 8,
        pattern = '^%a+$',
    })
    local number_rule = Rule.number({
        default = 4,
        min = 1,
        max = 10,
        integer = true,
        finite = false,
    })
    local boolean_rule = Rule.boolean(true)
    local table_rule = Rule.table({ optional = true })
    local enum_rule = Rule.enum({ 'left', 'center', 'right' }, { default = 'left' })
    local size_rule = Rule.size_value({ default = 'fill', allow_content = true })

    assert_equal(string_rule.kind, 'string',
        'Rule.string should create a string descriptor')
    assert_true(string_rule.optional,
        'Rule.string should preserve optional descriptors')
    assert_true(string_rule.has_default,
        'Rule.string should mark defaulted descriptors')
    assert_equal(string_rule.default, 'fallback',
        'Rule.string should preserve defaults')
    assert_true(string_rule.non_empty,
        'Rule.string should preserve non_empty constraints')
    assert_equal(string_rule.min_len, 2,
        'Rule.string should preserve min_len constraints')
    assert_equal(string_rule.max_len, 8,
        'Rule.string should preserve max_len constraints')
    assert_equal(string_rule.pattern, '^%a+$',
        'Rule.string should preserve pattern constraints')

    assert_equal(number_rule.kind, 'number',
        'Rule.number should create a number descriptor')
    assert_equal(number_rule.default, 4,
        'Rule.number should preserve defaults')
    assert_equal(number_rule.min, 1,
        'Rule.number should preserve min bounds')
    assert_equal(number_rule.max, 10,
        'Rule.number should preserve max bounds')
    assert_true(number_rule.integer,
        'Rule.number should preserve integer constraints')
    assert_equal(number_rule.finite, false,
        'Rule.number should allow finite checks to be disabled')

    assert_equal(boolean_rule.kind, 'boolean',
        'Rule.boolean should create a boolean descriptor')
    assert_equal(boolean_rule.default, true,
        'Rule.boolean shorthand should become a default')
    assert_equal(table_rule.kind, 'table',
        'Rule.table should create a table descriptor')
    assert_true(table_rule.optional,
        'Rule.table should preserve optional descriptors')
    assert_equal(enum_rule.kind, 'enum',
        'Rule.enum should create an enum descriptor')
    assert_true(enum_rule.allowed.center,
        'Rule.enum should build an allowed-value lookup')
    assert_equal(enum_rule.display, 'left, center, right',
        'Rule.enum should preserve ordered display text')
    assert_equal(size_rule.kind, 'size_value',
        'Rule.size_value should create a size descriptor')
    assert_true(size_rule.allow_content,
        'Rule.size_value should preserve allow_content')
end

local function run_validation_tests()
    local string_rule = Rule.string({
        non_empty = true,
        min_len = 2,
        max_len = 5,
        pattern = '^%a+$',
    })
    local number_rule = Rule.number({ min = 0, max = 10, integer = true })
    local finite_rule = Rule.number({ finite = true })
    local enum_rule = Rule.enum({ 'row', 'column' })
    local size_rule = Rule.size_value()
    local intrinsic_size_rule = Rule.size_value({ allow_content = true })

    assert_valid(string_rule, 'name', 'Alpha',
        'Rule.validate should accept valid strings')
    assert_invalid(string_rule, 'name', '', 'name: must not be empty',
        'Rule.validate should reject empty strings')
    assert_invalid(string_rule, 'name', 'A', 'name must be >= 2',
        'Rule.validate should reject strings shorter than min_len')
    assert_invalid(string_rule, 'name', 'abcdef', 'name must be <= 5',
        'Rule.validate should reject strings longer than max_len')
    assert_invalid(string_rule, 'name', 'ab1', 'name must match: ^%a+$',
        'Rule.validate should reject strings that miss the pattern')
    assert_invalid(string_rule, 'name', 12, 'name must be a string',
        'Rule.validate should reject non-string values')

    assert_valid(number_rule, 'count', 4,
        'Rule.validate should accept valid numbers')
    assert_invalid(number_rule, 'count', 4.5, 'count must be an integer',
        'Rule.validate should reject non-integer numbers')
    assert_invalid(number_rule, 'count', -1, 'count must be >= 0',
        'Rule.validate should reject numbers below min')
    assert_invalid(number_rule, 'count', 11, 'count must be <= 10',
        'Rule.validate should reject numbers above max')
    assert_invalid(finite_rule, 'count', 0 / 0, 'count must be a finite number',
        'Rule.validate should reject NaN when finite is enabled')

    assert_valid(Rule.boolean(), 'enabled', false,
        'Rule.validate should accept booleans')
    assert_invalid(Rule.boolean(), 'enabled', 'false', 'enabled must be a boolean',
        'Rule.validate should reject non-booleans')
    assert_valid(Rule.table(), 'options', {},
        'Rule.validate should accept tables')
    assert_invalid(Rule.table(), 'options', 'x', 'options must be a table',
        'Rule.validate should reject non-tables')

    assert_valid(enum_rule, 'direction', 'row',
        'Rule.validate should accept enum members')
    assert_invalid(enum_rule, 'direction', 'grid', 'direction: must be one of: row, column',
        'Rule.validate should reject values outside an enum')

    assert_valid(size_rule, 'width', 100,
        'Rule.size_value should accept numbers')
    assert_valid(size_rule, 'width', 'fill',
        'Rule.size_value should accept fill')
    assert_valid(size_rule, 'width', '50%',
        'Rule.size_value should accept percentage strings')
    assert_invalid(size_rule, 'width', 'content',
        'width: "content" requires an intrinsic measurement rule',
        'Rule.size_value should reject content unless allowed')
    assert_valid(intrinsic_size_rule, 'width', 'content',
        'Rule.size_value should accept content when allow_content is true')
    assert_invalid(size_rule, 'width', 'auto',
        'width: must be a number, "fill", "content", or a percentage string',
        'Rule.size_value should reject unsupported strings')
end

local function run_nil_and_resolve_tests()
    local required = Rule.string()
    local optional = Rule.string({ optional = true })
    local defaulted = Rule.string({ default = 'fallback' })
    local value, err

    assert_invalid(required, 'label', nil, 'label: is required',
        'Rule.validate should reject nil for required rules')
    assert_valid(optional, 'label', nil,
        'Rule.validate should accept nil for optional rules')
    assert_valid(defaulted, 'label', nil,
        'Rule.validate should accept nil for defaulted rules')

    value, err = Rule.resolve(required, nil)
    assert_nil(value, 'Rule.resolve should return nil for missing required values')
    assert_equal(err, 'is required',
        'Rule.resolve should report required missing values')

    value, err = Rule.resolve(optional, nil)
    assert_nil(value, 'Rule.resolve should return nil for optional missing values')
    assert_nil(err, 'Rule.resolve should not report optional missing values')

    value, err = Rule.resolve(defaulted, nil)
    assert_equal(value, 'fallback',
        'Rule.resolve should return defaults for missing defaulted values')
    assert_nil(err, 'Rule.resolve should not report defaulted missing values')

    value, err = Rule.resolve(defaulted, 'explicit')
    assert_equal(value, 'explicit',
        'Rule.resolve should preserve explicit values')
    assert_nil(err, 'Rule.resolve should not report explicit values')
end

local function run_option_guard_tests()
    assert_error(function()
        Rule.string({ typo = true })
    end, 'Rule: unknown option "typo"',
        'Rule.string should reject unknown options')

    assert_error(function()
        Rule.number({ min_exclusive = 0 })
    end, 'Rule: unknown option "min_exclusive"',
        'Rule.number should reject unknown options')

    assert_error(function()
        Rule.size_value({ deferred = true })
    end, 'Rule: unknown option "deferred"',
        'Rule.size_value should reject unknown options')
end

local function run_composite_rule_tests()
    local any_rule = Rule.any_of({
        Rule.number({ integer = true }),
        Rule.string({ pattern = '^auto$' }),
    })
    local all_rule = Rule.all_of({
        Rule.string({ min_len = 3 }),
        Rule.string({ pattern = '^%a+$' }),
    })

    assert_valid(any_rule, 'value', 4,
        'Rule.any_of should accept values matching the first inner rule')
    assert_valid(any_rule, 'value', 'auto',
        'Rule.any_of should accept values matching a later inner rule')
    assert_invalid(any_rule, 'value', 'manual', 'value: did not match any allowed type',
        'Rule.any_of should reject values that match no inner rule')

    assert_valid(all_rule, 'token', 'Alpha',
        'Rule.all_of should accept values matching every inner rule')
    assert_invalid(all_rule, 'token', 'Ab1', 'token must match: ^%a+$',
        'Rule.all_of should reject values that fail any inner rule')
end

local function run_optional_derivation_tests()
    local base = Rule.number({ min = 0, max = 10, default = 5 })
    local optional = Rule.optional(base)

    assert_true(optional.optional,
        'Rule.optional should mark derived rules optional')
    assert_equal(optional.has_default, false,
        'Rule.optional should remove defaults from derived rules')
    assert_nil(optional.default,
        'Rule.optional should clear default values')
    assert_equal(optional.min, 0,
        'Rule.optional should copy lower bounds')
    assert_equal(optional.max, 10,
        'Rule.optional should copy upper bounds')
    assert_valid(optional, 'count', nil,
        'Rule.optional should accept nil')
    assert_invalid(optional, 'count', 11, 'count must be <= 10',
        'Rule.optional should retain copied constraints')
    assert_equal(base.default, 5,
        'Rule.optional should not mutate the base rule')
end

local function run_schema_binding_tests()
    local host = { width = '50%' }
    local rules = {
        width = Rule.size_value({ default = 'fill' }),
        alpha = Rule.number({ min = 0, max = 1, default = 1 }),
        label = Rule.string({ optional = true }),
    }
    local schema = Schema.create(host, rules)
    local bindings = schema:get_bindings()

    assert_nil(host.alpha,
        'Schema.create should not apply defaults immediately')
    assert_equal(schema:get_rule('width').property, 'width',
        'Schema.get_rule should return bindings by property name')
    assert_equal(schema:get_rule('width').rule, rules.width,
        'Schema.get_rule should expose the bound rule')
    assert_equal(schema:get_rule('width').host, host,
        'Schema.get_rule should bind rules to the host')
    assert_nil(schema:get_rule('missing'),
        'Schema.get_rule should return nil for unknown properties')

    assert_equal(bindings.width.rule, rules.width,
        'Schema.get_bindings should include existing bindings')
    bindings.width = nil
    assert_true(schema:get_rule('width') ~= nil,
        'Schema.get_bindings should return a detached binding map')
end

local function run_schema_default_and_validation_tests()
    local host = {
        width = '50%',
        alpha = 0.5,
    }
    local schema = Schema.create(host, {
        width = Rule.size_value({ default = 'fill' }),
        height = Rule.size_value({ default = 'fill' }),
        alpha = Rule.number({ min = 0, max = 1, default = 1 }),
        label = Rule.string({ optional = true }),
    })

    schema:set_defaults()

    assert_equal(host.width, '50%',
        'Schema.set_defaults should preserve existing values by default')
    assert_equal(host.height, 'fill',
        'Schema.set_defaults should fill missing defaulted values')
    assert_equal(host.alpha, 0.5,
        'Schema.set_defaults should not overwrite existing defaulted values')

    schema:set_defaults(true)

    assert_equal(host.width, 'fill',
        'Schema.set_defaults(true) should overwrite existing defaulted values')
    assert_equal(host.alpha, 1,
        'Schema.set_defaults(true) should overwrite existing numeric defaults')

    host.alpha = 0.75
    schema:validate()

    host.alpha = 2
    assert_error(function()
        schema:validate()
    end, 'alpha must be <= 1',
        'Schema.validate should report failures using the bound property name')
end

local function run_schema_copy_tests()
    local child_host = { value = 8 }
    local parent_host = { value = 'parent', extra = 4 }
    local child_schema = Schema.create(child_host, {
        value = Rule.number({ min = 0, max = 10 }),
    })
    local parent_schema = Schema.create(parent_host, {
        value = Rule.string(),
        extra = Rule.number({ default = 3 }),
    })

    child_schema:copy_from(parent_schema, false)

    assert_equal(child_schema:get_rule('value').host, child_host,
        'Schema.copy_from without overwrite should keep existing child bindings')
    assert_equal(child_schema:get_rule('extra').host, parent_host,
        'Schema.copy_from should copy missing parent bindings')

    parent_host.extra = 5
    child_schema:get_rule('extra'):validate()

    parent_host.extra = 'bad'
    assert_error(function()
        child_schema:get_rule('extra'):validate()
    end, 'extra must be a number',
        'Copied bindings should validate against their original host')

    child_schema:copy_from(parent_schema, true)

    assert_equal(child_schema:get_rule('value').host, parent_host,
        'Schema.copy_from with overwrite should replace conflicting bindings')
    assert_equal(child_schema:get_rule('value').rule.kind, 'string',
        'Schema.copy_from with overwrite should replace conflicting rules')
end

local function run()
    run_descriptor_tests()
    run_validation_tests()
    run_nil_and_resolve_tests()
    run_option_guard_tests()
    run_composite_rule_tests()
    run_optional_derivation_tests()
    run_schema_binding_tests()
    run_schema_default_and_validation_tests()
    run_schema_copy_tests()
end

return {
    run = run,
}
