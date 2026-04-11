local Reactive = require('lib.ui.utils.reactive')
local Rule = require('lib.ui.utils.rule')
local Schema = require('lib.ui.utils.schema')

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

local function capture_error(fn)
    local ok, err = pcall(fn)
    if ok then
        error('expected an error', 2)
    end
    return tostring(err):gsub('^.-:%d+: ', '')
end

local function run_define_round_trip_tests()
    local instance = {}
    local schema = Schema(instance)

    schema:define({
        value = Rule.number({ min = 0, finite = true }),
    })

    instance.value = 3

    assert_equal(instance.value, 3,
        'Schema binding should allow validated values to round-trip through the proxy store')

    local read_count = 0
    local props = Reactive(instance)
    props:define({
        value = {
            get = function(value)
                read_count = read_count + 1
                return value * 2
            end,
        },
    })

    assert_equal(instance.value, 6,
        'Schema binding should coexist with Reactive reads on the same instance')
    assert_equal(read_count, 1,
        'Reactive read transforms should still apply after schema binding')
end

local function run_pre_write_and_required_tests()
    local instance = {}
    local schema = Schema(instance)

    schema:define({
        opacity = Rule.opacity(),
        name = Rule.custom(function(_, value)
            if value == nil then
                return nil
            end
            return value:upper()
        end, { required = true }),
    })

    instance.opacity = 0.5
    assert_equal(instance.opacity, 0.5,
        'Schema binding should run pre-write validation before storage')

    instance.name = 'ok'
    assert_equal(instance.name, 'OK',
        'Schema binding should store the transformed value returned by rule.validate')

    local missing_required = capture_error(function()
        instance.name = nil
    end)

    assert_equal(missing_required, 'property "name" is required',
        'Schema binding should fail with the required-property message when a required value resolves to nil')
end

local function run_default_and_set_tests()
    local instance = {}
    local schema = Schema(instance)
    local pre_write_calls = 0
    local set_calls = 0

    schema:define({
        count = Rule.custom(function(_, value)
            pre_write_calls = pre_write_calls + 1
            return value + 1
        end, {
            default = 4,
            set = function(target, value)
                set_calls = set_calls + 1
                target.last_set = value
            end,
        }),
    })

    assert_equal(instance.count, 5,
        'Schema binding should assign defaults through the full proxy pipeline')
    assert_equal(pre_write_calls, 1,
        'Schema binding should run pre-write exactly once for a default assignment')
    assert_equal(set_calls, 1,
        'Schema binding should run set once for the default assignment')
    assert_equal(instance.last_set, 5,
        'Schema binding should pass the stored value to the set callback')

    instance.count = 6

    assert_equal(instance.count, 7,
        'Schema binding should continue to run pre-write on later assignments')
    assert_equal(set_calls, 2,
        'Schema binding should run set on every assignment')
    assert_equal(instance.last_set, 7,
        'Schema binding set callbacks should receive the validated value on later assignments')
end

local function run_reactive_order_tests()
    local instance = {}
    local schema = Schema(instance)
    local props = Reactive(instance)
    local events = {}

    schema:define({
        value = Rule.custom(function(_, value)
            events[#events + 1] = 'pre:' .. tostring(value)
            return value + 1
        end),
    })
    props:define({
        value = {},
    })
    props:watch('value', function(new, old)
        events[#events + 1] = 'change:' .. tostring(old) .. '->' .. tostring(new)
    end)

    instance.value = 2

    assert_equal(events[1], 'pre:2',
        'Schema binding pre-write should run before Reactive change watchers')
    assert_equal(events[2], 'change:nil->3',
        'Reactive change watchers should observe the validated value')
end

local function run_tier_tests()
    local instance = {}
    local schema = Schema(instance)
    local original_tier = Schema.VALIDATION_TIER
    local runs = 0

    schema:define({
        value = Rule.custom(function(_, value)
            runs = runs + 1
            return value .. ':dev'
        end, { tier = 'dev' }),
    })

    Schema.VALIDATION_TIER = 'always'
    instance.value = 'x'

    assert_equal(instance.value, 'x',
        'Schema binding should skip pre-write validators above the active validation tier')
    assert_equal(runs, 0,
        'Skipped schema-binding validators should not run')

    Schema.VALIDATION_TIER = 'dev'
    instance.value = 'y'

    assert_equal(instance.value, 'y:dev',
        'Schema binding should run validators whose tier passes the active ceiling')
    assert_equal(runs, 1,
        'Schema binding should run the validator exactly once when the tier passes')

    Schema.VALIDATION_TIER = original_tier
end

local function run()
    local original_tier = Schema.VALIDATION_TIER
    Schema.VALIDATION_TIER = 'heavy'

    run_define_round_trip_tests()
    run_pre_write_and_required_tests()
    run_default_and_set_tests()
    run_reactive_order_tests()
    run_tier_tests()

    Schema.VALIDATION_TIER = original_tier
end

return {
    run = run,
}
