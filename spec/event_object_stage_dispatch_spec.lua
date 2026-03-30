local Container = require('lib.ui.core.container')
local Event = require('lib.ui.event.event')
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

local function assert_nil(value, message)
    if value ~= nil then
        error(message .. ': expected nil, got ' .. tostring(value), 2)
    end
end

local function run_event_object_contract_tests()
    local stage = Stage.new({ width = 200, height = 120 })
    local child = Container.new({
        interactive = true,
        x = 20,
        y = 15,
        width = 50,
        height = 30,
    })

    stage.baseSceneLayer:addChild(child)
    stage:update()

    local event = Event.new({
        type = 'ui.activate',
        timestamp = 123,
        target = child,
        currentTarget = child,
        path = { stage, stage.baseSceneLayer, child },
        pointerType = 'mouse',
        x = 25,
        y = 20,
        button = 1,
    })

    assert_equal(event.type, 'ui.activate',
        'Event objects should preserve type')
    assert_equal(event.path[1], stage,
        'Event paths should preserve the resolved ancestry')
    assert_equal(event.localX, 5,
        'Spatial event payloads should resolve localX from currentTarget')
    assert_equal(event.localY, 5,
        'Spatial event payloads should resolve localY from currentTarget')

    event:_set_current_target(stage)

    assert_equal(event.localX, 25,
        'Changing currentTarget should recompute localX relative to the new node')
    assert_equal(event.localY, 20,
        'Changing currentTarget should recompute localY relative to the new node')

    event:preventDefault()
    event:stopPropagation()
    event:stopImmediatePropagation()

    assert_true(event.defaultPrevented,
        'preventDefault should mark the event as default-prevented')
    assert_true(event.propagationStopped,
        'stopPropagation should mark propagationStopped')
    assert_true(event.immediatePropagationStopped,
        'stopImmediatePropagation should mark immediatePropagationStopped')

    local focus_event = Event.new({
        type = 'ui.focus.change',
        timestamp = 456,
        previousTarget = stage,
        nextTarget = child,
    })

    assert_equal(focus_event.previousTarget, stage,
        'Focus event payloads should preserve previousTarget')
    assert_equal(focus_event.nextTarget, child,
        'Focus event payloads should preserve nextTarget')

    stage:destroy()
end

