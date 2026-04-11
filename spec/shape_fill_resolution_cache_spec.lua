local UI = require('lib.ui')
local ShapeFillSource = require('lib.ui.shapes.fill_source')
local ShapeFillPlacement = require('lib.ui.shapes.fill_placement')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_same(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected same reference', 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function make_texture(width, height)
    return UI.Texture.new({
        source = {
            width = width,
            height = height,
        },
        width = width,
        height = height,
    })
end

local function make_sprite(texture, x, y, width, height)
    return UI.Sprite.new({
        texture = texture,
        region = {
            x = x,
            y = y,
            width = width,
            height = height,
        },
    })
end

local function with_resolution_counters(run_fn)
    local counts = {
        surface = 0,
        descriptor = 0,
        placement = 0,
    }
    local original_resolve_surface = ShapeFillSource.resolve_surface
    local original_resolve_descriptor = ShapeFillSource.resolve_active_descriptor
    local original_resolve_placement = ShapeFillPlacement.resolve

    ShapeFillSource.resolve_surface = function(shape)
        counts.surface = counts.surface + 1
        return original_resolve_surface(shape)
    end

    ShapeFillSource.resolve_active_descriptor = function(fill_surface)
        counts.descriptor = counts.descriptor + 1
        return original_resolve_descriptor(fill_surface)
    end

    ShapeFillPlacement.resolve = function(bounds, descriptor)
        counts.placement = counts.placement + 1
        return original_resolve_placement(bounds, descriptor)
    end

    local ok, err = xpcall(function()
        run_fn(counts)
    end, debug.traceback)

    ShapeFillSource.resolve_surface = original_resolve_surface
    ShapeFillSource.resolve_active_descriptor = original_resolve_descriptor
    ShapeFillPlacement.resolve = original_resolve_placement

    if not ok then
        error(err, 0)
    end
end

local function resolve_all(shape)
    return
        shape:_resolve_fill_surface(),
        shape:_resolve_active_fill_source(),
        shape:_resolve_active_fill_placement()
end

local function assert_cached_resolution(shape, counts, message)
    local surface = nil
    local descriptor = nil
    local placement = nil

    surface, descriptor, placement = resolve_all(shape)

    local after_first_surface = counts.surface
    local after_first_descriptor = counts.descriptor
    local after_first_placement = counts.placement

    local next_surface, next_descriptor, next_placement = resolve_all(shape)

    assert_same(next_surface, surface,
        message .. ' should reuse the cached fill surface')
    assert_same(next_descriptor, descriptor,
        message .. ' should reuse the cached active descriptor')
    assert_same(next_placement, placement,
        message .. ' should reuse the cached placement')
    assert_equal(counts.surface, after_first_surface,
        message .. ' should not rebuild the fill surface on cache hit')
    assert_equal(counts.descriptor, after_first_descriptor,
        message .. ' should not rebuild the active descriptor on cache hit')
    assert_equal(counts.placement, after_first_placement,
        message .. ' should not rebuild the placement on cache hit')

    return surface, descriptor, placement
end

local function assert_full_invalidation(shape, counts, mutate, message)
    local surface, descriptor, placement = assert_cached_resolution(shape, counts, message .. ' baseline')
    local before_surface = counts.surface
    local before_descriptor = counts.descriptor
    local before_placement = counts.placement

    mutate()

    local next_surface, next_descriptor, next_placement = resolve_all(shape)

    assert_true(next_surface ~= surface,
        message .. ' should invalidate the cached fill surface')
    assert_true(next_descriptor ~= descriptor,
        message .. ' should invalidate the cached active descriptor')
    assert_true(next_placement ~= placement,
        message .. ' should invalidate the cached placement')
    assert_equal(counts.surface, before_surface + 1,
        message .. ' should rebuild the fill surface exactly once after invalidation')
    assert_equal(counts.descriptor, before_descriptor + 1,
        message .. ' should rebuild the active descriptor exactly once after invalidation')
    assert_equal(counts.placement, before_placement + 1,
        message .. ' should rebuild the placement exactly once after invalidation')

    assert_cached_resolution(shape, counts, message .. ' updated')
end

local function apply_motion(shape, properties)
    shape.motion = {
        enter = {
            properties = properties,
        },
    }

    shape:_raise_motion('enter')
end

local function run_static_cache_reuse_tests()
    with_resolution_counters(function(counts)
        local texture = make_texture(64, 32)
        local sprite = make_sprite(texture, 8, 4, 16, 12)
        local shape = UI.RectShape.new({
            width = 80,
            height = 40,
            fillTexture = sprite,
            fillRepeatX = true,
            fillRepeatY = false,
            fillAlignX = 'start',
            fillAlignY = 'end',
            fillOffsetX = 3,
            fillOffsetY = -2,
        })

        assert_cached_resolution(shape, counts,
            'static textured shape fill resolution')
    end)
end

local function run_public_fill_invalidation_tests()
    with_resolution_counters(function(counts)
        local color_shape = UI.RectShape.new({
            width = 40,
            height = 20,
            fillColor = '#112233',
            fillOpacity = 0.5,
        })

        assert_full_invalidation(color_shape, counts, function()
            color_shape.fillColor = '#334455'
        end, 'fillColor write')

        assert_full_invalidation(color_shape, counts, function()
            color_shape.fillOpacity = 0.75
        end, 'fillOpacity write')

        local gradient_shape = UI.RectShape.new({
            width = 50,
            height = 25,
            fillGradient = {
                kind = 'linear',
                direction = 'horizontal',
                colors = {
                    '#111111',
                    '#eeeeee',
                },
            },
        })

        assert_full_invalidation(gradient_shape, counts, function()
            gradient_shape.fillGradient = {
                kind = 'linear',
                direction = 'vertical',
                colors = {
                    '#ff0000',
                    '#00ff00',
                    '#0000ff',
                },
            }
        end, 'fillGradient write')

        local texture_a = make_texture(64, 32)
        local texture_b = make_texture(96, 48)
        local sprite_a = make_sprite(texture_a, 8, 4, 16, 12)
        local sprite_b = make_sprite(texture_b, 4, 2, 24, 18)
        local texture_shape = UI.RectShape.new({
            width = 100,
            height = 50,
            fillTexture = sprite_a,
            fillRepeatX = true,
            fillRepeatY = false,
            fillAlignX = 'start',
            fillAlignY = 'end',
            fillOffsetX = 2,
            fillOffsetY = -1,
        })

        assert_full_invalidation(texture_shape, counts, function()
            texture_shape.fillTexture = sprite_b
        end, 'fillTexture write')

        assert_full_invalidation(texture_shape, counts, function()
            texture_shape.fillRepeatX = false
        end, 'fillRepeatX write')

        assert_full_invalidation(texture_shape, counts, function()
            texture_shape.fillRepeatY = true
        end, 'fillRepeatY write')

        assert_full_invalidation(texture_shape, counts, function()
            texture_shape.fillAlignX = 'center'
        end, 'fillAlignX write')

        assert_full_invalidation(texture_shape, counts, function()
            texture_shape.fillAlignY = 'start'
        end, 'fillAlignY write')

        assert_full_invalidation(texture_shape, counts, function()
            texture_shape.fillOffsetX = 9
        end, 'fillOffsetX write')

        assert_full_invalidation(texture_shape, counts, function()
            texture_shape.fillOffsetY = 4
        end, 'fillOffsetY write')
    end)
end

local function run_motion_fill_invalidation_tests()
    with_resolution_counters(function(counts)
        local texture_a = make_texture(64, 32)
        local texture_b = make_texture(96, 48)
        local sprite_a = make_sprite(texture_a, 8, 4, 16, 12)
        local sprite_b = make_sprite(texture_b, 4, 2, 24, 18)
        local shape = UI.RectShape.new({
            width = 120,
            height = 60,
            fillColor = '#112233',
            fillOpacity = 0.6,
            fillGradient = {
                kind = 'linear',
                direction = 'horizontal',
                colors = {
                    '#ff0000',
                    '#00ff00',
                },
            },
            fillTexture = sprite_a,
            fillAlignX = 'start',
            fillAlignY = 'end',
            fillOffsetX = 3,
            fillOffsetY = -2,
        })

        assert_full_invalidation(shape, counts, function()
            apply_motion(shape, {
                fillColor = {
                    to = '#445566',
                },
            })
        end, 'fillColor motion')

        assert_full_invalidation(shape, counts, function()
            apply_motion(shape, {
                fillOpacity = {
                    to = 0.25,
                },
            })
        end, 'fillOpacity motion')

        assert_full_invalidation(shape, counts, function()
            apply_motion(shape, {
                fillGradient = {
                    to = {
                        kind = 'linear',
                        direction = 'vertical',
                        colors = {
                            '#111111',
                            '#999999',
                        },
                    },
                },
            })
        end, 'fillGradient motion')

        assert_full_invalidation(shape, counts, function()
            apply_motion(shape, {
                fillTexture = {
                    to = sprite_b,
                },
            })
        end, 'fillTexture motion')

        assert_full_invalidation(shape, counts, function()
            apply_motion(shape, {
                fillOffsetX = {
                    to = 11,
                },
            })
        end, 'fillOffsetX motion')

        assert_full_invalidation(shape, counts, function()
            apply_motion(shape, {
                fillOffsetY = {
                    to = 5,
                },
            })
        end, 'fillOffsetY motion')

        assert_full_invalidation(shape, counts, function()
            apply_motion(shape, {
                fillAlignX = {
                    to = 'center',
                },
            })
        end, 'fillAlignX motion')

        assert_full_invalidation(shape, counts, function()
            apply_motion(shape, {
                fillAlignY = {
                    to = 'start',
                },
            })
        end, 'fillAlignY motion')
    end)
end

local function run_local_bounds_invalidation_tests()
    with_resolution_counters(function(counts)
        local texture = make_texture(64, 32)
        local sprite = make_sprite(texture, 8, 4, 16, 12)
        local shape = UI.RectShape.new({
            width = 80,
            height = 40,
            fillTexture = sprite,
            fillRepeatX = true,
            fillOffsetX = 2,
        })

        local surface, descriptor, placement = assert_cached_resolution(shape, counts,
            'local-bounds baseline')
        local before_surface = counts.surface
        local before_descriptor = counts.descriptor
        local before_placement = counts.placement

        shape.width = 120

        local next_surface, next_descriptor, next_placement = resolve_all(shape)

        assert_same(next_surface, surface,
            'local-bounds changes should preserve the cached fill surface')
        assert_same(next_descriptor, descriptor,
            'local-bounds changes should preserve the cached active descriptor')
        assert_true(next_placement ~= placement,
            'local-bounds changes should invalidate the cached placement')
        assert_equal(counts.surface, before_surface,
            'local-bounds changes should not rebuild the fill surface')
        assert_equal(counts.descriptor, before_descriptor,
            'local-bounds changes should not rebuild the active descriptor')
        assert_equal(counts.placement, before_placement + 1,
            'local-bounds changes should rebuild the placement exactly once')

        assert_cached_resolution(shape, counts,
            'local-bounds updated')
    end)
end

local function run()
    run_static_cache_reuse_tests()
    run_public_fill_invalidation_tests()
    run_motion_fill_invalidation_tests()
    run_local_bounds_invalidation_tests()
end

return {
    run = run,
}
