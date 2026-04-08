local UI = require('lib.ui')
local GraphicsSource = require('lib.ui.render.graphics_source')
local GraphicsValidation = require('lib.ui.render.graphics_validation')

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

local function assert_error(fn, needle, message)
    local ok, err = pcall(fn)
    if ok then
        error(message .. ': expected an error', 2)
    end

    local text = tostring(err)
    if needle ~= nil and not text:find(needle, 1, true) then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
    end
end

local function make_texture(width, height)
    local source = {
        width = width,
        height = height,
    }

    return UI.Texture.new({
        source = source,
        width = width,
        height = height,
    }), source
end

local function run_validation_helper_tests()
    local opacity = GraphicsValidation.validate_root_opacity('opacity', 0.4, nil, 2)
    local blend_mode = GraphicsValidation.validate_root_blend_mode('blendMode', 'normal', nil, 2)
    local shader = GraphicsValidation.validate_root_shader('shader', { id = 'fx' }, nil, 2)
    local gradient = GraphicsValidation.validate_gradient('fillGradient', {
        kind = 'linear',
        direction = 'horizontal',
        colors = {
            '#ff0000',
            '#00ff00',
        },
    }, nil, 2)

    assert_equal(opacity, 0.4,
        'Shared root opacity validation should preserve valid values')
    assert_equal(blend_mode, 'normal',
        'Shared root blendMode validation should preserve valid values')
    assert_equal(shader.id, 'fx',
        'Shared root shader validation should preserve valid shader references')
    assert_equal(gradient.kind, 'linear',
        'Shared gradient validation should preserve the gradient kind')
    assert_equal(gradient.direction, 'horizontal',
        'Shared gradient validation should preserve the gradient direction')
    assert_equal(#gradient.colors, 2,
        'Shared gradient validation should resolve every gradient color input')

    assert_error(function()
        GraphicsValidation.validate_root_blend_mode('blendMode', 'alpha', nil, 2)
    end, "blendMode: 'alpha' is not a valid value",
        'Shared root blendMode validation should reject legacy alpha mode strings')

    assert_error(function()
        GraphicsValidation.validate_root_opacity('opacity', 1.5, nil, 2)
    end, 'opacity must be in [0, 1]',
        'Shared root opacity validation should reject values above 1')

    assert_error(function()
        GraphicsValidation.validate_root_shader('shader', false, nil, 2)
    end, 'shader must be a shader object reference',
        'Shared root shader validation should reject non-object shader values')

    local default_state = GraphicsValidation.normalize_root_compositing_state({})
    local shader_state = GraphicsValidation.normalize_root_compositing_state({
        shader = { id = 'fx' },
    })

    assert_equal(default_state.opacity, 1,
        'Shared root compositing normalization should default opacity to 1')
    assert_equal(default_state.blendMode, 'normal',
        'Shared root compositing normalization should default blendMode to normal')
    assert_equal(default_state.shader, nil,
        'Shared root compositing normalization should default shader to nil')
    assert_true(GraphicsValidation.is_default_root_compositing_state(default_state),
        'Shared root compositing normalization should recognize the default state')
    assert_true(not GraphicsValidation.is_default_root_compositing_state(shader_state),
        'Shared root compositing normalization should treat shader-bearing state as non-default')

    assert_error(function()
        GraphicsValidation.validate_gradient('fillGradient', {
            kind = 'linear',
            direction = 'vertical',
            colors = {
                '#ff0000',
            },
        }, nil, 2)
    end, '.colors must contain at least two color inputs',
        'Shared gradient validation should reject single-stop gradients')
end

