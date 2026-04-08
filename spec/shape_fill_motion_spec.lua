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

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function assert_near(actual, expected, tolerance, message)
    tolerance = tolerance or 0.0001

    if math.abs(actual - expected) > tolerance then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
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

    if needle ~= nil and not text:find(needle, 1, true) then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
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

local function run_fill_motion_surface_tests()
    local texture = make_texture(64, 32)
    local sprite = make_sprite(texture, 8, 4, 16, 12)
    local fill_color_easing_called = false
    local fill_opacity_easing_called = false
    local fill_gradient_easing_called = false
    local fill_texture_easing_called = false
    local fill_offset_easing_called = false
    local fill_align_x_easing_called = false
    local fill_align_y_easing_called = false
    local shape = UI.RectShape.new({
        width = 40,
        height = 20,
        fillGradient = {
            kind = 'linear',
            direction = 'vertical',
            colors = {
                '#000000',
                '#ffffff',
            },
        },
        motion = {
            enter = {
                properties = {
                    fillColor = {
                        to = '#224466cc',
                        easing = function()
                            fill_color_easing_called = true
                        end,
                    },
                    fillOpacity = {
                        to = 0.35,
                        easing = function()
                            fill_opacity_easing_called = true
                        end,
                    },
                    fillGradient = {
                        to = {
                            kind = 'linear',
                            direction = 'horizontal',
                            colors = {
                                '#112233',
                                '#445566',
                                '#778899',
                            },
                        },
                        easing = function()
                            fill_gradient_easing_called = true
                        end,
                    },
                    fillTexture = {
                        to = sprite,
                        easing = function()
                            fill_texture_easing_called = true
                        end,
                    },
                    fillOffsetX = {
                        to = 6.5,
                        easing = function()
                            fill_offset_easing_called = true
                        end,
                    },
                    fillOffsetY = {
                        to = -3.25,
                    },
                    fillAlignX = {
                        to = 'end',
                        easing = function()
                            fill_align_x_easing_called = true
                        end,
                    },
                    fillAlignY = {
                        to = 'start',
                        easing = function()
                            fill_align_y_easing_called = true
                        end,
                    },
                },
            },
        },
    })

    shape:_raise_motion('enter')

    local fill_surface = shape:_resolve_fill_surface()
    local active_fill = shape:_resolve_active_fill_source()

    assert_true(fill_color_easing_called,
        'Shape fillColor motion should follow the continuous-property path')
    assert_true(fill_opacity_easing_called,
        'Shape fillOpacity motion should follow the continuous-property path')
    assert_true(fill_gradient_easing_called,
        'Shape fillGradient motion should follow the continuous-property path')
    assert_true(fill_offset_easing_called,
        'Shape fillOffset motion should follow the continuous-property path')
    assert_true(not fill_texture_easing_called,
        'Shape fillTexture motion should ignore easing for discrete-step semantics')
    assert_true(not fill_align_x_easing_called and not fill_align_y_easing_called,
        'Shape fillAlign motion should ignore easing for discrete-step semantics')

    assert_near(fill_surface.fillColor[1], 0x22 / 255, nil,
        'Shape fill motion should resolve fillColor.r through the shared validator')
    assert_near(fill_surface.fillColor[2], 0x44 / 255, nil,
        'Shape fill motion should resolve fillColor.g through the shared validator')
    assert_near(fill_surface.fillColor[3], 0x66 / 255, nil,
        'Shape fill motion should resolve fillColor.b through the shared validator')
    assert_near(fill_surface.fillColor[4], 0xcc / 255, nil,
        'Shape fill motion should resolve fillColor.a through the shared validator')
    assert_equal(fill_surface.fillOpacity, 0.35,
        'Shape fill motion should store fillOpacity on the shape-local fill surface')
    assert_equal(fill_surface.fillGradient.direction, 'horizontal',
        'Shape fillGradient motion should preserve the motion-written direction')
    assert_equal(#fill_surface.fillGradient.colors, 3,
        'Shape fillGradient motion should preserve the motion-written stop count')
    assert_near(fill_surface.fillGradient.colors[1][1], 0x11 / 255, nil,
        'Shape fillGradient motion should resolve stop colors through the shared validator')
    assert_near(fill_surface.fillGradient.colors[3][3], 0x99 / 255, nil,
        'Shape fillGradient motion should preserve later stop colors')
    assert_same(fill_surface.fillTexture, sprite,
        'Shape fillTexture motion should preserve the source object by reference')
    assert_equal(fill_surface.fillOffsetX, 6.5,
        'Shape fillOffsetX motion should store the motion-written value')
    assert_equal(fill_surface.fillOffsetY, -3.25,
        'Shape fillOffsetY motion should store the motion-written value')
    assert_equal(fill_surface.fillAlignX, 'end',
        'Shape fillAlignX motion should store the discrete to-value')
    assert_equal(fill_surface.fillAlignY, 'start',
        'Shape fillAlignY motion should store the discrete to-value')
    assert_equal(active_fill.kind, 'texture',
        'Shape fill motion should still resolve active source priority from the resulting property values')
    assert_same(active_fill.source, sprite,
        'Shape active fill should expose the motion-written texture source')
    assert_equal(active_fill.alignX, 'end',
        'Shape active fill should expose motion-written alignX')
    assert_equal(active_fill.alignY, 'start',
        'Shape active fill should expose motion-written alignY')
