local Proxy = require('lib.ui.utils.proxy')

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

local function assert_false(value, message)
    if value then
        error(message, 2)
    end
end

local function make_instance()
    local Class = {
        greet = function(self)
            return 'hello ' .. tostring(rawget(self, 'label') or 'anon')
        end,
    }

    return setmetatable({
        label = 'proxy',
    }, Class), Class
end

local function run_install_and_passthrough_tests()
    local instance, Class = make_instance()

    assert_false(Proxy.is_installed(instance),
        'Proxy should report not installed before any declaration')

    Proxy.declare(instance, 'tracked')
    local first_metatable = getmetatable(instance)

    Proxy.declare(instance, 'other_tracked')

    assert_true(Proxy.is_installed(instance),
        'Proxy should report installed after declare')
    assert_equal(getmetatable(instance), first_metatable,
        'Proxy install should be idempotent across repeated declare calls')
    assert_equal(instance.greet, Class.greet,
        'Proxy should preserve non-declared method lookup through the original class')
    assert_equal(instance:greet(), 'hello proxy',
        'Proxy should preserve method fallback behavior after install')

    local hook_runs = 0
    Proxy.on_write(instance, 'tracked', function()
        hook_runs = hook_runs + 1
    end)

    instance.untracked = 42

    assert_equal(rawget(instance, 'untracked'), 42,
        'Proxy should rawset non-declared writes onto the instance table')
    assert_equal(hook_runs, 0,
        'Proxy should not run declared hooks for non-declared writes')
end