local function run_schema_integration_tests()
    local texture = nil
    local sprite = nil
    local image_component = nil
    local shader = { id = 'root-fx' }

    texture = select(1, make_texture(64, 32))
    sprite = UI.Sprite.new({
        texture = texture,
        region = {
            x = 8,
            y = 4,
            width = 16,
            height = 12,
        },
    })
    image_component = UI.Image.new({
        source = texture,
        width = 16,
        height = 12,
    })

    local drawable = UI.Drawable.new({
        shader = shader,
        opacity = 0.35,
        blendMode = 'normal',
        backgroundGradient = {
            kind = 'linear',
            direction = 'vertical',
            colors = {
                '#112233',
                '#445566',
            },
        },
        backgroundImage = sprite,
        backgroundOffsetX = -3.5,
        backgroundAlignX = 'end',
    })

    assert_equal(drawable.opacity, 0.35,
        'Drawable should consume shared root opacity validation')
    assert_equal(drawable.blendMode, 'normal',
        'Drawable should consume shared root blendMode validation')
    assert_same(drawable.shader, shader,
        'Drawable should consume the shared root shader validator')
    assert_equal(drawable.backgroundGradient.direction, 'vertical',
        'Drawable should consume the shared gradient validator')
    assert_same(drawable.backgroundImage, sprite,
        'Drawable should consume the shared Texture or Sprite source validator')
    assert_equal(drawable.backgroundOffsetX, -3.5,
        'Drawable should preserve validated background offsets')
    assert_equal(drawable.backgroundAlignX, 'end',
        'Drawable should preserve validated source alignment values')

    assert_error(function()
        UI.Drawable.new({
            opacity = 1.2,
        })
    end, 'opacity must be in [0, 1]',
        'Drawable should reject invalid root opacity values through the shared helper')

    assert_error(function()
        UI.Drawable.new({
            blendMode = 'alpha',
        })
    end, "blendMode: 'alpha' is not a valid value",
        'Drawable should reject non-normalized blendMode values through the shared helper')

    assert_error(function()
        UI.Drawable.new({
            shader = 'bad.shader',
        })
    end, 'shader must be a shader object reference',
        'Drawable should reject invalid shader values through the shared helper')

    assert_error(function()
        UI.Drawable.new({
            backgroundImage = image_component,
        })
    end, 'backgroundImage: Image component is not a valid source — use Texture or Sprite',
        'Drawable should reject Image components as backgroundImage sources through the shared helper')
end

local function run_shape_capability_surface_tests()
    local shader = { id = 'shape-fx' }
    local shape = UI.Shape.new({
        opacity = 0.2,
        blendMode = 'screen',
        shader = shader,
    })
    local rect_shape = UI.RectShape.new({
        width = 16,
        height = 12,
        blendMode = 'add',
    })
    local shape_capabilities = rawget(UI.Shape, '_root_compositing_capabilities')
    local drawable_capabilities = rawget(UI.Drawable, '_root_compositing_capabilities')

    assert_equal(shape.opacity, 0.2,
        'Shape should consume shared root opacity validation')
    assert_equal(shape.blendMode, 'screen',
        'Shape should consume shared root blendMode validation')
    assert_same(shape.shader, shader,
        'Shape should expose shader on the shared root compositing surface')
    assert_equal(rect_shape.blendMode, 'add',
        'Shape subclasses should inherit the shared root compositing surface')
    assert_true(shape_capabilities ~= nil and
        shape_capabilities.opacity == true and
        shape_capabilities.shader == true and
        shape_capabilities.blendMode == true,
        'Shape should declare class-level shared root compositing capabilities')
    assert_true(drawable_capabilities ~= nil and
        drawable_capabilities.opacity == true and
        drawable_capabilities.shader == true and
        drawable_capabilities.blendMode == true,
        'Drawable should declare class-level shared root compositing capabilities')
    assert_true(rawget(shape_capabilities, 'mask') == nil and
        rawget(drawable_capabilities, 'mask') == nil,
        'Shared root compositing capability records should exclude mask')

    assert_error(function()
        UI.Shape.new({
            blendMode = 'alpha',
        })
    end, "blendMode: 'alpha' is not a valid value",
        'Shape should reject non-normalized blendMode values through the shared helper')

    assert_error(function()
        UI.Shape.new({
            shader = 42,
        })
    end, 'shader must be a shader object reference',
        'Shape should reject invalid shader values through the shared helper')
end

