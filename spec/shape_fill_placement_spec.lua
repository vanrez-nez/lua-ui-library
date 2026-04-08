local UI = require('lib.ui')
local ShapeFillPlacement = require('lib.ui.shapes.fill_placement')
local SourcePlacement = require('lib.ui.render.source_placement')

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

local function assert_near(actual, expected, tolerance, message)
    tolerance = tolerance or 0.01

    if math.abs(actual - expected) > tolerance then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
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

local function run_shared_tiling_helper_tests()
    local tiled = SourcePlacement.resolve_tiled_placements({
        x = 4,
        y = 6,
        width = 100,
        height = 50,
    }, 16, 12, {
        alignX = 'center',
        alignY = 'end',
        offsetX = 5,
        offsetY = -2,
        repeatX = true,
        repeatY = false,
    })

    assert_equal(SourcePlacement.resolve_aligned_origin(4, 100, 16, 'center', 5), 51,
        'Shared aligned-origin resolution should honor center alignment and offsets')
    assert_equal(SourcePlacement.resolve_aligned_origin(6, 50, 12, 'end', -2), 42,
        'Shared aligned-origin resolution should honor end alignment and offsets')
    assert_equal(tiled.originX, 51,
        'Shared tiled placement should preserve the alignment-derived tiling origin on x')
    assert_equal(tiled.originY, 42,
        'Shared tiled placement should preserve the alignment-derived tiling origin on y')
    assert_equal(tiled.startX, 3,
        'Shared tiled placement should backfill repeated tiles to cover the local bounds start edge')
    assert_equal(tiled.startY, 42,
        'Shared tiled placement should keep the aligned origin on a non-repeating axis')
    assert_equal(#tiled.placements, 7,
        'Shared tiled placement should cover the repeated axis across the local bounds')
    assert_equal(tiled.placements[1].x, 3,
        'Shared tiled placement should begin at the first tile intersecting local bounds')
    assert_equal(tiled.placements[1].y, 42,
        'Shared tiled placement should preserve non-repeating axis placement')
    assert_equal(tiled.placements[4].x, 51,
        'Shared tiled placement should preserve the aligned origin as one of the emitted tiles')
    assert_equal(tiled.placements[7].x, 99,
        'Shared tiled placement should continue until the repeated tiles cover the far edge')
end

local function run_shape_texture_stretch_tests()
    local previous_love = rawget(_G, 'love')

    rawset(_G, 'love', {
        graphics = {
            newQuad = function(x, y, width, height, texture_width, texture_height)
                return {
                    x = x,
                    y = y,
                    width = width,
                    height = height,
                    texture_width = texture_width,
                    texture_height = texture_height,
                }
            end,
        },
    })

    local texture = make_texture(64, 32)
    local sprite = UI.Sprite.new({
        texture = texture,
        region = {
            x = 8,
            y = 4,
            width = 16,
            height = 12,
        },
    })
    local shape = UI.RectShape.new({
        width = 80,
        height = 40,
        fillTexture = sprite,
        fillAlignX = 'end',
        fillAlignY = 'end',
        fillOffsetX = 11,
        fillOffsetY = -7,
    })

    local placement = shape:_resolve_active_fill_placement()

    assert_equal(placement.kind, 'texture',
        'Shape fill placement should preserve the active texture kind')
    assert_equal(placement.placementMode, 'stretch',
        'Shape fill placement should default texture-backed fill to stretch mode')
    assert_same(placement.source, sprite,
        'Shape fill placement should preserve the active texture source by reference')
    assert_same(placement.texture, sprite,
        'Shape fill placement should preserve the active texture wrapper by reference')
    assert_same(placement.drawable, texture:getDrawable(),
        'Shape fill placement should resolve the underlying drawable source')
    assert_true(placement.quad ~= nil,
        'Shape fill placement should resolve a sprite quad when the graphics backend supports it')
    assert_equal(placement.sourceWidth, 16,
        'Shape fill placement should use sprite region width for placement math')
    assert_equal(placement.sourceHeight, 12,
        'Shape fill placement should use sprite region height for placement math')
    assert_equal(placement.originX, 0,
        'Shape stretch placement should ignore fillAlignX and fillOffsetX')
    assert_equal(placement.originY, 0,
        'Shape stretch placement should ignore fillAlignY and fillOffsetY')
    assert_equal(#placement.placements, 1,
        'Shape stretch placement should emit a single placement covering local bounds')
    assert_equal(placement.placements[1].x, 0,
        'Shape stretch placement should start at the local bounds x')
    assert_equal(placement.placements[1].y, 0,
        'Shape stretch placement should start at the local bounds y')
    assert_equal(placement.placements[1].width, 80,
        'Shape stretch placement should use the full local bounds width')
    assert_equal(placement.placements[1].height, 40,
        'Shape stretch placement should use the full local bounds height')
    assert_near(placement.placements[1].scaleX, 5,
        0.0001,
        'Shape stretch placement should scale by local bounds width over sprite width')
    assert_near(placement.placements[1].scaleY, 40 / 12,
        0.0001,
        'Shape stretch placement should scale by local bounds height over sprite height')

    rawset(_G, 'love', previous_love)