local function run_default_pipeline_tests()
    local instance = {}
    local events = {}

    Proxy.on_pre_write(instance, 'count', function(key, value)
        events[#events + 1] = 'pre:' .. key .. '=' .. tostring(value)
        return value + 1
    end)
    Proxy.on_write(instance, 'count', function(value, key)
        events[#events + 1] = 'write:' .. key .. '=' .. tostring(value)
    end)
    Proxy.on_change(instance, 'count', function(new, old, key)
        events[#events + 1] = 'change:' .. key .. '=' .. tostring(old) .. '->' .. tostring(new)
    end)

    Proxy.declare(instance, 'count', { default = 4 })

    assert_equal(instance.count, 5,
        'Proxy declare default should flow through pre_write before storing')
    assert_equal(Proxy.raw_get(instance, 'count'), 5,
        'Proxy declare default should store the transformed value in backing data')
    assert_equal(#events, 3,
        'Proxy declare default should execute the write pipeline exactly once')
    assert_equal(events[1], 'pre:count=4',
        'Proxy declare default should run pre_write for the default value')
    assert_equal(events[2], 'write:count=5',
        'Proxy declare default should run on_write after storing the transformed value')
    assert_equal(events[3], 'change:count=nil->5',
        'Proxy declare default should run on_change for the initial default assignment')
end

local function run_read_and_write_hook_tests()
    local instance = {}
    local pre_order = {}
    local write_events = {}
    local change_events = {}

    Proxy.declare(instance, 'name')

    Proxy.on_read(instance, 'name', function(value)
        return 'first:' .. tostring(value)
    end)
    Proxy.on_read(instance, 'name', function(value)
        return 'second:' .. tostring(value)
    end)

    Proxy.on_pre_write(instance, 'name', function(key, value)
        pre_order[#pre_order + 1] = 'one:' .. key .. '=' .. tostring(value)
        return value .. '-a'
    end)
    Proxy.on_pre_write(instance, 'name', function(key, value)
        pre_order[#pre_order + 1] = 'two:' .. key .. '=' .. tostring(value)
        return value .. '-b'
    end)
    Proxy.on_write(instance, 'name', function(value, key)
        write_events[#write_events + 1] = key .. '=' .. tostring(value)
    end)
    Proxy.on_write(instance, 'name', function(value, key)
        write_events[#write_events + 1] = 'again:' .. key .. '=' .. tostring(value)
    end)
    Proxy.on_change(instance, 'name', function(new, old, key)
        change_events[#change_events + 1] = key .. ':' .. tostring(old) .. '->' .. tostring(new)
    end)
    Proxy.on_change(instance, 'name', function(new, old, key)
        change_events[#change_events + 1] = 'again:' .. key .. ':' .. tostring(old) .. '->' .. tostring(new)
    end)

    instance.name = 'value'

    assert_equal(Proxy.raw_get(instance, 'name'), 'value-a-b',
        'Proxy pre_write hooks should run in order and transform the stored value')
    assert_equal(instance.name, 'second:value-a-b',
        'Proxy on_read should be a single slot and the last registration should win')
    assert_equal(pre_order[1], 'one:name=value',
        'Proxy pre_write should receive the original value first')
    assert_equal(pre_order[2], 'two:name=value-a',
        'Proxy pre_write should pass each transformed value to the next hook')
    assert_equal(#write_events, 2,
        'Proxy on_write should run every registered hook')
    assert_equal(write_events[1], 'name=value-a-b',
        'Proxy on_write should receive the stored value')
    assert_equal(write_events[2], 'again:name=value-a-b',
        'Proxy on_write should preserve registration order')
    assert_equal(#change_events, 2,
        'Proxy on_change should run every registered hook when the value changes')

    instance.name = 'value'

    assert_equal(#write_events, 4,
        'Proxy on_write should run even when the incoming assignment does not change the final value')
    assert_equal(#change_events, 2,
        'Proxy on_change should not run when the stored value is unchanged')
end

local function run_off_change_and_raw_access_tests()
    local instance = {}
    local on_write_calls = 0
    local on_change_a = 0
    local on_change_b = 0
    local on_read_calls = 0
    local pre_write_calls = 0

    local function change_a()
        on_change_a = on_change_a + 1
    end

    local function change_b()
        on_change_b = on_change_b + 1
    end

    Proxy.declare(instance, 'count')
    Proxy.on_read(instance, 'count', function(value)
        on_read_calls = on_read_calls + 1
        return (value or 0) * 10
    end)
    Proxy.on_pre_write(instance, 'count', function(_, value)
        pre_write_calls = pre_write_calls + 1
        return value + 1
    end)
    Proxy.on_write(instance, 'count', function()
        on_write_calls = on_write_calls + 1
    end)
    Proxy.on_change(instance, 'count', change_a)
    Proxy.on_change(instance, 'count', change_b)

    Proxy.off_change(instance, 'count', function() end)
    instance.count = 1

    assert_equal(on_change_a, 1,
        'Proxy off_change should be a no-op for unknown functions')
    assert_equal(on_change_b, 1,
        'Proxy off_change should not disturb existing change handlers when the function is unknown')

    Proxy.off_change(instance, 'count', change_a)
    instance.count = 2

    assert_equal(on_change_a, 1,
        'Proxy off_change should remove handlers by function identity')
    assert_equal(on_change_b, 2,
        'Proxy off_change should leave other change handlers installed')

    Proxy.raw_set(instance, 'count', 99)

    assert_equal(pre_write_calls, 2,
        'Proxy raw_set should bypass pre_write hooks')
    assert_equal(on_write_calls, 2,
        'Proxy raw_set should bypass on_write hooks')
    assert_equal(on_change_b, 2,
        'Proxy raw_set should bypass on_change hooks')
    assert_equal(Proxy.raw_get(instance, 'count'), 99,
        'Proxy raw_set should write directly to backing storage')

    assert_equal(Proxy.raw_get(instance, 'count'), 99,
        'Proxy raw_get should return the backing value directly')
    assert_equal(on_read_calls, 0,
        'Proxy raw_get should bypass on_read hooks')
    assert_equal(instance.count, 990,
        'Proxy regular reads should still flow through the installed on_read hook')
    assert_equal(on_read_calls, 1,
        'Proxy regular reads should invoke on_read exactly once per access')
end

local function run()
    run_install_and_passthrough_tests()
    run_default_pipeline_tests()
    run_read_and_write_hook_tests()
    run_off_change_and_raw_access_tests()
end

return {
    run = run,
}
