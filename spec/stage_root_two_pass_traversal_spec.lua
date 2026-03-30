local Container = require('lib.ui.core.container')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')
local Stage = require('lib.ui.scene.stage')
local UI = require('lib.ui')

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

local function assert_error(fn, needle, message)
    local ok, err = pcall(fn)

    if ok then
        error(message .. ': expected an error', 2)
    end

    local text = tostring(err)

    if needle and not text:find(needle, 1, true) then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
    end
end

local function assert_rectangle_equal(actual, expected, message)
    assert_true(actual:equals(expected, 1e-9),
        message .. ': expected ' .. tostring(expected) ..
        ', got ' .. tostring(actual))
end

local function with_mock_love(mock_love, callback)
    local previous_love = love
    love = mock_love

    local ok, err = xpcall(callback, debug.traceback)

    love = previous_love

    if not ok then
        error(err, 0)
    end
end

local function run_public_surface_and_singleton_tests()
    local stage = Stage.new({
        width = 320,
        height = 180,
        safeAreaInsets = { 10, 20, 30, 40 },
    })

    assert_equal(UI.Stage, Stage, 'lib.ui should expose the Stage module')
    assert_true(Stage.is_stage(stage), 'Stage.is_stage should recognize stage instances')
    assert_equal(stage.parent, nil, 'Stage should have no parent')
    assert_equal(stage.width, 320, 'Stage should preserve width')
    assert_equal(stage.height, 180, 'Stage should preserve height')
    assert_true(stage.safeAreaInsets == Insets.new(10, 20, 30, 40),
        'Stage should normalize safeAreaInsets')

    local children = stage:getChildren()

    assert_equal(#children, 2, 'Stage should own exactly two direct children')
    assert_equal(children[1], stage.baseSceneLayer,
        'Stage should expose the base scene layer as the first direct child')
    assert_equal(children[2], stage.overlayLayer,
        'Stage should expose the overlay layer as the second direct child')
    assert_true(stage.baseSceneLayer._ui_container_instance == true,
        'baseSceneLayer should be a Container')
    assert_true(stage.overlayLayer._ui_container_instance == true,
        'overlayLayer should be a Container')

    assert_error(function()
        Stage.new({ width = '100%', height = 1 })
    end, 'Stage.width',
        'Stage should reject non-numeric width values')

    assert_error(function()
        Stage.new({ width = 1, height = 1, visible = false })
    end, 'does not support prop "visible"',
    'Stage should reject unsupported Container props at construction')

    assert_error(function()
        Stage.new({ width = 1, height = 1 })
    end, 'more than one Stage instance',
    'Creating more than one live Stage should fail deterministically')

    stage:destroy()

    local replacement = Stage.new({ width = 64, height = 64 })

    assert_equal(replacement.width, 64,
        'Destroying a Stage should release the singleton slot for a new instance')

    replacement:destroy()
end

local function run_runtime_ownership_tests()
    local stage = Stage.new({ width = 200, height = 100 })
    local child = Container.new({ width = 20, height = 20 })
    local parent = Container.new({ width = 20, height = 20 })

    assert_error(function()
        stage:addChild(child)
    end, 'runtime-managed',
    'Stage should reject arbitrary direct-child insertion')

    assert_error(function()
        stage:removeChild(stage.baseSceneLayer)
    end, 'cannot be removed directly',
    'Stage should reject direct layer removal')

    assert_error(function()
        parent:addChild(stage)
    end, 'must not have a parent',
    'Stage should fail deterministically when another container attempts to parent it')

    assert_error(function()
        stage.visible = false
    end, 'does not support prop "visible"',
    'Stage should reject unsupported Container props after construction')

    assert_equal(#parent:getChildren(), 0,
        'Failed parenting attempts should not mutate the prospective parent tree')

    stage:destroy()
end

local function run_viewport_and_safe_area_tests()
    local stage = Stage.new({
        width = 320,
        height = 180,
        safeAreaInsets = {
            top = 10,
            right = 20,
            bottom = 30,
            left = 40,
        },
    })

    assert_rectangle_equal(stage:getViewport(), Rectangle.new(0, 0, 320, 180),
        'Stage should expose the full viewport bounds')
    assert_true(stage:getSafeArea() == Insets.new(10, 20, 30, 40),
        'Stage should expose safe-area insets through getSafeArea')
    assert_rectangle_equal(stage:getSafeAreaBounds(),
        Rectangle.new(40, 10, 260, 140),
        'Stage should expose safe-area bounds derived from viewport minus insets')

    stage:update()

    assert_rectangle_equal(stage.baseSceneLayer:getLocalBounds(),
        Rectangle.new(0, 0, 320, 180),
        'baseSceneLayer should fill the Stage viewport after update')
    assert_rectangle_equal(stage.overlayLayer:getLocalBounds(),
        Rectangle.new(0, 0, 320, 180),
        'overlayLayer should fill the Stage viewport after update')

    stage:resize(640, 360, { 12, 24, 36, 48 })

    assert_equal(stage.width, 640, 'Stage resize should update width')
    assert_equal(stage.height, 360, 'Stage resize should update height')
    assert_true(stage.safeAreaInsets == Insets.new(12, 24, 36, 48),
        'Stage resize should update safe-area insets')
    assert_rectangle_equal(stage:getSafeAreaBounds(),
        Rectangle.new(48, 12, 568, 312),
        'Stage resize should update safe-area bounds')

    stage:destroy()
end

local function run_environment_synchronization_tests()
    local viewport = { 320, 180 }
    local safe_area = { 40, 10, 260, 140 }

    with_mock_love({
        graphics = {
            getDimensions = function()
                return viewport[1], viewport[2]
            end,
        },
        window = {
            getSafeArea = function()
                return safe_area[1], safe_area[2], safe_area[3], safe_area[4]
            end,
        },
    }, function()
        local stage = Stage.new()

        assert_equal(stage.width, 320,
            'Stage width reads should synchronize from the host environment')
        assert_equal(stage.height, 180,
            'Stage height reads should synchronize from the host environment')
        assert_true(stage.safeAreaInsets == Insets.new(10, 20, 30, 40),
            'Stage safeAreaInsets reads should synchronize from the host environment')
        assert_rectangle_equal(stage:getSafeAreaBounds(),
            Rectangle.new(40, 10, 260, 140),
            'Stage safe-area bounds should reflect synchronized host state')

        viewport = { 640, 360 }
        safe_area = { 48, 12, 568, 312 }

        assert_equal(stage.width, 640,
            'Stage width should refresh when the host viewport changes')
        assert_equal(stage.height, 360,
            'Stage height should refresh when the host viewport changes')
        assert_true(stage.safeAreaInsets == Insets.new(12, 24, 36, 48),
            'Stage safeAreaInsets should refresh when the host safe area changes')
        assert_rectangle_equal(stage:getViewport(),
            Rectangle.new(0, 0, 640, 360),
            'Stage viewport bounds should track host updates')
        assert_rectangle_equal(stage:getSafeAreaBounds(),
            Rectangle.new(48, 12, 568, 312),
            'Stage safe-area bounds should track host updates')

        stage:destroy()
    end)
end

local function run_overlay_precedence_and_input_boundary_tests()
    local stage = Stage.new({ width = 300, height = 200 })
    local base_child = Container.new({
        tag = 'base-child',
        interactive = true,
        width = 120,
        height = 120,
        zIndex = 99,
    })
    local overlay_child = Container.new({
        tag = 'overlay-child',
        interactive = true,
        width = 120,
        height = 120,
        zIndex = -99,
    })

    stage.baseSceneLayer:addChild(base_child)
    stage.overlayLayer:addChild(overlay_child)
    stage:update()

    local order = {}

    stage:draw({}, function(node)
        order[#order + 1] = node.tag
    end)

    assert_equal(order[1], 'base scene layer',
        'Stage draw traversal should enter the base scene layer first')
    assert_equal(order[2], 'base-child',
        'Base-scene descendants should draw before overlay descendants')
    assert_equal(order[3], 'overlay layer',
        'Stage draw traversal should visit the overlay layer after the base layer')
    assert_equal(order[4], 'overlay-child',
        'Overlay descendants should draw after base-scene descendants')

    assert_equal(stage:resolveTarget(10, 10), overlay_child,
        'Overlay target resolution should take precedence over base-scene zIndex')

    local pressed_delivery = stage:deliverInput({
        kind = 'mousepressed',
        x = 10,
        y = 10,
        button = 1,
    })

    assert_equal(pressed_delivery.intent, 'Activate',
        'Stage:deliverInput should translate raw pointer activation into a logical intent')
    assert_nil(pressed_delivery.event,
        'Pointer press should buffer the activation gesture without dispatching a public event yet')
    assert_equal(pressed_delivery.target, overlay_child,
        'Stage:deliverInput should still resolve the hit target through the Stage-owned boundary')
    assert_equal(pressed_delivery.path[1], stage,
        'Resolved input paths should start at the Stage root')
    assert_equal(pressed_delivery.path[2], stage.overlayLayer,
        'Resolved input paths should include the overlay layer when it wins precedence')
    assert_equal(pressed_delivery.path[3], overlay_child,
        'Resolved input paths should end at the deepest eligible target')

    local released_delivery = stage:deliverInput({
        kind = 'mousereleased',
        x = 10,
        y = 10,
        button = 1,
    })

    assert_true(released_delivery.dispatched,
        'Pointer release should dispatch the public activation event once the gesture resolves')
    assert_equal(released_delivery.event.type, 'ui.activate',
        'Resolved pointer activation should create a ui.activate event')
    assert_equal(released_delivery.event.pointerType, 'mouse',
        'Pointer activation should preserve pointer type on the event payload')
    assert_equal(released_delivery.event.currentTarget, overlay_child,
        'New events should default currentTarget to the resolved target before propagation')
    assert_equal(released_delivery.event.localX, 10,
        'Spatial event payloads should expose localX relative to currentTarget')
    assert_equal(released_delivery.event.localY, 10,
        'Spatial event payloads should expose localY relative to currentTarget')

    stage.overlayLayer.visible = false

    assert_equal(stage:resolveTarget(10, 10), base_child,
        'When the overlay layer is hidden, target resolution should fall through to base content')

    stage:destroy()
end

local function run_two_pass_tests()
    local stage = Stage.new({ width = 100, height = 80 })

    assert_error(function()
        stage:draw()
    end, 'Stage.draw() called without a preceding Stage.update() in this frame',
    'Stage draw should hard-fail before a successful update pass')

    stage:update()
    stage:draw()

    assert_error(function()
        stage:draw()
    end, 'Stage.draw() called without a preceding Stage.update() in this frame',
    'Stage draw should clear the update token after a successful draw pass')

    stage:destroy()
end

local function run_update_token_invalidation_tests()
    local stage = Stage.new({ width = 120, height = 90 })
    local child = Container.new({ width = 20, height = 20 })

    stage.baseSceneLayer:addChild(child)
    stage:update()

    child.width = 40
    child:getLocalBounds()

    assert_error(function()
        stage:draw()
    end, 'Stage.draw() called without a preceding Stage.update() in this frame',
    'Read-time synchronization must not satisfy the Stage update token')

    stage:update()
    stage:draw()

    stage:destroy()
end

local function run_queued_state_change_tests()
    local stage = Stage.new({ width = 160, height = 90 })
    local child = Container.new({ width = 10, height = 10 })
    local order = {}

    stage.baseSceneLayer:addChild(child)

    stage:_queue_state_change(function()
        order[#order + 1] = 'first'
        child.x = 24
        stage:_queue_state_change(function()
            order[#order + 1] = 'third'
            child.y = 12
        end)
    end)

    stage:_queue_state_change(function()
        order[#order + 1] = 'second'
    end)

    stage:update()

    assert_equal(order[1], 'first',
        'Queued state changes should process in FIFO order')
    assert_equal(order[2], 'second',
        'Queued state changes should preserve existing FIFO order')
    assert_equal(order[3], 'third',
        'Nested queued state changes should run after earlier queued work')
    assert_equal(child.x, 24,
        'Queued state changes should commit authoritative mutations during update')
    assert_equal(child.y, 12,
        'Nested queued state changes should commit authoritative mutations during update')
    assert_true(not child._world_transform_dirty,
        'Queued state changes should leave geometry resolved before Stage.update returns')
    assert_true(not child._bounds_dirty,
        'Queued state changes should leave bounds resolved before Stage.update returns')

    stage:draw()
    stage:destroy()
end

local function run()
    run_public_surface_and_singleton_tests()
    run_runtime_ownership_tests()
    run_viewport_and_safe_area_tests()
    run_environment_synchronization_tests()
    run_overlay_precedence_and_input_boundary_tests()
    run_two_pass_tests()
    run_update_token_invalidation_tests()
    run_queued_state_change_tests()
end

return {
    run = run,
}