end

local function run_shape_texture_tiling_tests()
    local previous_love = rawget(_G, 'love')

    rawset(_G, 'love', {
        graphics = {
            newQuad = function(x, y, width, height, texture_width, texture_height)
                return {
                    x = x,
                    y = y,
                    width = width,
                    height = height,
                    texture_width = texture_width,
                    texture_height = texture_height,
                }
            end,
        },
    })

    local texture = make_texture(64, 32)
    local sprite = UI.Sprite.new({
        texture = texture,
        region = {
            x = 8,
            y = 4,
            width = 16,
            height = 12,
        },
    })
    local shape = UI.RectShape.new({
        width = 100,
        height = 50,
        fillTexture = sprite,
        fillRepeatX = true,
        fillRepeatY = false,
        fillAlignX = 'center',
        fillAlignY = 'end',
        fillOffsetX = 5,
        fillOffsetY = -2,
    })

    local placement = shape:_resolve_active_fill_placement()

    assert_equal(placement.placementMode, 'tile',
        'Shape fill placement should switch to intrinsic-size tiling mode when either repeat flag is enabled')
    assert_equal(placement.originX, 47,
        'Shape tiled placement should derive the initial tile origin from local bounds alignment on x')
    assert_equal(placement.originY, 36,
        'Shape tiled placement should derive the initial tile origin from local bounds alignment on y')
    assert_equal(placement.startX, -1,
        'Shape tiled placement should backfill repeated tiles so coverage reaches the left local edge')
    assert_equal(placement.startY, 36,
        'Shape tiled placement should keep the aligned origin on a non-repeating axis')
    assert_equal(#placement.placements, 7,
        'Shape tiled placement should emit enough intrinsic-size tiles to cover the repeated axis')
    assert_equal(placement.placements[1].x, -1,
        'Shape tiled placement should start from the first repeated tile intersecting local bounds')
    assert_equal(placement.placements[1].y, 36,
        'Shape tiled placement should preserve non-repeating axis alignment and offset')
    assert_equal(placement.placements[4].x, 47,
        'Shape tiled placement should include the alignment-derived initial tile position')
    assert_equal(placement.placements[7].x, 95,
        'Shape tiled placement should continue until the repeated tiles cover the far edge')
    assert_equal(placement.placements[1].width, 16,
        'Shape tiled placement should keep intrinsic sprite width')
    assert_equal(placement.placements[1].height, 12,
        'Shape tiled placement should keep intrinsic sprite height')
    assert_equal(placement.placements[1].scaleX, 1,
        'Shape tiled placement should not stretch intrinsic sprite width')
    assert_equal(placement.placements[1].scaleY, 1,
        'Shape tiled placement should not stretch intrinsic sprite height')

    rawset(_G, 'love', previous_love)
end

local function run_gradient_placement_tests()
    local placement = ShapeFillPlacement.resolve({
        x = 4,
        y = 6,
        width = 30,
        height = 18,
    }, {
        kind = 'gradient',
        source_prop = 'fillGradient',
        gradient = {
            kind = 'linear',
            direction = 'vertical',
            colors = {
                '#ff0000',
                '#00ff00',
            },
        },
        opacity = 0.4,
        repeatX = true,
        repeatY = true,
        alignX = 'end',
        alignY = 'start',
        offsetX = 20,
        offsetY = -9,
    })

    assert_equal(placement.kind, 'gradient',
        'Shape fill placement should preserve the active gradient kind')
    assert_equal(placement.placementMode, 'gradient',
        'Shape fill placement should resolve gradients through the full-bounds gradient path')
    assert_equal(placement.direction, 'vertical',
        'Shape fill placement should preserve the resolved gradient direction')
    assert_equal(placement.span.x, 4,
        'Shape gradient placement should use the local bounds x')
    assert_equal(placement.span.y, 6,
        'Shape gradient placement should use the local bounds y')
    assert_equal(placement.span.width, 30,
        'Shape gradient placement should span the local bounds width')
    assert_equal(placement.span.height, 18,
        'Shape gradient placement should span the local bounds height')
    assert_equal(placement.startX, 4,
        'Shape gradient placement should start at the local bounds left edge')
    assert_equal(placement.startY, 6,
        'Shape gradient placement should start at the local bounds top edge')
    assert_equal(placement.endX, 4,
        'Shape vertical gradient placement should keep x fixed across the span')
    assert_equal(placement.endY, 24,
        'Shape vertical gradient placement should end at the local bounds bottom edge')
    assert_equal(placement.opacity, 0.4,
        'Shape gradient placement should preserve fillOpacity')
