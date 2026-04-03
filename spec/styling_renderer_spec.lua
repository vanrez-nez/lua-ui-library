local UI = require('lib.ui')

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

local function run_background_image_tests()
    local Styling = require('lib.ui.render.styling')
    local Texture = UI.Texture
    local Sprite = UI.Sprite

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

    local texture_source = {
        width = 64,
        height = 32,
    }
    local texture = Texture.new({
        source = texture_source,
        width = 64,
        height = 32,
    })

    local sprite = Sprite.new({
        texture = texture,
        region = {
            x = 8,
            y = 4,
            width = 16,
            height = 12,
        },
    })

    local draw_calls = {}
    local graphics = {
        getColor = function() return 1, 1, 1, 1 end,
        setColor = function() end,
        getStencilTest = function() return nil end,
        setStencilTest = function() end,
        stencil = function(fn) fn() end,
        polygon = function() end,
        draw = function(...)
            draw_calls[#draw_calls + 1] = { ... }
        end,
    }

    Styling.draw({
        backgroundImage = texture,
        backgroundOpacity = 1,
    }, {
        x = 0,
        y = 0,
        width = 64,
        height = 32,
    }, graphics)

    assert_same(draw_calls[1][1], texture_source,
        'Texture-backed backgrounds should draw the underlying drawable source')
    assert_equal(draw_calls[1][2], 0,
        'Texture-backed backgrounds should draw at the resolved x position')
    assert_equal(draw_calls[1][3], 0,
        'Texture-backed backgrounds should draw at the resolved y position')

    draw_calls = {}

    Styling.draw({
        backgroundImage = sprite,
        backgroundOpacity = 1,
        backgroundRepeatX = true,
    }, {
        x = 0,
        y = 0,
        width = 32,
        height = 12,
    }, graphics)

    assert_equal(#draw_calls, 2,
        'Repeated sprite-backed backgrounds should tile using the sprite dimensions')
    assert_same(draw_calls[1][1], texture_source,
        'Sprite-backed backgrounds should draw the texture drawable, not the Sprite wrapper')
    assert_equal(draw_calls[1][2].x, 8,
        'Sprite-backed backgrounds should use a quad matching the sprite region x')
    assert_equal(draw_calls[1][2].y, 4,
        'Sprite-backed backgrounds should use a quad matching the sprite region y')
    assert_equal(draw_calls[1][2].width, 16,
        'Sprite-backed backgrounds should use a quad matching the sprite region width')
    assert_equal(draw_calls[1][2].height, 12,
        'Sprite-backed backgrounds should use a quad matching the sprite region height')
    assert_equal(draw_calls[1][3], 0,
        'Sprite-backed backgrounds should tile from the resolved base x position')
    assert_equal(draw_calls[2][3], 16,
        'Sprite-backed backgrounds should advance by sprite width when repeating')

    rawset(_G, 'love', previous_love)
end

local function run_inset_shadow_geometry_tests()
    local Styling = require('lib.ui.render.styling')

    local polygons = {}
    local graphics = {
        getColor = function() return 1, 1, 1, 1 end,
        setColor = function() end,
        getStencilTest = function() return nil end,
        setStencilTest = function() end,
        stencil = function(fn) fn() end,
        polygon = function(mode, pts)
            polygons[#polygons + 1] = { mode = mode, pts = pts }
        end,
    }

    Styling.draw({
        shadowColor = { 0, 0, 0, 1 },
        shadowOpacity = 1,
        shadowInset = true,
        shadowBlur = 0,
        borderWidthTop = 4,
        borderWidthRight = 2,
        borderWidthBottom = 6,
        borderWidthLeft = 8,
        cornerRadiusTopLeft = 20,
        cornerRadiusTopRight = 18,
        cornerRadiusBottomRight = 16,
        cornerRadiusBottomLeft = 14,
    }, {
        x = 10,
        y = 20,
        width = 100,
        height = 60,
    }, graphics)

    local inner_stencil = polygons[1]
    local inner_fill = polygons[2]

    assert_equal(inner_stencil.mode, 'fill',
        'Inset shadow should first stencil the inner rounded silhouette')
    assert_equal(inner_fill.mode, 'fill',
        'Inset shadow hard-fill path should use the inner rounded silhouette')

    local expected_inner_x = 10 + 8
    local expected_inner_w = 100 - 8 - 2
    local expected_inner_tr = 18 - ((4 + 2) * 0.5)

    assert_equal(inner_stencil.pts[1], expected_inner_x + expected_inner_w - expected_inner_tr,
        'Inset shadow stencil should contract the top-right radius by half adjacent border widths')
    assert_equal(inner_stencil.pts[2], 20 + 4,
        'Inset shadow stencil should be inset from the top border edge')
    assert_equal(inner_fill.pts[1], inner_stencil.pts[1],
        'Inset shadow fill should use the same contracted inner silhouette as the stencil')
    assert_equal(inner_fill.pts[2], inner_stencil.pts[2],
        'Inset shadow fill should align with the inner stencil geometry')
end

local M = {}

function M.run()
    run_background_image_tests()
    run_inset_shadow_geometry_tests()
end

return M
