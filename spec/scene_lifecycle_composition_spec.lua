local Container = require('lib.ui.core.container')
local Rectangle = require('lib.ui.core.rectangle')
local Scene = require('lib.ui.scene.scene')
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

local function run_public_surface_and_defaults_tests()
    local scene = Scene.new({
        params = {
            name = 'menu',
        },
    })

    assert_equal(UI.Scene, Scene, 'lib.ui should expose the Scene module')
    assert_true(Scene.is_scene(scene), 'Scene.is_scene should recognize scene instances')
    assert_equal(scene.params.name, 'menu', 'Scene should preserve params')
    assert_true(not scene:_is_created(), 'Scene should not run creation eagerly')
    assert_true(not scene:_is_runtime_managed(),
        'Detached scenes should not report runtime ownership')
    assert_true(not scene:_is_runtime_active(),
        'Detached scenes should start inactive')
    assert_equal(#scene:getChildren(), 0,
        'A Scene with no content should remain valid and empty')

    assert_error(function()
        Scene.new({ sceneName = 'menu' })
    end, 'does not support prop "sceneName"',
        'Scene should reject unsupported construction props')

    assert_error(function()
        scene.visible = false
    end, 'does not support prop "visible"',
        'Scene should reject unsupported post-construction props')
end

local function run_runtime_mount_and_stage_sizing_tests()
    local stage = Stage.new({ width = 320, height = 180 })
    local scene = Scene.new()

    assert_error(function()
        stage.baseSceneLayer:addChild(scene)
    end, 'Composer-managed',
        'Scenes should reject direct mounting outside Composer-managed runtime flow')

    scene:_mount_to_runtime(stage.baseSceneLayer, {})
    stage:update()

    assert_true(scene:_is_runtime_managed(),
        'Mounting through the runtime helper should establish runtime ownership')
    assert_equal(scene.parent, stage.baseSceneLayer,
        'Mounted scenes should attach to the base scene layer')
    assert_rectangle_equal(scene:getLocalBounds(), Rectangle.new(0, 0, 320, 180),
        'Scenes should fill the stage-sized runtime layer by default')

    stage:destroy()
end

local function run_composition_validity_tests()
    local scene = Scene.new()
    local parent = Container.new({ width = 100, height = 100 })
    local nested_scene = Scene.new()
    local runtime_wrapper = Container.new({ width = 40, height = 40 })
    local fake_runtime_utility = Container.new({ width = 20, height = 20 })

    rawset(fake_runtime_utility, '_ui_composer_instance', true)
    runtime_wrapper:addChild(fake_runtime_utility)

    assert_error(function()
        parent:addChild(scene)
    end, 'Composer-managed',
        'Scenes should reject arbitrary non-runtime parents')

    assert_error(function()
        scene:addChild(nested_scene)
    end, 'direct child scenes',
        'Scenes should reject direct child scenes')

    assert_error(function()
        scene:addChild(runtime_wrapper)
    end, 'runtime utility descendants',
        'Scenes should reject runtime utilities anywhere in their content subtree')
end

local function run_lifecycle_and_input_gating_tests()
    local stage = Stage.new({ width = 200, height = 120 })
    local scene = Scene.new({
        params = {
            token = 'alpha',
        },
    })
    local calls = {}
    local child = Container.new({
        tag = 'content',
        interactive = true,
        width = 60,
        height = 40,
    })

    function scene:onCreate(params)
        calls[#calls + 1] = 'create:' .. params.token
        self:addChild(child)
    end

    function scene:onEnterBefore()
        calls[#calls + 1] = 'enter-before'
    end

    function scene:onEnterAfter()
        calls[#calls + 1] = 'enter-after'
    end

    function scene:onLeaveBefore()
        calls[#calls + 1] = 'leave-before'
    end

    function scene:onLeaveAfter()
        calls[#calls + 1] = 'leave-after'
    end

    scene:_mount_to_runtime(stage.baseSceneLayer, {})
    scene:_create_if_needed()
    scene:_create_if_needed()

    assert_equal(calls[1], 'create:alpha',
        'Scene creation should fire exactly once with the stored params')
    assert_equal(#calls, 1, 'Repeated create checks should not rerun onCreate')

    stage:update()
    assert_nil(stage:resolveTarget(10, 10),
        'Inactive scenes should receive no input events')

    scene:_run_enter_before()
    assert_true(not scene:_is_runtime_active(),
        'Enter-before should not commit active state on its own')
    scene:_set_runtime_active(true)
    scene:_run_enter_after()

    stage:update()
    assert_equal(stage:resolveTarget(10, 10), child,
        'Active scenes should participate in Stage input routing')

    scene:_run_leave_before()
    assert_true(scene:_is_runtime_active(),
        'Leave-before should preserve active state until Composer deactivates the scene')
    scene:_set_runtime_active(false)
    scene:_run_leave_after()

    stage:update()
    assert_nil(stage:resolveTarget(10, 10),
        'Deactivated scenes should stop receiving routed input')

    assert_equal(calls[2], 'enter-before',
        'Enter-before should run before active-state commit completion')
    assert_equal(calls[3], 'enter-after',
        'Enter-after should run after active-state commit')
    assert_equal(calls[4], 'leave-before',
        'Leave-before should run before deactivation')
    assert_equal(calls[5], 'leave-after',
        'Leave-after should run after deactivation')

    stage:destroy()
end

local function run_hook_error_determinism_tests()
    local stage = Stage.new({ width = 120, height = 90 })
    local scene = Scene.new()
    local child = Container.new({
        interactive = true,
        width = 40,
        height = 30,
    })

    function scene:onCreate()
        self:addChild(child)
    end

    function scene:onEnterBefore()
        error('enter-before failed', 0)
    end

    scene:_mount_to_runtime(stage.baseSceneLayer, {})
    scene:_create_if_needed()

    assert_error(function()
        scene:_run_enter_before()
    end, 'enter-before failed',
        'Scene lifecycle hook errors should surface deterministically')
    assert_true(not scene:_is_runtime_active(),
        'A failed enter-before hook must not leave active state indeterminate')

    stage:update()
    assert_nil(stage:resolveTarget(5, 5),
        'Failed activation should leave the scene inactive for input routing')

    stage:destroy()
end

local function run_destroy_hook_tests()
    local stage = Stage.new({ width = 80, height = 60 })
    local scene = Scene.new()
    local destroy_calls = 0

    function scene:onDestroy()
        destroy_calls = destroy_calls + 1
    end

    scene:_mount_to_runtime(stage.baseSceneLayer, {})
    scene:destroy()

    assert_equal(destroy_calls, 1,
        'Scene destruction should fire the destruction hook exactly once')
    assert_true(scene._destroyed == true,
        'Scene destruction should destroy the scene subtree')

    stage:destroy()
end

local SceneLifecycleCompositionSpec = {}

function SceneLifecycleCompositionSpec.run()
    run_public_surface_and_defaults_tests()
    run_runtime_mount_and_stage_sizing_tests()
    run_composition_validity_tests()
    run_lifecycle_and_input_gating_tests()
    run_hook_error_determinism_tests()
    run_destroy_hook_tests()
end

return SceneLifecycleCompositionSpec