local function run_motion_root_compositing_tests()
    local blend_easing_called = false
    local shader_easing_called = false
    local next_shader = { id = 'motion-fx' }
    local shape = UI.RectShape.new({
        width = 24,
        height = 18,
        motion = {
            enter = {
                properties = {
                    blendMode = {
                        from = 'add',
                        to = 'screen',
                        duration = 120,
                        easing = function()
                            blend_easing_called = true
                        end,
                    },
                    shader = {
                        from = { id = 'from-fx' },
                        to = next_shader,
                        duration = 90,
                        easing = function()
                            shader_easing_called = true
                        end,
                    },
                },
            },
        },
    })
    local from_only_shape = UI.RectShape.new({
        width = 24,
        height = 18,
        motion = {
            enter = {
                properties = {
                    blendMode = {
                        from = 'multiply',
                    },
                    shader = {
                        from = { id = 'ignored-fx' },
                    },
                },
            },
        },
    })

    shape:_raise_motion('enter')
    from_only_shape:_raise_motion('enter')

    assert_equal(shape:_get_motion_value('root', 'blendMode'), 'screen',
        'Root blendMode motion should apply the discrete to-value immediately')
    assert_same(shape:_get_motion_value('root', 'shader'), next_shader,
        'Root shader motion should apply the discrete to-value immediately')
    assert_true(not blend_easing_called and not shader_easing_called,
        'Root blendMode and shader motion should ignore easing for discrete-step semantics')
    assert_equal(from_only_shape:_get_motion_value('root', 'blendMode'), nil,
        'Root blendMode motion should ignore from when no to-value is supplied')
    assert_equal(from_only_shape:_get_motion_value('root', 'shader'), nil,
        'Root shader motion should ignore from when no to-value is supplied')

    assert_error(function()
        UI.RectShape.new({
            width = 24,
            height = 18,
            motion = {
                enter = {
                    properties = {
                        shader = {
                            to = false,
                        },
                    },
                },
            },
        }):_raise_motion('enter')
    end, 'shader must be a shader object reference',
        'Root shader motion should fail immediately for invalid shader values')
end

local function run_source_helper_tests()
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

    local texture, texture_source = make_texture(64, 32)
    local sprite = UI.Sprite.new({
        texture = texture,
        region = {
            x = 8,
            y = 4,
            width = 16,
            height = 12,
        },
    })

    local texture_width, texture_height = texture:getIntrinsicDimensions()
    local sprite_width, sprite_height = sprite:getIntrinsicDimensions()
    local texture_drawable, texture_quad, resolved_texture_width, resolved_texture_height =
        GraphicsSource.resolve_draw_source(texture)
    local sprite_drawable, sprite_quad, resolved_sprite_width, resolved_sprite_height =
        GraphicsSource.resolve_draw_source(sprite)

    assert_equal(texture_width, 64,
        'Texture intrinsic dimensions should expose the texture width')
    assert_equal(texture_height, 32,
        'Texture intrinsic dimensions should expose the texture height')
    assert_equal(sprite_width, 16,
        'Sprite intrinsic dimensions should expose the sprite region width')
    assert_equal(sprite_height, 12,
        'Sprite intrinsic dimensions should expose the sprite region height')

    assert_same(texture_drawable, texture_source,
        'Shared draw-source resolution should unwrap Texture to its drawable')
    assert_equal(texture_quad, nil,
        'Texture-backed draw-source resolution should not allocate a quad')
    assert_equal(resolved_texture_width, 64,
        'Texture-backed draw-source resolution should report the texture width')
    assert_equal(resolved_texture_height, 32,
        'Texture-backed draw-source resolution should report the texture height')

    assert_same(sprite_drawable, texture_source,
        'Shared draw-source resolution should unwrap Sprite to the texture drawable')
    assert_true(sprite_quad ~= nil,
        'Sprite-backed draw-source resolution should allocate a quad when available')
    assert_equal(sprite_quad.x, 8,
        'Sprite-backed draw-source resolution should preserve region x')
    assert_equal(sprite_quad.y, 4,
        'Sprite-backed draw-source resolution should preserve region y')
    assert_equal(sprite_quad.width, 16,
        'Sprite-backed draw-source resolution should preserve region width')
    assert_equal(sprite_quad.height, 12,
        'Sprite-backed draw-source resolution should preserve region height')
    assert_equal(resolved_sprite_width, 16,
        'Sprite-backed draw-source resolution should report the sprite width')
    assert_equal(resolved_sprite_height, 12,
        'Sprite-backed draw-source resolution should report the sprite height')

    rawset(_G, 'love', previous_love)
end

local M = {}

function M.run()
    run_validation_helper_tests()
    run_schema_integration_tests()
    run_shape_capability_surface_tests()
    run_motion_root_compositing_tests()
    run_source_helper_tests()
end

return M
