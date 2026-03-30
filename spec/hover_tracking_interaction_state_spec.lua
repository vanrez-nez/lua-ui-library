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

local function tag_of(node)
    if node == nil then
        return 'nil'
    end

    return tostring(node.tag)
end

local function attach_hover_log(node, log)
    node._handle_internal_pointer_enter = function(self, payload)
        log[#log + 1] = self.tag .. ' enter ' ..
            tag_of(payload.previousTarget) .. '->' ..
            tag_of(payload.nextTarget)
    end
    node._handle_internal_pointer_leave = function(self, payload)
        log[#log + 1] = self.tag .. ' leave ' ..
            tag_of(payload.previousTarget) .. '->' ..
            tag_of(payload.nextTarget)
    end
end

local function run_hover_transition_tests()
    local stage = Stage.new({ width = 180, height = 120 })
    local left = Container.new({
        tag = 'left',
        interactive = true,
        x = 10,
        y = 10,
        width = 60,
        height = 60,
    })
    local right = Container.new({
        tag = 'right',
        interactive = true,
        x = 90,
        y = 10,
        width = 60,
        height = 60,
    })
    local log = {}

    attach_hover_log(left, log)
    attach_hover_log(right, log)

    stage.baseSceneLayer:addChild(left)
    stage.baseSceneLayer:addChild(right)
    stage:update()

    local first_move = stage:deliverInput({
        kind = 'mousemoved',
        x = 20,
        y = 20,
    })

    assert_true(not first_move.dispatched,
        'Hover movement should not dispatch a public propagation event')
    assert_nil(first_move.event,
        'Hover movement should not create a public event object')
    assert_equal(first_move.target, left,
        'Hover movement should still resolve the current hover candidate')
    assert_equal(rawget(stage, '_hovered_target'), left,
        'Hover ownership should track the current eligible target')
    assert_true(rawget(left, '_hovered') == true,
        'The new hover owner should be marked hovered internally')

    stage:deliverInput({
        kind = 'mousemoved',
        x = 100,
        y = 20,
    })

    assert_equal(rawget(stage, '_hovered_target'), right,
        'Moving between eligible targets should transfer hover ownership')
    assert_true(rawget(left, '_hovered') ~= true,
        'Previous hover owners should clear their internal hovered flag')
    assert_true(rawget(right, '_hovered') == true,
        'New hover owners should receive the internal hovered flag')

    stage:deliverInput({
        kind = 'mousemoved',
        x = 170,
        y = 100,
    })

    assert_nil(rawget(stage, '_hovered_target'),
        'Hover ownership should clear when the pointer leaves all eligible targets')
    assert_true(rawget(right, '_hovered') ~= true,
        'The last hover owner should clear when the pointer leaves the tree')
    assert_sequence(log, {
        'left enter nil->left',
        'left leave left->right',
        'right enter left->right',
        'right leave right->nil',
    }, 'Hover enter and leave notifications should remain deterministic and internal')

    stage:destroy()
end

local function run_hover_consistency_tests()
    local stage = Stage.new({ width = 180, height = 120 })
    local clip_parent = Container.new({
        x = 10,
        y = 10,
        width = 30,
        height = 30,
        clipChildren = true,
    })
    local clipped_child = Container.new({
        tag = 'clipped-child',
        interactive = true,
        width = 80,
        height = 80,
    })
    local hidden_target = Container.new({
        tag = 'hidden-target',
        interactive = true,
        x = 90,
        y = 10,
        width = 40,
        height = 40,
    })

    clip_parent:addChild(clipped_child)
    stage.baseSceneLayer:addChild(clip_parent)
    stage.baseSceneLayer:addChild(hidden_target)
    stage:update()

    stage:deliverInput({
        kind = 'mousemoved',
        x = 20,
        y = 20,
    })

    assert_equal(rawget(stage, '_hovered_target'), clipped_child,
        'Hover should resolve descendants that are still inside active clips')

    stage:deliverInput({
        kind = 'mousemoved',
        x = 60,
        y = 20,
    })

    assert_nil(rawget(stage, '_hovered_target'),
        'Hover should clear when the pointer moves into a clipped-out region')

    stage:deliverInput({
        kind = 'mousemoved',
        x = 100,
        y = 20,
    })

    assert_equal(rawget(stage, '_hovered_target'), hidden_target,
        'Hover should acquire newly targeted eligible nodes')

    hidden_target.visible = false
    stage:update()

    assert_nil(rawget(stage, '_hovered_target'),
        'Hover should clear during synchronization when the current owner becomes effectively hidden')
    assert_true(rawget(hidden_target, '_hovered') ~= true,
        'Hidden nodes should not retain stale internal hover ownership')

    stage:destroy()
end

local function run_mouse_hold_gating_tests()
    local stage = Stage.new({ width = 220, height = 140 })
    local left = Container.new({
        tag = 'left',
        interactive = true,
        x = 10,
        y = 10,
        width = 60,
        height = 60,
    })
    local right = Container.new({
        tag = 'right',
        interactive = true,
        x = 120,
        y = 10,
        width = 60,
        height = 60,
    })

    stage.baseSceneLayer:addChild(left)
    stage.baseSceneLayer:addChild(right)
    stage:update()

    stage:deliverInput({
        kind = 'mousemoved',
        x = 20,
        y = 20,
    })
    stage:deliverInput({
        kind = 'mousepressed',
        x = 20,
        y = 20,
        button = 1,
    })

    local drag_start = stage:deliverInput({
        kind = 'mousemoved',
        x = 130,
        y = 20,
    })

    assert_equal(drag_start.event.type, 'ui.drag',
        'Large pointer movement with the button held should still normalize to drag')
    assert_equal(rawget(stage, '_hovered_target'), left,
        'Hover ownership should remain unchanged while the mouse button is held')

    stage:deliverInput({
        kind = 'mousereleased',
        x = 130,
        y = 20,
        button = 1,
    })

    assert_equal(rawget(stage, '_hovered_target'), right,
        'Hover ownership should refresh to the mouse release position once the button is no longer held')

    stage:destroy()
end

local function run()
    run_hover_transition_tests()
    run_hover_consistency_tests()
    run_mouse_hold_gating_tests()
end

return {
    run = run,
}
