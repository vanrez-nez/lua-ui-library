local Container = require('lib.ui.core.container')
local Stage = require('lib.ui.scene.stage')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error(message .. ': expected nil, got ' .. tostring(value), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
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

local function run_explicit_focus_request_tests()
    local stage = Stage.new({ width = 320, height = 180 })
    local outer = Container.new({
        tag = 'outer',
        focusable = true,
        width = 40,
        height = 20,
    })
    local scope = Container.new({
        width = 120,
        height = 80,
    })
    local inner = Container.new({
        tag = 'inner',
        focusable = true,
        x = 40,
        width = 40,
        height = 20,
    })
    local hidden = Container.new({
        tag = 'hidden',
        focusable = true,
        visible = false,
        width = 40,
        height = 20,
    })

    stage.baseSceneLayer:addChild(outer)
    stage.baseSceneLayer:addChild(scope)
    stage.baseSceneLayer:addChild(hidden)
    scope:addChild(inner)
    stage:_set_focus_contract_internal(scope, {
        scope = true,
    })
    stage:update()

    local focus_log = {}

    inner:_add_event_listener('ui.focus.change', function(event)
        focus_log[#focus_log + 1] = {
            previous = event.previousTarget,
            next = event.nextTarget,
            owner_at_delivery = rawget(stage, '_focus_owner'),
        }
    end, 'bubble')

    stage:_request_focus_internal(outer)
    stage:_request_focus_internal(inner)

    assert_equal(stage:_get_focus_owner_internal(), inner,
        'Explicit focus requests should move focus to eligible nodes')
    assert_equal(#focus_log, 1,
        'Focusing a target should dispatch ui.focus.change to the new owner')
    assert_equal(focus_log[1].previous, outer,
        'Focus change events should report the previous focus owner')
    assert_equal(focus_log[1].next, inner,
        'Focus change events should report the committed new owner')
    assert_equal(focus_log[1].owner_at_delivery, inner,
        'ui.focus.change should fire only after the focus owner commits')

    stage:_request_focus_internal(hidden)

    assert_equal(stage:_get_focus_owner_internal(), inner,
        'Explicit requests for hidden nodes should be ignored')

    local trap = Container.new({
        width = 100,
        height = 60,
    })
    local trapped = Container.new({
        focusable = true,
        width = 30,
        height = 20,
    })

    trap:addChild(trapped)
    stage.overlayLayer:addChild(trap)
    stage:_set_focus_contract_internal(trap, {
        scope = true,
        trap = true,
    })
    stage:_request_focus_internal(outer)

    assert_equal(stage:_get_focus_owner_internal(), trapped,
        'Explicit requests outside an active trap should be ignored')

    stage:destroy()
end

local function run_sequential_traversal_tests()
    local stage = Stage.new({ width = 320, height = 180 })
    local outer_first = Container.new({
        tag = 'outer_first',
        focusable = true,
        width = 40,
        height = 20,
    })
    local scope = Container.new({
        x = 60,
        width = 120,
        height = 60,
    })
    local inner_first = Container.new({
        tag = 'inner_first',
        focusable = true,
        width = 40,
        height = 20,
    })
    local inner_second = Container.new({
        tag = 'inner_second',
        focusable = true,
        x = 50,
        width = 40,
        height = 20,
    })
    local outer_last = Container.new({
        tag = 'outer_last',
        focusable = true,
        x = 200,
        width = 40,
        height = 20,
    })

    stage.baseSceneLayer:addChild(outer_first)
    stage.baseSceneLayer:addChild(scope)
    stage.baseSceneLayer:addChild(outer_last)
    scope:addChild(inner_first)
    scope:addChild(inner_second)
    stage:_set_focus_contract_internal(scope, {
        scope = true,
    })
    stage:update()

    stage:deliverInput({
        kind = 'keypressed',
        key = 'tab',
    })

    assert_equal(stage:_get_focus_owner_internal(), outer_first,
        'Sequential traversal should begin from the first outer-scope candidate')

    stage:deliverInput({
        kind = 'keypressed',
        key = 'tab',
    })

    assert_equal(stage:_get_focus_owner_internal(), outer_last,
        'Sequential traversal should skip descendants owned by inactive nested scopes')

    stage:deliverInput({
        kind = 'keypressed',
        key = 'tab',
    })

    assert_equal(stage:_get_focus_owner_internal(), outer_first,
        'Sequential traversal should wrap deterministically at the end of the active scope')

    stage:deliverInput({
        kind = 'keypressed',
        key = 'tab',
        shift = true,
    })

    assert_equal(stage:_get_focus_owner_internal(), outer_last,
        'Previous sequential traversal should wrap deterministically at the start of the scope')

    stage:_request_focus_internal(inner_first)

    stage:deliverInput({
        kind = 'keypressed',
        key = 'tab',
    })

    assert_equal(stage:_get_focus_owner_internal(), inner_second,
        'Sequential traversal should stay within the active nested focus scope')

    stage:deliverInput({
        kind = 'keypressed',
        key = 'tab',
    })

    assert_equal(stage:_get_focus_owner_internal(), inner_first,
        'Sequential traversal should wrap within the active nested focus scope')

    stage:destroy()
end

local function run_directional_and_pointer_coupling_tests()
    local stage = Stage.new({ width = 320, height = 180 })
    local left = Container.new({
        tag = 'left',
        focusable = true,
        x = 10,
        y = 40,
        width = 40,
        height = 20,
    })
    local right = Container.new({
        tag = 'right',
        focusable = true,
        x = 100,
        y = 40,
        width = 40,
        height = 20,
    })
    local coupled = Container.new({
        tag = 'coupled',
        interactive = true,
        focusable = true,
        x = 10,
        y = 110,
        width = 40,
        height = 20,
    })
    local uncoupled = Container.new({
        tag = 'uncoupled',
        interactive = true,
        focusable = true,
        x = 80,
        y = 110,
        width = 40,
        height = 20,
    })

    stage.baseSceneLayer:addChild(left)
    stage.baseSceneLayer:addChild(right)
    stage.baseSceneLayer:addChild(coupled)
    stage.baseSceneLayer:addChild(uncoupled)
    stage:_set_focus_contract_internal(coupled, {
        pointerFocusCoupling = 'before',
    })
    stage:update()

    stage:_request_focus_internal(right)

    stage:deliverInput({
        kind = 'keypressed',
        key = 'right',
    })

    assert_equal(stage:_get_focus_owner_internal(), right,
        'Directional traversal should be a no-op when no eligible candidate exists')

    local activate_owner = nil

    coupled:_add_event_listener('ui.activate', function()
        activate_owner = rawget(stage, '_focus_owner')
    end, 'bubble')

    tap(stage, 20, 120)

    assert_equal(stage:_get_focus_owner_internal(), coupled,
        'Pointer activation should acquire focus when the component contract couples pointer and focus')
    assert_equal(activate_owner, coupled,
        'Before-coupled pointer focus should commit before ui.activate propagation')

    tap(stage, 90, 120)

    assert_equal(stage:_get_focus_owner_internal(), coupled,
        'Pointer activation should leave focus unchanged when the target has no focus-coupling contract')

    stage:destroy()
end

local function run_overlay_trap_restriction_tests()
    local stage = Stage.new({ width = 320, height = 180 })
    local outside = Container.new({
        tag = 'outside',
        interactive = true,
        focusable = true,
        x = 200,
        y = 40,
        width = 40,
        height = 20,
    })
    local trap = Container.new({
        x = 40,
        y = 30,
        width = 120,
        height = 80,
    })
    local inside_first = Container.new({
        tag = 'inside_first',
        interactive = true,
        focusable = true,
        width = 40,
        height = 20,
    })
    local inside_second = Container.new({
        tag = 'inside_second',
        interactive = true,
        focusable = true,
        y = 30,
        width = 40,
        height = 20,
    })

    trap:addChild(inside_first)
    trap:addChild(inside_second)
    stage.baseSceneLayer:addChild(outside)
    stage.overlayLayer:addChild(trap)
    stage:_set_focus_contract_internal(outside, {
        pointerFocusCoupling = 'before',
    })
    stage:_set_focus_contract_internal(trap, {
        scope = true,
        trap = true,
    })
    stage:update()

    assert_equal(stage:_get_focus_owner_internal(), inside_first,
        'Active overlay traps should move focus into the trapped scope')

    stage:deliverInput({
        kind = 'keypressed',
        key = 'tab',
    })

    assert_equal(stage:_get_focus_owner_internal(), inside_second,
        'Sequential traversal should remain inside the active overlay trap')

    tap(stage, 210, 50)

    assert_equal(stage:_get_focus_owner_internal(), inside_second,
        'Pointer activation outside the active trap should not move focus')

    stage:destroy()
end

local function run()
    run_explicit_focus_request_tests()
    run_sequential_traversal_tests()
    run_directional_and_pointer_coupling_tests()
    run_overlay_trap_restriction_tests()
end

return {
    run = run,
}