local function run_stage_dispatch_normalization_tests()
    local stage = Stage.new({ width = 200, height = 120 })
    local child = Container.new({
        interactive = true,
        x = 20,
        y = 15,
        width = 50,
        height = 30,
    })

    stage.baseSceneLayer:addChild(child)
    stage:update()

    local press_delivery = stage:deliverInput({
        kind = 'mousepressed',
        x = 30,
        y = 20,
        button = 1,
    })

    assert_equal(press_delivery.intent, 'Activate',
        'Pointer press should still map to the Activate logical family internally')
    assert_nil(press_delivery.event,
        'Pointer press should not dispatch a public activation event yet')
    assert_equal(press_delivery.target, child,
        'Pointer press should resolve the initial gesture target')

    local release_delivery = stage:deliverInput({
        kind = 'mousereleased',
        x = 30,
        y = 20,
        button = 1,
    })

    assert_true(release_delivery.dispatched,
        'Pointer release should dispatch the public activation event for a tap')
    assert_equal(release_delivery.event.type, 'ui.activate',
        'Tap release should normalize to ui.activate')
    assert_equal(release_delivery.event.target, child,
        'Pointer activation should preserve the gesture target')

    stage:deliverInput({
        kind = 'mousepressed',
        x = 30,
        y = 20,
        button = 1,
    })

    local drag_start = stage:deliverInput({
        kind = 'mousemoved',
        x = 40,
        y = 31,
    })

    assert_equal(drag_start.event.type, 'ui.drag',
        'Crossing the internal drag threshold should dispatch ui.drag')
    assert_equal(drag_start.event.dragPhase, 'start',
        'The first dispatched drag event should be the start phase')
    assert_equal(drag_start.event.originX, 30,
        'Drag events should preserve the gesture originX')
    assert_equal(drag_start.event.originY, 20,
        'Drag events should preserve the gesture originY')

    local drag_move = stage:deliverInput({
        kind = 'mousemoved',
        x = 44,
        y = 35,
    })

    assert_equal(drag_move.event.dragPhase, 'move',
        'Subsequent pointer motion should dispatch drag move events')
    assert_equal(drag_move.event.deltaX, 14,
        'Drag move events should expose cumulative deltaX')
    assert_equal(drag_move.event.deltaY, 15,
        'Drag move events should expose cumulative deltaY')

    local drag_end = stage:deliverInput({
        kind = 'mousereleased',
        x = 44,
        y = 35,
        button = 1,
    })

    assert_equal(drag_end.event.type, 'ui.drag',
        'Releasing an active drag should dispatch a drag event, not a second activation')
    assert_equal(drag_end.event.dragPhase, 'end',
        'Drag release should dispatch the end phase')

    local navigate = stage:deliverInput({
        kind = 'keypressed',
        key = 'tab',
        shift = true,
    })

    assert_equal(navigate.event.type, 'ui.navigate',
        'Tab should normalize to ui.navigate')
    assert_equal(navigate.event.direction, 'previous',
        'Shift+Tab should produce previous sequential navigation')
    assert_equal(navigate.event.navigationMode, 'sequential',
        'Tab traversal should be marked as sequential navigation')
    assert_equal(navigate.event.target, stage,
        'Navigate should fall back to Stage when no focus owner is present')

    local scroll = stage:deliverInput({
        kind = 'wheelmoved',
        y = -1,
    })

    assert_equal(scroll.event.type, 'ui.scroll',
        'Mouse wheel input should normalize to ui.scroll')
    assert_equal(scroll.event.deltaY, 40,
        'Wheel deltas should be normalized to positive-down pixel deltas')
    assert_equal(scroll.event.axis, 'vertical',
        'Single-axis wheel input should report the vertical axis')
    assert_equal(scroll.event.target, stage,
        'Wheel input without a spatial target should fall back to Stage')

    local spatial_scroll = stage:deliverInput({
        kind = 'wheelmoved',
        x = 0,
        y = -1,
        stageX = 30,
        stageY = 20,
    })

    assert_equal(spatial_scroll.event.target, child,
        'Wheel input with stage coordinates should target the hit node under the pointer')
    assert_equal(spatial_scroll.event.x, 30,
        'Spatial wheel events should preserve stage-space x coordinates on the event payload')
    assert_equal(spatial_scroll.event.y, 20,
        'Spatial wheel events should preserve stage-space y coordinates on the event payload')

    rawset(stage, '_focused_node', child)

    local keyboard_activate = stage:deliverInput({
        kind = 'keypressed',
        key = 'space',
    })

    assert_equal(keyboard_activate.event.type, 'ui.activate',
        'Space with a focused node should dispatch ui.activate')
    assert_equal(keyboard_activate.event.target, child,
        'Keyboard activation should target the focused node')

    local text_input = stage:deliverInput({
        kind = 'textinput',
        text = 'abc',
    })

    assert_equal(text_input.event.type, 'ui.text.input',
        'Committed text entry should dispatch ui.text.input')
    assert_equal(text_input.event.text, 'abc',
        'Text input events should preserve committed text')

    local text_compose = stage:deliverInput({
        kind = 'textedited',
        text = 'ime',
        start = 3,
        length = 2,
    })

    assert_equal(text_compose.event.type, 'ui.text.compose',
        'Composition updates should dispatch ui.text.compose')
    assert_equal(text_compose.event.rangeStart, 3,
        'Composition events should preserve rangeStart')
    assert_equal(text_compose.event.rangeEnd, 5,
        'Composition events should preserve rangeEnd')

    stage:destroy()
end

local function run()
    run_event_object_contract_tests()
    run_stage_dispatch_normalization_tests()
end

return {
    run = run,
}