end

local function run_horizontal_gradient_placement_tests()
    local placement = ShapeFillPlacement.resolve({
        x = 3,
        y = 5,
        width = 28,
        height = 16,
    }, {
        kind = 'gradient',
        source_prop = 'fillGradient',
        gradient = {
            kind = 'linear',
            direction = 'horizontal',
            colors = {
                '#ff0000',
                '#0000ff',
            },
        },
        opacity = 0.6,
        repeatX = true,
        repeatY = true,
        alignX = 'end',
        alignY = 'start',
        offsetX = 14,
        offsetY = -8,
    })

    assert_equal(placement.kind, 'gradient',
        'Horizontal gradient placement should preserve the active gradient kind')
    assert_equal(placement.placementMode, 'gradient',
        'Horizontal gradient placement should stay on the full-bounds gradient path')
    assert_equal(placement.direction, 'horizontal',
        'Horizontal gradient placement should preserve the resolved direction')
    assert_equal(placement.startX, 3,
        'Horizontal gradient placement should start at the local bounds left edge')
    assert_equal(placement.startY, 5,
        'Horizontal gradient placement should start at the local bounds top edge')
    assert_equal(placement.endX, 31,
        'Horizontal gradient placement should end at the local bounds right edge')
    assert_equal(placement.endY, 5,
        'Horizontal gradient placement should keep y fixed across the span')
    assert_equal(placement.span.width, 28,
        'Horizontal gradient placement should span the full local bounds width')
    assert_equal(placement.span.height, 16,
        'Horizontal gradient placement should span the full local bounds height')
    assert_equal(placement.opacity, 0.6,
        'Horizontal gradient placement should preserve fillOpacity')
end

local function run_shape_texture_biaxial_tiling_tests()
    local previous_love = rawget(_G, 'love')

    rawset(_G, 'love', {
        graphics = {
            newQuad = function(x, y, width, height, texture_width, texture_height)
                return {
                    x = x,
                    y = y,
                    width = width,
                    height = height,
                    texture_width = texture_width,
                    texture_height = texture_height,
                }
            end,
        },
    })

    local texture = make_texture(64, 32)
    local sprite = UI.Sprite.new({
        texture = texture,
        region = {
            x = 8,
            y = 4,
            width = 16,
            height = 12,
        },
    })
    local shape = UI.RectShape.new({
        width = 40,
        height = 30,
        fillTexture = sprite,
        fillRepeatX = true,
        fillRepeatY = true,
        fillAlignX = 'center',
        fillAlignY = 'end',
        fillOffsetX = 2,
        fillOffsetY = -1,
    })

    local placement = shape:_resolve_active_fill_placement()

    assert_equal(placement.placementMode, 'tile',
        'Shape fill placement should keep intrinsic-size tiling when both repeat flags are enabled')
    assert_equal(placement.originX, 14,
        'Shape biaxial tiling should derive the initial tile origin from aligned local bounds on x')
    assert_equal(placement.originY, 17,
        'Shape biaxial tiling should derive the initial tile origin from aligned local bounds on y')
    assert_equal(placement.startX, -2,
        'Shape biaxial tiling should backfill tiles on x to cover the left edge')
    assert_equal(placement.startY, -7,
        'Shape biaxial tiling should backfill tiles on y to cover the top edge')
    assert_equal(#placement.placements, 12,
        'Shape biaxial tiling should emit a full covering grid across both axes')
    assert_equal(placement.placements[1].x, -2,
        'Shape biaxial tiling should start with the first intersecting tile on x')
    assert_equal(placement.placements[1].y, -7,
        'Shape biaxial tiling should start with the first intersecting tile on y')
    assert_equal(placement.placements[5].x, 14,
        'Shape biaxial tiling should preserve the alignment-derived origin as one emitted column')
    assert_equal(placement.placements[7].y, 17,
        'Shape biaxial tiling should preserve the alignment-derived origin as one emitted row')
    assert_equal(placement.placements[12].x, 30,
        'Shape biaxial tiling should cover the far-right edge')
    assert_equal(placement.placements[12].y, 29,
        'Shape biaxial tiling should cover the far-bottom edge')

    rawset(_G, 'love', previous_love)
end

local M = {}

function M.run()
    run_shared_tiling_helper_tests()
    run_shape_texture_stretch_tests()
    run_shape_texture_tiling_tests()
    run_gradient_placement_tests()
    run_horizontal_gradient_placement_tests()
    run_shape_texture_biaxial_tiling_tests()
end

return M
