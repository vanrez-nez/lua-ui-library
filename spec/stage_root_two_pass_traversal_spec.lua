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

    local delivery = stage:deliverInput({
        kind = 'mousepressed',
        x = 10,
        y = 10,
        button = 1,
    })

    assert_equal(delivery.intent, 'Activate',
        'Stage:deliverInput should translate raw pointer activation into a logical intent')
    assert_equal(delivery.target, overlay_child,
        'Stage:deliverInput should resolve targets through the Stage-owned boundary')
    assert_equal(delivery.path[1], stage,
        'Resolved input paths should start at the Stage root')
    assert_equal(delivery.path[2], stage.overlayLayer,
        'Resolved input paths should include the overlay layer when it wins precedence')
    assert_equal(delivery.path[3], overlay_child,
        'Resolved input paths should end at the deepest eligible target')

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

local function run()
    run_public_surface_and_singleton_tests()
    run_runtime_ownership_tests()
    run_viewport_and_safe_area_tests()
    run_overlay_precedence_and_input_boundary_tests()
    run_two_pass_tests()
end

return {
    run = run,
}
