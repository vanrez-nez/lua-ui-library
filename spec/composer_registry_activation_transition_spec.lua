local Container = require('lib.ui.core.container')
local Composer = require('lib.ui.scene.composer')
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

local function assert_contains(haystack, needle, message)
    for index = 1, #haystack do
        if haystack[index] == needle then
            return
        end
    end

    error(message .. ': missing "' .. tostring(needle) .. '"', 2)
end

local function clear_array(values)
    for index = #values, 1, -1 do
        values[index] = nil
    end
end

local function make_scene_factory(name, calls, targets)
    return function()
        local scene = UI.Scene.new()
        local target = Container.new({
            tag = name .. '-target',
            interactive = true,
            width = 24,
            height = 24,
        })

        targets[name] = target

        function scene:onCreate()
            calls[#calls + 1] = name .. ':create'
            self:addChild(target)
        end

        function scene:onEnterBefore()
            calls[#calls + 1] = name .. ':enter-before'
        end

        function scene:onEnterAfter()
            calls[#calls + 1] = name .. ':enter-after'
        end

        function scene:onLeaveBefore()
            calls[#calls + 1] = name .. ':leave-before'
        end

        function scene:onLeaveAfter()
            calls[#calls + 1] = name .. ':leave-after'
        end

        return scene
    end
end

local function make_transition_graphics()
    local graphics = {
        calls = {},
        current_canvas = nil,
        next_canvas_id = 0,
        color = { 1, 1, 1, 1 },
    }

    local function current_target_name()
        if graphics.current_canvas == nil then
            return 'screen'
        end

        return graphics.current_canvas.id
    end

    function graphics.newCanvas(width, height)
        graphics.next_canvas_id = graphics.next_canvas_id + 1

        return {
            id = 'canvas-' .. graphics.next_canvas_id,
            width = width,
            height = height,
        }
    end

    function graphics.getCanvas()
        return graphics.current_canvas
    end

    function graphics.setCanvas(canvas)
        graphics.current_canvas = canvas
        graphics.calls[#graphics.calls + 1] =
            'setCanvas:' .. current_target_name()
    end

    function graphics.clear()
        graphics.calls[#graphics.calls + 1] =
            'clear:' .. current_target_name()
    end

    function graphics.push(_)
    end

    function graphics.pop()
    end

    function graphics.origin()
    end

    function graphics.getColor()
        return graphics.color[1], graphics.color[2], graphics.color[3], graphics.color[4]
    end

    function graphics.setColor(r, g, b, a)
        graphics.color = { r, g, b, a }
        graphics.calls[#graphics.calls + 1] =
            string.format('color:%s:%.2f', current_target_name(), a or 1)
    end

    function graphics.draw(drawable, x, y)
        graphics.calls[#graphics.calls + 1] = string.format(
            'draw:%s:%s:%.2f:%.2f',
            current_target_name(),
            drawable.id or drawable.tag or tostring(drawable),
            x or 0,
            y or 0
        )
    end

    return graphics
end

local function run_public_surface_and_registration_tests()
    local composer = Composer.new({
        defaultTransition = 'fade',
        defaultTransitionDuration = 0.25,
    })

    assert_equal(UI.Composer, Composer,
        'lib.ui should expose the Composer module')
    assert_true(Composer.is_composer(composer),
        'Composer.is_composer should recognize composer instances')
    assert_true(composer.stage ~= nil,
        'Composer should own a Stage instance')
    assert_equal(composer.defaultTransition, 'fade',
        'Composer should preserve defaultTransition')
    assert_equal(composer.defaultTransitionDuration, 0.25,
        'Composer should preserve defaultTransitionDuration')

    composer:register('menu', function()
        return UI.Scene.new()
    end)

    assert_error(function()
        composer:register('menu', function()
            return UI.Scene.new()
        end)
    end, 'already registered',
        'Composer should reject duplicate stable scene names')

    assert_error(function()
        composer:register('bad', {})
    end, 'definition must be a factory function or a table with .new()',
        'Composer should reject invalid scene definitions')

    assert_error(function()
        composer:gotoScene('missing')
    end, 'unknown scene name "missing"',
        'Unknown scene names should hard-fail deterministically')

    composer:destroy()
end

local function run_initial_navigation_and_same_scene_tests()
    local composer = Composer.new()
    local calls = {}
    local targets = {}

    composer:register('alpha', make_scene_factory('alpha', calls, targets))

    composer:gotoScene('alpha', {
        params = {
            token = 'first',
        },
        duration = 0,
    })
    composer:update(0)

    assert_equal(calls[1], 'alpha:create',
        'Initial navigation should create the target scene lazily')
    assert_equal(calls[2], 'alpha:enter-before',
        'Initial navigation should fire enter-before on the target scene')
    assert_equal(calls[3], 'alpha:enter-after',
        'Initial navigation should fire enter-after on the target scene')
    assert_equal(#composer.stage.baseSceneLayer:getChildren(), 1,
        'Stable scene activation should leave exactly one scene mounted')

    local delivery = composer:deliverInput({
        kind = 'mousepressed',
        x = 5,
        y = 5,
        button = 1,
    })

    assert_equal(delivery.target, targets.alpha,
        'Composer should forward root input through the Stage into the active scene subtree')

    clear_array(calls)

    composer:gotoScene('alpha', { duration = 0 })
    composer:update(0)

    assert_equal(calls[1], 'alpha:leave-before',
        'gotoScene to the current scene should still fire leave-before')
    assert_equal(calls[2], 'alpha:enter-before',
        'gotoScene to the current scene should still fire enter-before')
    assert_equal(calls[3], 'alpha:leave-after',
        'gotoScene to the current scene should still fire leave-after')
    assert_equal(calls[4], 'alpha:enter-after',
        'gotoScene to the current scene should still fire enter-after')
    assert_equal(#composer.stage.baseSceneLayer:getChildren(), 1,
        'Same-scene navigation should preserve a single mounted stable scene')

    composer:destroy()
end

local function run_transition_progress_and_completion_tests()
    local composer = Composer.new()
    local calls = {}
    local targets = {}

    composer:register('alpha', make_scene_factory('alpha', calls, targets))
    composer:register('beta', make_scene_factory('beta', calls, targets))

    composer:gotoScene('alpha', { duration = 0 })
    composer:update(0)
    clear_array(calls)

    composer:gotoScene('beta', {
        transition = 'fade',
        duration = 1,
    })
    composer:update(0)

    assert_equal(calls[1], 'alpha:leave-before',
        'Transitioned navigation should fire leave-before before the transition starts')
    assert_equal(calls[2], 'beta:create',
        'Transitioned navigation should still create the incoming scene lazily')
    assert_equal(calls[3], 'beta:enter-before',
        'Transitioned navigation should fire enter-before before completion')
    assert_true(composer.transitionState ~= nil,
        'Composer should expose transition state only while transitioning')
    assert_equal(composer.transitionState.progress, 0,
        'Transition state should begin at zero progress')
    assert_equal(#composer.stage.baseSceneLayer:getChildren(), 2,
        'Transitions should keep outgoing and incoming scenes mounted together')

    local delivery_during_transition = composer:deliverInput({
        kind = 'mousepressed',
        x = 5,
        y = 5,
        button = 1,
    })

    assert_equal(delivery_during_transition.target, targets.alpha,
        'During a transition the active outgoing scene should remain the routed input target')

    clear_array(calls)
    composer:update(0.5)

    assert_true(composer.transitionState ~= nil,
        'Transition state should remain present before completion')
    assert_equal(composer.transitionState.progress, 0.5,
        'Composer should advance transition progress during update')
    assert_equal(#calls, 0,
        'Mid-transition progress should not fire after-hooks early')

    composer:update(0.5)

    assert_nil(composer.transitionState,
        'Composer should clear transition state on completion')
    assert_equal(calls[1], 'alpha:leave-after',
        'Transition completion should fire leave-after on the outgoing scene')
    assert_equal(calls[2], 'beta:enter-after',
        'Transition completion should fire enter-after on the incoming scene')
    assert_equal(#composer.stage.baseSceneLayer:getChildren(), 1,
        'Transition completion should return to one mounted stable scene')

    local delivery_after_transition = composer:deliverInput({
        kind = 'mousepressed',
        x = 5,
        y = 5,
        button = 1,
    })

    assert_equal(delivery_after_transition.target, targets.beta,
        'After completion input should route into the committed incoming scene')

    composer:destroy()
end

local function run_transition_draw_execution_tests()
    local composer = Composer.new()
    local calls = {}
    local targets = {}
    local graphics = make_transition_graphics()

    composer:register('alpha', make_scene_factory('alpha', calls, targets))
    composer:register('beta', make_scene_factory('beta', calls, targets))

    composer:resize(320, 180)
    composer:gotoScene('alpha', { duration = 0 })
    composer:update(0)
    clear_array(calls)
    clear_array(graphics.calls)

    composer:gotoScene('beta', {
        duration = 1,
        transition = {
            compose = function(adapter, progress, outgoing_canvas, incoming_canvas, width, height)
                adapter.calls[#adapter.calls + 1] = string.format(
                    'compose:%.2f:%s:%s:%s:%s',
                    progress,
                    outgoing_canvas.handle.id,
                    incoming_canvas.handle.id,
                    tostring(width),
                    tostring(height)
                )

                adapter.draw(outgoing_canvas.handle, -width * progress, 0)
                adapter.draw(incoming_canvas.handle, width * (1 - progress), 0)
            end,
        },
    })
    composer:update(0)
    composer:update(0.5)

    composer:draw(graphics, function(node)
        if node.tag ~= nil then
            local target = graphics.getCanvas()
            local target_name = 'screen'

            if target ~= nil then
                target_name = target.id
            end

            graphics.calls[#graphics.calls + 1] =
                node.tag .. '@' .. target_name
        end
    end)

    assert_contains(graphics.calls, 'setCanvas:canvas-1',
        'Transition draw should render the outgoing scene into an offscreen canvas')
    assert_contains(graphics.calls, 'clear:canvas-1',
        'Transition draw should clear the outgoing canvas before rendering')
    assert_contains(graphics.calls, 'alpha-target@canvas-1',
        'Transition draw should render the outgoing scene subtree into its canvas')
    assert_contains(graphics.calls, 'beta-target@canvas-2',
        'Transition draw should render the incoming scene subtree into its canvas')
    assert_contains(graphics.calls, 'compose:0.50:canvas-1:canvas-2:320:180',
        'Transition draw should call the transition composition with progress and stage bounds')
    assert_contains(graphics.calls, 'draw:screen:canvas-1:-160.00:0.00',
        'Transition composition should draw the outgoing canvas back to the main target')
    assert_contains(graphics.calls, 'draw:screen:canvas-2:160.00:0.00',
        'Transition composition should draw the incoming canvas back to the main target')

    composer:destroy()
end

local function run_interruption_tests()
    local composer = Composer.new()
    local calls = {}
    local targets = {}

    composer:register('alpha', make_scene_factory('alpha', calls, targets))
    composer:register('beta', make_scene_factory('beta', calls, targets))
    composer:register('gamma', make_scene_factory('gamma', calls, targets))

    composer:gotoScene('alpha', { duration = 0 })
    composer:update(0)
    clear_array(calls)

    composer:gotoScene('beta', {
        transition = 'fade',
        duration = 1,
    })
    composer:update(0)

    clear_array(calls)
    composer:gotoScene('gamma', { duration = 0 })
    composer:update(0)

    assert_equal(calls[1], 'alpha:leave-after',
        'Interrupting a transition should complete the original outgoing leave lifecycle')
    assert_equal(calls[2], 'gamma:create',
        'Interrupting a transition should start the final target navigation immediately')
    assert_equal(calls[3], 'gamma:enter-before',
        'Interrupting a transition should fire enter-before only for the final incoming scene')
    assert_equal(calls[4], 'gamma:enter-after',
        'Interrupting a transition should complete enter-after only for the final incoming scene')
    assert_true(not table.concat(calls, ','):find('beta:enter-after', 1, true),
        'Interrupted intermediate scenes must not receive enter-after')
    assert_true(not table.concat(calls, ','):find('beta:leave-before', 1, true),
        'Interrupted intermediate scenes must not receive leave-before')
    assert_true(not table.concat(calls, ','):find('beta:leave-after', 1, true),
        'Interrupted intermediate scenes must not receive leave-after')
    assert_nil(composer.transitionState,
        'Interrupting into an immediate navigation should clear the transition state')
    assert_equal(#composer.stage.baseSceneLayer:getChildren(), 1,
        'Stable boundaries after interruption should still leave one mounted base scene')

    local delivery = composer:deliverInput({
        kind = 'mousepressed',
        x = 5,
        y = 5,
        button = 1,
    })

    assert_equal(delivery.target, targets.gamma,
        'After interruption input should route only into the final committed scene')

    composer:destroy()
end

local function run_interruption_draw_cleanup_tests()
    local composer = Composer.new()
    local calls = {}
    local targets = {}
    local graphics = make_transition_graphics()

    composer:register('alpha', make_scene_factory('alpha', calls, targets))
    composer:register('beta', make_scene_factory('beta', calls, targets))
    composer:register('gamma', make_scene_factory('gamma', calls, targets))

    composer:resize(320, 180)
    composer:gotoScene('alpha', { duration = 0 })
    composer:update(0)

    composer:gotoScene('beta', {
        duration = 1,
        transition = {
            compose = function(adapter, progress, outgoing_canvas, incoming_canvas)
                adapter.calls[#adapter.calls + 1] = string.format(
                    'compose:%.2f:%s:%s',
                    progress,
                    outgoing_canvas.handle.id,
                    incoming_canvas.handle.id
                )

                adapter.draw(outgoing_canvas.handle, 0, 0)
                adapter.draw(incoming_canvas.handle, 0, 0)
            end,
        },
    })
    composer:update(0)
    composer:update(0.25)
    composer:gotoScene('gamma', { duration = 0 })
    composer:update(0)
    clear_array(graphics.calls)

    composer:draw(graphics, function(node)
        if node.tag ~= nil then
            local target = graphics.getCanvas()
            local target_name = 'screen'

            if target ~= nil then
                target_name = target.id
            end

            graphics.calls[#graphics.calls + 1] =
                node.tag .. '@' .. target_name
        end
    end)

    assert_contains(graphics.calls, 'gamma-target@screen',
        'After interruption the final committed scene should draw directly to the screen')
    assert_true(not table.concat(graphics.calls, ','):find('compose:', 1, true),
        'After interruption the composer should stop using transition composition')
    assert_true(not table.concat(graphics.calls, ','):find('canvas-', 1, true),
        'After interruption there should be no transition canvas residue in the stable draw path')

    composer:destroy()
end

local ComposerRegistryActivationTransitionSpec = {}

function ComposerRegistryActivationTransitionSpec.run()
    run_public_surface_and_registration_tests()
    run_initial_navigation_and_same_scene_tests()
    run_transition_progress_and_completion_tests()
    run_transition_draw_execution_tests()
    run_interruption_tests()
    run_interruption_draw_cleanup_tests()
end

return ComposerRegistryActivationTransitionSpec
