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

local function run_target_resolution_tests()
    do
        local stage = Stage.new({ width = 200, height = 140 })
        local base = Container.new({
            tag = 'base',
            interactive = true,
            x = 20,
            y = 20,
            width = 80,
            height = 80,
        })
        local overlay = Container.new({
            tag = 'overlay',
            interactive = true,
            x = 20,
            y = 20,
            width = 80,
            height = 80,
        })

        stage.baseSceneLayer:addChild(base)
        stage.overlayLayer:addChild(overlay)
        stage:update()

        assert_equal(stage:resolveTarget(30, 30), overlay,
            'Overlay targets should resolve before base-scene targets')

        overlay.visible = false
        stage:update()

        assert_equal(stage:resolveTarget(30, 30), base,
            'Hidden overlays should fall through to the base scene layer')

        stage:destroy()
    end

    do
        local stage = Stage.new({ width = 220, height = 160 })
        local hidden_parent = Container.new({
            visible = false,
            x = 10,
            y = 10,
            width = 80,
            height = 80,
        })
        local hidden_child = Container.new({
            interactive = true,
            width = 80,
            height = 80,
        })
        local clip_parent = Container.new({
            clipChildren = true,
            x = 100,
            y = 20,
            width = 20,
            height = 20,
        })
        local clip_child = Container.new({
            interactive = true,
            width = 60,
            height = 60,
        })

        hidden_parent:addChild(hidden_child)
        clip_parent:addChild(clip_child)
        stage.baseSceneLayer:addChild(hidden_parent)
        stage.baseSceneLayer:addChild(clip_parent)
        stage:update()

        assert_nil(stage:resolveTarget(30, 30),
            'Target resolution should ignore descendants of effectively hidden ancestors')
        assert_nil(stage:resolveTarget(145, 45),
            'Target resolution should reject descendants clipped out by an ancestor clip')

        stage:destroy()
    end

    do
        local stage = Stage.new({ width = 180, height = 140 })
        local lower = Container.new({
            tag = 'lower',
            interactive = true,
            x = 30,
            y = 20,
            width = 80,
            height = 80,
            zIndex = 1,
        })
        local higher = Container.new({
            tag = 'higher',
            interactive = true,
            x = 30,
            y = 20,
            width = 80,
            height = 80,
            zIndex = 5,
        })
        local later_same_z = Container.new({
            tag = 'later_same_z',
            interactive = true,
            x = 120,
            y = 20,
            width = 40,
            height = 40,
            zIndex = 2,
        })
        local earlier_same_z = Container.new({
            tag = 'earlier_same_z',
            interactive = true,
            x = 120,
            y = 20,
            width = 40,
            height = 40,
            zIndex = 2,
        })

        stage.baseSceneLayer:addChild(lower)
        stage.baseSceneLayer:addChild(higher)
        stage.baseSceneLayer:addChild(earlier_same_z)
        stage.baseSceneLayer:addChild(later_same_z)
        stage:update()

        assert_equal(stage:resolveTarget(50, 40), higher,
            'Higher zIndex siblings should win target resolution')
        assert_equal(stage:resolveTarget(130, 30), later_same_z,
            'Equal-z siblings should resolve in reverse draw order')

        higher.zIndex = 0
        stage:update()

        assert_equal(stage:resolveTarget(50, 40), lower,
            'Lowering a sibling zIndex should expose the next eligible sibling')

        stage:destroy()
    end
end

