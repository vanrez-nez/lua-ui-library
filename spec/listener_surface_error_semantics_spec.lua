local Container = require('lib.ui.core.container')
local Stage = require('lib.ui.scene.stage')

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

local function assert_sequence(actual, expected, message)
    if #actual ~= #expected then
        error(message .. ': expected length ' .. tostring(#expected) ..
            ', got ' .. tostring(#actual), 2)
    end

    for index = 1, #expected do
        if actual[index] ~= expected[index] then
            error(message .. ': mismatch at index ' .. tostring(index) ..
                ', expected ' .. tostring(expected[index]) ..
                ', got ' .. tostring(actual[index]), 2)
        end
    end
end

local function tap(stage, x, y)
    stage:deliverInput({
        kind = 'mousepressed',
        x = x,
        y = y,
        button = 1,
    })

    return stage:deliverInput({
        kind = 'mousereleased',
        x = x,
        y = y,
        button = 1,
    })
end

local function run_listener_phase_surface_tests()
    local node = Container.new({})
    local capture_listener = function()
    end
    local bubble_listener = function()
    end
    local shared_listener = function()
    end

    node:_add_event_listener('ui.activate', capture_listener, 'capture')
    node:_add_event_listener('ui.activate', bubble_listener, 'bubble')
    node:_add_event_listener('ui.activate', shared_listener, 'capture')
    node:_add_event_listener('ui.activate', shared_listener, 'bubble')

    local capture_snapshot = node:_get_event_listener_snapshot('ui.activate', 'capture')
    local bubble_snapshot = node:_get_event_listener_snapshot('ui.activate', 'bubble')

    assert_equal(#capture_snapshot, 2,
        'Capture listeners should be stored per phase')
    assert_equal(#bubble_snapshot, 2,
        'Bubble listeners should be stored per phase')
    assert_equal(capture_snapshot[1], capture_listener,
        'Capture listeners should retain registration order')
    assert_equal(capture_snapshot[2], shared_listener,
        'Capture listeners should retain later registrations after earlier ones')
    assert_equal(bubble_snapshot[1], bubble_listener,
        'Bubble listeners should retain registration order')
    assert_equal(bubble_snapshot[2], shared_listener,
        'Bubble listeners should retain later registrations after earlier ones')

    node:_remove_event_listener('ui.activate', shared_listener, 'capture')
    capture_snapshot = node:_get_event_listener_snapshot('ui.activate', 'capture')
    bubble_snapshot = node:_get_event_listener_snapshot('ui.activate', 'bubble')

    assert_equal(#capture_snapshot, 1,
        'Phase-specific removal should leave the other phase untouched')
    assert_equal(#bubble_snapshot, 2,
        'Removing from capture should not affect bubble listeners')

    node:_remove_event_listener('ui.activate', shared_listener)
    bubble_snapshot = node:_get_event_listener_snapshot('ui.activate', 'bubble')

    assert_equal(#bubble_snapshot, 1,
        'Removing without a phase should clear remaining registrations across phases')
end

local function run_duplicate_registration_tests()
    local stage = Stage.new({ width = 160, height = 120 })
    local target = Container.new({
        interactive = true,
        x = 20,
        y = 20,
        width = 40,
        height = 40,
    })
    local calls = 0
    local listener = function()
        calls = calls + 1
    end

    stage.baseSceneLayer:addChild(target)
    target:_add_event_listener('ui.activate', listener, 'bubble')
    target:_add_event_listener('ui.activate', listener, 'bubble')
    stage:update()

    tap(stage, 30, 30)

    assert_equal(calls, 2,
        'Duplicate listener registrations should produce duplicate invocations')

    stage:destroy()
end

local function run_mutation_deferral_tests()
    local stage = Stage.new({ width = 200, height = 160 })
    local outer = Container.new({
        x = 10,
        y = 10,
        width = 120,
        height = 120,
    })
    local inner = Container.new({
        interactive = true,
        x = 20,
        y = 20,
        width = 40,
        height = 40,
    })
    local first_log = {}
    local second_log = {}
    local outer_existing
    local outer_added = function()
        second_log[#second_log + 1] = 'outer added'
        first_log[#first_log + 1] = 'outer added'
    end

    outer_existing = function()
        second_log[#second_log + 1] = 'outer existing'
        first_log[#first_log + 1] = 'outer existing'
    end

    outer:addChild(inner)
    stage.baseSceneLayer:addChild(outer)

    outer:_add_event_listener('ui.activate', outer_existing, 'bubble')
    inner:_add_event_listener('ui.activate', function()
        first_log[#first_log + 1] = 'mutate'
        second_log[#second_log + 1] = 'mutate'
        outer:_add_event_listener('ui.activate', outer_added, 'bubble')
        outer:_remove_event_listener('ui.activate', outer_existing, 'bubble')
    end, 'bubble')
    stage:update()

    tap(stage, 40, 40)

    assert_sequence(first_log, {
        'mutate',
        'outer existing',
    }, 'Listener mutations during dispatch should not affect the active delivery')

    second_log = {}
    tap(stage, 40, 40)

    assert_sequence(second_log, {
        'mutate',
        'outer added',
    }, 'Listener mutations should take effect on the next delivery')

    stage:destroy()
end

local function run_listener_error_tests()
    local stage = Stage.new({ width = 200, height = 160 })
    local outer = Container.new({
        x = 10,
        y = 10,
        width = 120,
        height = 120,
    })
    local inner = Container.new({
        interactive = true,
        x = 20,
        y = 20,
        width = 40,
        height = 40,
    })
    local log = {}

    outer:addChild(inner)
    stage.baseSceneLayer:addChild(outer)

    inner:_add_event_listener('ui.activate', function()
        log[#log + 1] = 'before error'
        error('listener boom', 0)
    end, 'bubble')
    outer:_add_event_listener('ui.activate', function()
        log[#log + 1] = 'outer bubble'
    end, 'bubble')
    inner:_set_event_default_action('ui.activate', function()
        log[#log + 1] = 'default'
    end)
    stage:update()

    local ok, err = pcall(function()
        tap(stage, 40, 40)
    end)

    assert_true(not ok,
        'Listener errors should propagate to the caller')
    assert_true(string.find(tostring(err), 'listener boom', 1, true) ~= nil,
        'Listener errors should preserve the thrown error message')
    assert_sequence(log, {
        'before error',
    }, 'Listener errors should halt the current event delivery immediately')

    stage:destroy()
end

local function run()
    run_listener_phase_surface_tests()
    run_duplicate_registration_tests()
    run_mutation_deferral_tests()
    run_listener_error_tests()
end

return {
    run = run,
}
