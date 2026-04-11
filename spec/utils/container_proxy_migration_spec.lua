local Container = require('lib.ui.core.container')
local Proxy = require('lib.ui.utils.proxy')
local Rule = require('lib.ui.utils.rule')

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

local function run_responsive_override_round_trip_tests()
    local node = Container.new({
        x = 5,
        width = 100,
        height = 20,
    })

    node:_refresh_if_dirty()
    node:_set_resolved_responsive_overrides('compact', {
        x = 30,
        width = '50%',
    })

    assert_equal(node.x, 30,
        'Responsive override reads should resolve through the proxy read hook')
    assert_equal(node.width, '50%',
        'Responsive override reads should expose the override value for width')
    assert_equal(Proxy.raw_get(node, 'x'), 5,
        'Responsive override reads should preserve the authored raw x value')
    assert_equal(Proxy.raw_get(node, 'width'), 100,
        'Responsive override reads should preserve the authored raw width value')
end

local function run_layout_offset_bypass_tests()
    local node = Container.new({
        x = 1,
        y = 2,
        width = 10,
        height = 10,
    })
    local change_count = 0

    node.props:watch('x', function()
        change_count = change_count + 1
    end)
    node.props:watch('y', function()
        change_count = change_count + 1
    end)

    node:_set_layout_offset(20, 30)

    assert_equal(change_count, 0,
        'Layout-owned offset writes should bypass public on_change watchers')
end

local function run_measurement_context_bypass_tests()
    local node = Container.new({
        width = 10,
        height = 10,
    })
    local change_count = 0

    Proxy.on_change(node, '_measurement_context_width', function()
        change_count = change_count + 1
    end)
    Proxy.on_change(node, '_measurement_context_height', function()
        change_count = change_count + 1
    end)

    node:_set_measurement_context(80, 40)

    assert_equal(change_count, 0,
        'Measurement-context writes should bypass on_change hooks')
end

local function run_dirty_clearing_tests()
    local node = Container.new({
        width = 10,
        height = 10,
    })

    node:_refresh_if_dirty()
    node.width = 20

    assert_true(node.dirty:is_dirty('measurement'),
        'Public size writes should mark the measurement domain dirty')
    assert_true(node.dirty:is_dirty('local_transform'),
        'Public size writes should mark the local-transform domain dirty')

    node:_refresh_if_dirty()

    assert_false(node.dirty:is_dirty('responsive'),
        'Refresh should clear the responsive domain after the responsive phase runs')
    assert_false(node.dirty:is_dirty('measurement'),
        'Refresh should clear the measurement domain after the measurement phase runs')
    assert_false(node.dirty:is_dirty('local_transform'),
        'Refresh should clear the local-transform domain after the transform phase runs')
    assert_false(node.dirty:is_dirty('world_transform'),
        'Refresh should clear the world-transform domain after the world phase runs')
    assert_false(node.dirty:is_dirty('bounds'),
        'Refresh should clear the bounds domain after the bounds phase runs')
end

local function run_schema_set_callback_tests()
    local set_calls = 0
    local node = Container(nil, {
        probe = Rule.number({
            default = 4,
            set = function(target, value)
                set_calls = set_calls + 1
                rawset(target, '_probe_last_set', value)
            end,
        }),
    })

    assert_equal(set_calls, 1,
        'Schema set callbacks should fire for initial defaults during container binding')
    assert_equal(rawget(node, '_probe_last_set'), 4,
        'Schema set callbacks should receive the stored default value')

    node.probe = 9

    assert_equal(set_calls, 2,
        'Schema set callbacks should fire for later public assignments')
    assert_equal(rawget(node, '_probe_last_set'), 9,
        'Schema set callbacks should receive the stored assigned value')
end

local function run()
    run_responsive_override_round_trip_tests()
    run_layout_offset_bypass_tests()
    run_measurement_context_bypass_tests()
    run_dirty_clearing_tests()
    run_schema_set_callback_tests()
end

return {
    run = run,
}