local function run_propagation_tests()
    do
        local stage = Stage.new({ width = 200, height = 160 })
        local outer = Container.new({
            tag = 'outer',
            x = 20,
            y = 20,
            width = 100,
            height = 100,
        })
        local inner = Container.new({
            tag = 'inner',
            interactive = true,
            x = 20,
            y = 20,
            width = 40,
            height = 40,
        })
        local log = {}

        outer:addChild(inner)
        stage.baseSceneLayer:addChild(outer)

        stage:_add_event_listener('ui.activate', function(event)
            log[#log + 1] = 'stage capture ' .. event.phase
        end, 'capture')
        outer:_add_event_listener('ui.activate', function(event)
            log[#log + 1] = 'outer capture ' .. event.phase
        end, 'capture')
        inner:_add_event_listener('ui.activate', function(event)
            log[#log + 1] = 'inner capture ' .. event.phase
        end, 'capture')
        inner:_add_event_listener('ui.activate', function(event)
            log[#log + 1] = 'inner bubble ' .. event.phase
        end, 'bubble')
        outer:_add_event_listener('ui.activate', function(event)
            log[#log + 1] = 'outer bubble ' .. event.phase
        end, 'bubble')
        stage:_add_event_listener('ui.activate', function(event)
            log[#log + 1] = 'stage bubble ' .. event.phase
        end, 'bubble')
        inner:_set_event_default_action('ui.activate', function(event)
            log[#log + 1] = 'default ' .. event.currentTarget.tag
        end)

        stage:update()

        local delivery = tap(stage, 50, 50)

        assert_true(delivery.dispatched,
            'Tap delivery should dispatch ui.activate for an eligible target')
        assert_equal(delivery.event.target, inner,
            'Activation should target the deepest eligible node')
        assert_sequence(log, {
            'stage capture capture',
            'outer capture capture',
            'inner capture target',
            'inner bubble target',
            'outer bubble bubble',
            'stage bubble bubble',
            'default inner',
        }, 'Propagation should deliver capture, target, bubble, then default action')

        stage:destroy()
    end

    do
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
            log[#log + 1] = 'inner target'
        end, 'bubble')
        outer:_add_event_listener('ui.activate', function(event)
            log[#log + 1] = 'outer bubble 1'
            event:stopPropagation()
        end, 'bubble')
        outer:_add_event_listener('ui.activate', function()
            log[#log + 1] = 'outer bubble 2'
        end, 'bubble')
        stage:_add_event_listener('ui.activate', function()
            log[#log + 1] = 'stage bubble'
        end, 'bubble')
        inner:_set_event_default_action('ui.activate', function()
            log[#log + 1] = 'default'
        end)

        stage:update()
        tap(stage, 40, 40)

        assert_sequence(log, {
            'inner target',
            'outer bubble 1',
            'outer bubble 2',
            'default',
        }, 'stopPropagation should finish the current node, stop later nodes, and preserve the default action')

        stage:destroy()
    end

    do
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

        outer:_add_event_listener('ui.activate', function()
            log[#log + 1] = 'outer capture'
        end, 'capture')
        inner:_add_event_listener('ui.activate', function(event)
            log[#log + 1] = 'inner capture 1'
            event:stopImmediatePropagation()
        end, 'capture')
        inner:_add_event_listener('ui.activate', function()
            log[#log + 1] = 'inner capture 2'
        end, 'capture')
        inner:_add_event_listener('ui.activate', function()
            log[#log + 1] = 'inner bubble'
        end, 'bubble')
        outer:_add_event_listener('ui.activate', function()
            log[#log + 1] = 'outer bubble'
        end, 'bubble')
        inner:_set_event_default_action('ui.activate', function()
            log[#log + 1] = 'default'
        end)

        stage:update()
        tap(stage, 40, 40)

        assert_sequence(log, {
            'outer capture',
            'inner capture 1',
            'default',
        }, 'stopImmediatePropagation should halt the current node immediately and skip later phases')

        stage:destroy()
    end

    do
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

        inner:_add_event_listener('ui.activate', function(event)
            log[#log + 1] = 'target'
            event:preventDefault()
        end, 'bubble')
        outer:_add_event_listener('ui.activate', function()
            log[#log + 1] = 'outer bubble'
        end, 'bubble')
        stage:_add_event_listener('ui.activate', function()
            log[#log + 1] = 'stage bubble'
        end, 'bubble')
        inner:_set_event_default_action('ui.activate', function()
            log[#log + 1] = 'default'
        end)

        stage:update()
        tap(stage, 40, 40)

        assert_sequence(log, {
            'target',
            'outer bubble',
            'stage bubble',
        }, 'preventDefault should suppress the default action without stopping propagation')

        stage:destroy()
    end
end

local function run_no_target_drop_tests()
    local stage = Stage.new({ width = 120, height = 80 })

    stage:update()

    stage:deliverInput({
        kind = 'mousepressed',
        x = 10,
        y = 10,
        button = 1,
    })

    local delivery = stage:deliverInput({
        kind = 'mousereleased',
        x = 10,
        y = 10,
        button = 1,
    })

    assert_true(not delivery.dispatched,
        'Spatial input with no eligible target should be dropped silently')
    assert_nil(delivery.event,
        'Dropped spatial input should not produce an event object')
    assert_nil(delivery.path,
        'Dropped spatial input should not build a propagation path')

    stage:destroy()
end

local function run()
    run_target_resolution_tests()
    run_propagation_tests()
    run_no_target_drop_tests()
end

return {
    run = run,
}
