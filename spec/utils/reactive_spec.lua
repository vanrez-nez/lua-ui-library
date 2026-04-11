local Proxy = require('lib.ui.utils.proxy')
local Reactive = require('lib.ui.utils.reactive')

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

local function run_define_tests()
    local instance = {}
    local props = Reactive(instance)

    props:define({
        count = { default = 3 },
    })

    assert_equal(instance.count, 3,
        'Reactive define should declare defaults through Proxy')
    assert_equal(props:raw_get('count'), 3,
        'Reactive raw_get should read the declared backing value')

    props:define({
        label = {
            get = function(value)
                return tostring(value):upper()
            end,
        },
    })
    instance.label = 'hello'

    assert_equal(instance.label, 'HELLO',
        'Reactive define should register get transforms')
    assert_equal(props:raw_get('label'), 'hello',
        'Reactive raw_get should bypass get transforms')

    props:define({
        status = {
            default = 'idle',
            get = function(value)
                return '[' .. tostring(value) .. ']'
            end,
        },
    })

    assert_equal(instance.status, '[idle]',
        'Reactive define should support default and get together')
    assert_equal(props:raw_get('status'), 'idle',
        'Reactive raw_get should preserve the untransformed stored default')
end

local function run_watch_tests()
    local instance = {}
    local props = Reactive(instance)
    local watch_calls = {}

    props:define({
        value = { default = 1 },
    })
    props:watch('value', function(new, old, key, target)
        watch_calls[#watch_calls + 1] = {
            new = new,
            old = old,
            key = key,
            target = target,
        }
    end)

    instance.value = 2
    instance.value = 2
    instance.value = 3

    assert_equal(#watch_calls, 2,
        'Reactive watch should fire only when the stored value changes')
    assert_equal(watch_calls[1].new, 2,
        'Reactive watch should pass the new value')
    assert_equal(watch_calls[1].old, 1,
        'Reactive watch should pass the previous value')
    assert_equal(watch_calls[1].key, 'value',
        'Reactive watch should pass the property key')
    assert_equal(watch_calls[1].target, instance,
        'Reactive watch should pass the bound instance')
end

local function run_unwatch_tests()
    local instance = {}
    local props = Reactive(instance)
    local calls = 0

    local function watcher()
        calls = calls + 1
    end

    props:define({
        enabled = { default = false },
    })
    props:watch('enabled', watcher)

    instance.enabled = true
    props:unwatch('enabled', watcher)
    instance.enabled = false

    assert_equal(calls, 1,
        'Reactive unwatch should remove watchers by function identity')
end

local function run_raw_set_bypass_tests()
    local instance = {}
    local props = Reactive(instance)
    local watch_calls = 0
    local pre_write_calls = 0

    props:define({
        value = {
            default = 10,
            get = function(value)
                return value * 2
            end,
        },
    })
    props:watch('value', function()
        watch_calls = watch_calls + 1
    end)
    Proxy.on_pre_write(instance, 'value', function(_, value)
        pre_write_calls = pre_write_calls + 1
        return value + 1
    end)

    props:raw_set('value', 99)

    assert_equal(props:raw_get('value'), 99,
        'Reactive raw_set should write directly to backing storage')
    assert_equal(instance.value, 198,
        'Reactive raw_set should not disable future get transforms on normal reads')
    assert_equal(watch_calls, 0,
        'Reactive raw_set should bypass on_change watchers')
    assert_equal(pre_write_calls, 0,
        'Reactive raw_set should bypass pre_write hooks')
end

local function run()
    run_define_tests()
    run_watch_tests()
    run_unwatch_tests()
    run_raw_set_bypass_tests()
end

return {
    run = run,
}