end

local function run_priority_resolution_tests()
    local shape = UI.RectShape.new({
        width = 40,
        height = 20,
        fillColor = '#112233',
        fillGradient = {
            kind = 'linear',
            direction = 'vertical',
            colors = {
                '#000000',
                '#ffffff',
            },
        },
        motion = {
            enter = {
                properties = {
                    fillColor = {
                        to = '#ff0000',
                    },
                    fillOpacity = {
                        to = 0.4,
                    },
                },
            },
        },
    })

    shape:_raise_motion('enter')

    local fill_surface = shape:_resolve_fill_surface()
    local active_fill = shape:_resolve_active_fill_source()

    assert_near(fill_surface.fillColor[1], 1, nil,
        'Shape fillColor motion should still write the lower-priority property value')
    assert_near(fill_surface.fillColor[2], 0, nil,
        'Shape fillColor motion should still write the lower-priority property value g')
    assert_near(fill_surface.fillColor[3], 0, nil,
        'Shape fillColor motion should still write the lower-priority property value b')
    assert_equal(fill_surface.fillOpacity, 0.4,
        'Shape fillOpacity motion should still affect the fill surface while gradient remains active')
    assert_equal(active_fill.kind, 'gradient',
        'Shape fill motion must not bypass the documented source-priority rule')
    assert_same(active_fill.gradient, shape.fillGradient,
        'Shape fill priority should continue to prefer the higher-priority stored gradient when no motion overrides it')
end

local function run_discrete_from_only_tests()
    local texture = make_texture(64, 32)
    local sprite = make_sprite(texture, 8, 4, 16, 12)
    local shape = UI.RectShape.new({
        width = 40,
        height = 20,
        fillColor = '#224466',
        motion = {
            enter = {
                properties = {
                    fillTexture = {
                        from = sprite,
                    },
                    fillAlignX = {
                        from = 'end',
                    },
                    fillAlignY = {
                        from = 'start',
                    },
                },
            },
        },
    })

    shape:_raise_motion('enter')

    assert_nil(shape:_get_motion_value('root', 'fillTexture'),
        'Shape fillTexture motion should ignore from when no to-value is supplied')
    assert_nil(shape:_get_motion_value('root', 'fillAlignX'),
        'Shape fillAlignX motion should ignore from when no to-value is supplied')
    assert_nil(shape:_get_motion_value('root', 'fillAlignY'),
        'Shape fillAlignY motion should ignore from when no to-value is supplied')
    assert_equal(shape:_resolve_active_fill_source().kind, 'color',
        'Shape fill priority should remain on the stored color path when discrete motion provides no to-value')
end

local function run_validation_tests()
    assert_error(function()
        UI.RectShape.new({
            width = 24,
            height = 18,
            motion = {
                enter = {
                    properties = {
                        fillRepeatX = {
                            to = true,
                        },
                    },
                },
            },
        })
    end, 'unsupported motion property "fillRepeatX"',
        'Shape fillRepeatX must remain rejected as a motion property')

    assert_error(function()
        UI.RectShape.new({
            width = 24,
            height = 18,
            motion = {
                enter = {
                    properties = {
                        fillRepeatY = {
                            to = true,
                        },
                    },
                },
            },
        })
    end, 'unsupported motion property "fillRepeatY"',
        'Shape fillRepeatY must remain rejected as a motion property')

    assert_error(function()
        UI.RectShape.new({
            width = 24,
            height = 18,
            motion = {
                enter = {
                    properties = {
                        fillTexture = {
                            to = {},
                        },
                    },
                },
            },
        }):_raise_motion('enter')
    end, 'fillTexture must be a Texture or Sprite instance',
        'Shape fillTexture motion should fail immediately for invalid source types')

    assert_error(function()
        UI.RectShape.new({
            width = 24,
            height = 18,
            motion = {
                enter = {
                    properties = {
                        fillGradient = {
                            to = {
                                kind = 'linear',
                                direction = 'vertical',
                                colors = {
                                    '#ff0000',
                                },
                            },
                        },
                    },
                },
            },
        }):_raise_motion('enter')
    end, '.colors must contain at least two color inputs',
        'Shape fillGradient motion should use the shared gradient validator')

    assert_error(function()
        UI.RectShape.new({
            width = 24,
            height = 18,
            motion = {
                enter = {
                    properties = {
                        fillAlignX = {
                            to = 'stretch',
                        },
                    },
                },
            },
        }):_raise_motion('enter')
    end, "fillAlignX: 'stretch' is not a valid value",
        'Shape fillAlignX motion should use the shared alignment validator')
end

local M = {}

function M.run()
    run_fill_motion_surface_tests()
    run_priority_resolution_tests()
    run_discrete_from_only_tests()
    run_validation_tests()
end

return M
