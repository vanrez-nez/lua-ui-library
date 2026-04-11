local UI = require('lib.ui')
local RootCompositor = require('lib.ui.render.root_compositor')

local Drawable = UI.Drawable
local RectShape = UI.RectShape

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_same(actual, expected, message)
    if actual ~= expected then
        error(message, 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function make_runtime(counter)
    return {
        get_effective_value = function(node, key)
            counter.get_effective_value = counter.get_effective_value + 1
            local effective_values = rawget(node, '_effective_values') or {}
            return effective_values[key]
        end,
    }
end

local function attach_plan_trackers(node)
    local counters = {
        extras = 0,
        result_clip = 0,
    }

    local resolve_extras = node._resolve_root_compositing_extras
    local resolve_result_clip = node._resolve_root_compositing_result_clip

    rawset(node, '_resolve_root_compositing_extras', function(self)
        counters.extras = counters.extras + 1

        if resolve_extras == nil then
            return nil
        end

        return resolve_extras(self)
    end)

    rawset(node, '_resolve_root_compositing_result_clip', function(self)
        counters.result_clip = counters.result_clip + 1

        if resolve_result_clip == nil then
            return nil
        end

        return resolve_result_clip(self)
    end)

    return counters
end

local function assert_cached_repeat(node, runtime, counters, message)
    local first_plan = RootCompositor.resolve_node_plan(node, runtime)
    local after_first_get_effective = counters.get_effective_value
    local after_first_extras = counters.extras
    local after_first_result_clip = counters.result_clip
    local second_plan = RootCompositor.resolve_node_plan(node, runtime)

    assert_same(second_plan, first_plan, message .. ' should reuse the cached plan object')
    assert_equal(counters.get_effective_value, after_first_get_effective,
        message .. ' should not recompute effective root state on cache hit')
    assert_equal(counters.extras, after_first_extras,
        message .. ' should not recompute compositing extras on cache hit')
    assert_equal(counters.result_clip, after_first_result_clip,
        message .. ' should not recompute result clip on cache hit')

    return first_plan
end

local function run_default_fast_path_tests()
    local drawable = Drawable.new({
        width = 32,
        height = 18,
    })
    local counters = attach_plan_trackers(drawable)
    counters.get_effective_value = 0
    local runtime = make_runtime(counters)

    local plan = assert_cached_repeat(drawable, runtime, counters,
        'default-state Drawable plan')

    assert_true(plan ~= nil,
        'default-state Drawable should still resolve a normalized root compositing plan')
    assert_true(plan.compositing_extras == nil,
        'default-state Drawable should normalize empty compositing extras to nil')
    assert_true(not RootCompositor.plan_requires_isolation(plan),
        'default-state Drawable should remain on the non-isolated fast path')
end

local function run_public_invalidation_tests()
    local drawable = Drawable.new({
        width = 24,
        height = 24,
    })
    local counters = attach_plan_trackers(drawable)
    counters.get_effective_value = 0
    local runtime = make_runtime(counters)

    local baseline_plan = assert_cached_repeat(drawable, runtime, counters,
        'baseline Drawable plan')

    drawable.opacity = 0.5
    drawable:_refresh_if_dirty()

    local opacity_plan = RootCompositor.resolve_node_plan(drawable, runtime)
    assert_true(opacity_plan ~= baseline_plan,
        'changing opacity should invalidate the cached plan')
    assert_equal(opacity_plan.root_compositing_state.opacity, 0.5,
        'opacity changes should be reflected after recomputing the plan')
    assert_cached_repeat(drawable, runtime, counters,
        'opacity-updated Drawable plan')

    drawable.blendMode = 'screen'
    drawable:_refresh_if_dirty()

    local blend_plan = RootCompositor.resolve_node_plan(drawable, runtime)
    assert_equal(blend_plan.root_compositing_state.blendMode, 'screen',
        'changing blendMode should invalidate and refresh the cached plan')
    assert_cached_repeat(drawable, runtime, counters,
        'blend-updated Drawable plan')

    local shader = { id = 'fast-path-shader' }
    drawable.shader = shader
    drawable:_refresh_if_dirty()

    local shader_plan = RootCompositor.resolve_node_plan(drawable, runtime)
    assert_same(shader_plan.root_compositing_state.shader, shader,
        'changing shader should invalidate and refresh the cached plan')
    assert_cached_repeat(drawable, runtime, counters,
        'shader-updated Drawable plan')
end

local function run_motion_invalidation_tests()
    local drawable = Drawable.new({
        width = 20,
        height = 20,
    })
    local counters = attach_plan_trackers(drawable)
    counters.get_effective_value = 0
    local runtime = make_runtime(counters)

    assert_cached_repeat(drawable, runtime, counters,
        'motion baseline Drawable plan')

    drawable:_apply_motion_value('root', 'opacity', 0.25)

    local opacity_plan = RootCompositor.resolve_node_plan(drawable, runtime)
    assert_equal(opacity_plan.root_compositing_state.opacity, 0.25,
        'root-surface opacity motion should invalidate and refresh the cached plan')
    assert_cached_repeat(drawable, runtime, counters,
        'opacity-motion Drawable plan')

    drawable:_apply_motion_value('root', 'translationX', 12)

    local translation_plan = RootCompositor.resolve_node_plan(drawable, runtime)
    assert_true(translation_plan.compositing_extras ~= nil,
        'compositing motion should materialize normalized compositing extras')
    assert_equal(translation_plan.compositing_extras.translationX, 12,
        'translation motion should invalidate and refresh the cached plan')
    assert_cached_repeat(drawable, runtime, counters,
        'translation-motion Drawable plan')
end

local function run_result_clip_invalidation_tests()
    local rect = RectShape.new({
        width = 36,
        height = 36,
    })
    rect:_refresh_if_dirty()

    local counters = attach_plan_trackers(rect)
    counters.get_effective_value = 0
    local runtime = make_runtime(counters)

    local initial_plan = assert_cached_repeat(rect, runtime, counters,
        'initial RectShape plan')
    assert_true(initial_plan.result_clip == nil,
        'stroke-free RectShape nodes should not require a result clip')

    rect.strokeWidth = 4
    rect.strokeColor = '#ffffffff'
    rect:_refresh_if_dirty()

    local stroked_plan = RootCompositor.resolve_node_plan(rect, runtime)
    assert_equal(stroked_plan.result_clip.kind, 'stencil_mask',
        'result-clip-relevant visual changes should invalidate and refresh the cached plan')
    assert_cached_repeat(rect, runtime, counters,
        'stroked RectShape plan')

    rect.width = 48
    rect:_refresh_if_dirty()

    local before_resize_get_effective = counters.get_effective_value
    local before_resize_extras = counters.extras
    local before_resize_result_clip = counters.result_clip
    local resized_plan = RootCompositor.resolve_node_plan(rect, runtime)
    assert_true(resized_plan ~= stroked_plan,
        'bounds changes should invalidate the cached compositing plan even when the clip contract is unchanged')
    assert_equal(resized_plan.result_clip.kind, 'stencil_mask',
        'bounds changes should preserve the resolved result-clip kind after recomputation')
    assert_true(counters.get_effective_value > before_resize_get_effective or
        counters.extras > before_resize_extras or
        counters.result_clip > before_resize_result_clip,
        'bounds changes should force a fresh plan resolution before the next draw')
    assert_cached_repeat(rect, runtime, counters,
        'resized RectShape plan')
end

local function run()
    run_default_fast_path_tests()
    run_public_invalidation_tests()
    run_motion_invalidation_tests()
    run_result_clip_invalidation_tests()
end

return {
    run = run,
}
