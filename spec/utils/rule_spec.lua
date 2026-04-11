local Object = require('lib.cls')
local Color = require('lib.ui.render.color')
local ControlUtils = require('lib.ui.controls.control_utils')
local GraphicsValidation = require('lib.ui.render.graphics_validation')
local Rule = require('lib.ui.utils.rule')
local Schema = require('lib.ui.utils.schema')
local SpacingSchema = require('lib.ui.core.spacing_schema')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function assert_table_equal(actual, expected, message)
    assert_equal(type(actual), 'table', message .. ' should return a table')
    assert_equal(#actual, #expected, message .. ' should preserve array length')

    for index = 1, #expected do
        if math.abs(actual[index] - expected[index]) > 1e-9 then
            error(message .. ': expected [' .. index .. '] = ' .. tostring(expected[index]) ..
                ', got ' .. tostring(actual[index]), 2)
        end
    end
end

local function capture_error(fn)
    local ok, err = pcall(fn)
    if ok then
        error('expected an error', 2)
    end
    return tostring(err):gsub('^.-:%d+: ', '')
end

local function assert_error_message(fn, expected, message)
    assert_equal(capture_error(fn), expected, message)
end

local function validate(rule, value, opts, ctx_name)
    return Rule.validate(rule, (ctx_name or 'Node') .. '.prop', value, opts or {}, 1, opts)
end

local function run_builder_shape_tests()
    local rule = Rule.number({ min = 0, default = 4, required = true, tier = 'dev' })

    assert_true(rule._is_rule == true,
        'Rule builders should tag produced tables as rules')
    assert_equal(rule.default, 4,
        'Rule builders should preserve default values')
    assert_equal(rule.required, true,
        'Rule builders should preserve required flags')
    assert_equal(rule.tier, 'dev',
        'Rule builders should preserve explicit tiers')
end

local function run_enum_tests()
    local rule = Rule.enum({ 'normal', 'add' }, 'normal')

    assert_equal(validate(rule, 'add'), 'add',
        'Rule.enum should accept values present in the allowed set')
    assert_error_message(function()
        validate(rule, 'screen')
    end, "Node.prop: 'screen' is not a valid value — accepted: normal, add",
        'Rule.enum should reject values outside the allowed set with the expected message')
end

local function run_number_tests()
    assert_equal(validate(Rule.number({ min = 0 }), 0), 0,
        'Rule.number should accept values meeting the inclusive minimum')
    assert_equal(validate(Rule.number({ max = 10 }), 10), 10,
        'Rule.number should accept values meeting the inclusive maximum')
    assert_equal(validate(Rule.number({ min_exclusive = 0 }), 0.5), 0.5,
        'Rule.number should accept values above an exclusive minimum')
    assert_equal(validate(Rule.number({ max_exclusive = 5 }), 4.5), 4.5,
        'Rule.number should accept values below an exclusive maximum')
    assert_equal(validate(Rule.number({ finite = true }), 3), 3,
        'Rule.number should accept finite numeric values')

    assert_error_message(function()
        validate(Rule.number({ min = 0 }), -1)
    end, 'Node.prop must be >= 0, got -1',
        'Rule.number should reject values below the minimum')
    assert_error_message(function()
        validate(Rule.number({ max = 10 }), 11)
    end, 'Node.prop must be <= 10, got 11',
        'Rule.number should reject values above the maximum')
    assert_error_message(function()
        validate(Rule.number({ min_exclusive = 0 }), 0)
    end, 'Node.prop must be > 0, got 0',
        'Rule.number should reject values at an exclusive minimum')
    assert_error_message(function()
        validate(Rule.number({ max_exclusive = 5 }), 5)
    end, 'Node.prop must be < 5, got 5',
        'Rule.number should reject values at an exclusive maximum')
    assert_error_message(function()
        validate(Rule.number({ finite = true }), math.huge)
    end, 'Node.prop must be finite, got inf',
        'Rule.number should reject non-finite values when finite is required')
end

local function run_boolean_color_and_opacity_tests()
    assert_equal(validate(Rule.boolean(false), true), true,
        'Rule.boolean should accept boolean values')

    local resolved = validate(Rule.color({ 1, 1, 1, 1 }), '#00ff00')
    assert_table_equal(resolved, { 0, 1, 0, 1 },
        'Rule.color should resolve colors through Color.resolve')

    assert_equal(validate(Rule.opacity(1), 0), 0,
        'Rule.opacity should accept the lower bound')
    assert_equal(validate(Rule.opacity(1), 1), 1,
        'Rule.opacity should accept the upper bound')
    assert_equal(validate(Rule.opacity(1), 0.5), 0.5,
        'Rule.opacity should accept values inside the range')

    assert_error_message(function()
        validate(Rule.opacity(1), -0.1)
    end, 'Node.prop must be in [0, 1], got -0.1',
        'Rule.opacity should reject values below zero')
    assert_error_message(function()
        validate(Rule.opacity(1), 1.1)
    end, 'Node.prop must be in [0, 1], got 1.1',
        'Rule.opacity should reject values above one')
end

local function run_instance_tests()
    local Base = Object:extends('Base')
    local Alt = Object:extends('Alt')
    local Other = Object:extends('Other')

    local base_instance = Base()
    local alt_instance = Alt()
    local other_instance = Other()

    assert_equal(validate(Rule.instance(Base), base_instance), base_instance,
        'Rule.instance should accept an instance of a single class')
    assert_equal(validate(Rule.instance({ Base, Alt }), alt_instance), alt_instance,
        'Rule.instance should accept an instance of any class in the provided array')

    assert_error_message(function()
        validate(Rule.instance(Base), other_instance)
    end, 'Node.prop must be an instance of Base',
        'Rule.instance should reject instances of unrelated classes')
    assert_error_message(function()
        validate(Rule.instance({ Base, Alt }), other_instance)
    end, 'Node.prop must be an instance of one of: Base, Alt',
        'Rule.instance should reject values that do not match any allowed class')
end

local function run_simple_type_rule_tests()
    assert_equal(validate(Rule.table(), { ok = true }).ok, true,
        'Rule.table should accept tables')
    assert_equal(validate(Rule.any(), 'anything'), 'anything',
        'Rule.any should pass values through unchanged')
    assert_equal(validate(Rule.string(), 'hello'), 'hello',
        'Rule.string should accept strings')
    assert_equal(validate(Rule.string({ non_empty = true }), 'hello'), 'hello',
        'Rule.string should accept non-empty strings when requested')

    assert_error_message(function()
        validate(Rule.string({ non_empty = true }), '')
    end, 'Node.prop must not be an empty string',
        'Rule.string should reject empty strings when non_empty is enabled')
end

local function run_normalize_custom_gate_tests()
    local normalized = validate(Rule.normalize(function(value)
        return {
            wrapped = value,
        }
    end), 'x')

    assert_equal(normalized.wrapped, 'x',
        'Rule.normalize should return the normalizer result')

    assert_equal(validate(Rule.custom(function(key, value)
        return key .. '=' .. value
    end), 'ok'), 'Node.prop=ok',
        'Rule.custom should run the supplied validator function')

    local order = {}
    local gated = Rule.gate(function(key, value)
        order[#order + 1] = 'predicate:' .. key .. '=' .. tostring(value)
    end, Rule.number({ min = 0 }))

    assert_equal(validate(gated, 3), 3,
        'Rule.gate should delegate to the wrapped inner rule')
    assert_equal(order[1], 'predicate:Node.prop=3',
        'Rule.gate should run the predicate before the inner rule')
end

local function run_controlled_pair_tests()
    local rule = Rule.controlled_pair('value', 'onValueChange')

    assert_equal(validate(rule, 1, {
        value = 1,
        onValueChange = function() end,
    }), 1,
        'Rule.controlled_pair should accept a value when the callback is present')
    assert_equal(validate(rule, nil, {}), nil,
        'Rule.controlled_pair should accept neither side being present')

    assert_error_message(function()
        validate(rule, 1, {
            value = 1,
        })
    end, capture_error(function()
        ControlUtils.assert_controlled_pair('value', 1, 'onValueChange', nil, 1)
    end),
        'Rule.controlled_pair should preserve the current controlled-value error message')

    assert_error_message(function()
        local callback = function() end
        Rule.validate(
            rule,
            'Node.onValueChange',
            callback,
            { onValueChange = callback },
            1,
            { onValueChange = callback }
        )
    end, 'onValueChange without value when onValueChange implies a controlled value',
        'Rule.controlled_pair should reject a callback without a matching controlled value')
end

local function run_tier_tests()
    local original_tier = Schema.VALIDATION_TIER
    local dev_runs = 0
    local heavy_runs = 0
    local always_runs = 0
    local dev_rule = Rule.custom(function(_, value)
        dev_runs = dev_runs + 1
        return value .. ':dev'
    end, { tier = 'dev' })
    local heavy_rule = Rule.custom(function(_, value)
        heavy_runs = heavy_runs + 1
        return value .. ':heavy'
    end, { tier = 'heavy' })
    local always_rule = Rule.custom(function(_, value)
        always_runs = always_runs + 1
        return value .. ':always'
    end, { tier = 'always' })

    Schema.VALIDATION_TIER = 'always'
    assert_equal(validate(dev_rule, 'x'), 'x',
        'Schema should skip dev-tier rules when the ceiling is always')
    assert_equal(dev_runs, 0,
        'Skipped dev-tier rules should not run at all')
    assert_equal(validate(always_rule, 'x'), 'x:always',
        'Always-tier rules should still run when the ceiling is always')

    Schema.VALIDATION_TIER = 'dev'
    assert_equal(validate(dev_rule, 'x'), 'x:dev',
        'Schema should run dev-tier rules when the ceiling is dev')
    assert_equal(validate(heavy_rule, 'x'), 'x',
        'Schema should skip heavy-tier rules when the ceiling is dev')

    Schema.VALIDATION_TIER = 'heavy'
    assert_equal(validate(heavy_rule, 'x'), 'x:heavy',
        'Schema should run heavy-tier rules when the ceiling is heavy')

    assert_true(Rule.tier_passes('always'),
        'Rule.tier_passes should allow always-tier rules under a heavy ceiling')
    assert_true(Rule.tier_passes('dev'),
        'Rule.tier_passes should allow dev-tier rules under a heavy ceiling')
    assert_true(Rule.tier_passes('heavy'),
        'Rule.tier_passes should allow heavy-tier rules under a heavy ceiling')

    Schema.VALIDATION_TIER = original_tier
end

local function run_error_parity_tests()
    assert_error_message(function()
        validate(Rule.enum(GraphicsValidation.ROOT_BLEND_MODE_VALUES), 'invalid')
    end, capture_error(function()
        GraphicsValidation.validate_root_blend_mode('Node.prop', 'invalid', nil, 1)
    end),
        'Rule.enum should preserve the current observable enum error message format')

    assert_error_message(function()
        validate(Rule.number({ finite = true, min = 0 }), math.huge)
    end, capture_error(function()
        SpacingSchema.check_non_negative_finite('Node.prop', math.huge, 1)
    end),
        'Rule.number should preserve the current finite-number error message format')

    assert_error_message(function()
        validate(Rule.opacity(1), -0.1)
    end, capture_error(function()
        GraphicsValidation.validate_opacity('Node.prop', -0.1, nil, 1)
    end),
        'Rule.opacity should preserve the current opacity error message format')

    assert_error_message(function()
        validate(Rule.color(), 'not-a-color')
    end, capture_error(function()
        Color.resolve('not-a-color')
    end),
        'Rule.color should preserve Color.resolve error messages byte-for-byte')
end

local function run()
    local original_tier = Schema.VALIDATION_TIER
    Schema.VALIDATION_TIER = 'heavy'

    run_builder_shape_tests()
    run_enum_tests()
    run_number_tests()
    run_boolean_color_and_opacity_tests()
    run_instance_tests()
    run_simple_type_rule_tests()
    run_normalize_custom_gate_tests()
    run_controlled_pair_tests()
    run_tier_tests()
    run_error_parity_tests()

    Schema.VALIDATION_TIER = original_tier
end

return {
    run = run,
}
