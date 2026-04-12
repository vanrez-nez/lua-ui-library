local DemoColors = require('demos.common.colors')
local TransparentGrid = require('demos.common.transparent_grid')
local UI = require('lib.ui')

local Container = UI.Container
local Drawable = UI.Drawable
local CircleShape = UI.CircleShape
local RectShape = UI.RectShape

local FRAME_WIDTH = 240
local FRAME_HEIGHT = 190
local FRAME_CONTENT_INSET = 1
local GROUP_WIDTH = FRAME_WIDTH - (FRAME_CONTENT_INSET * 2)
local GROUP_HEIGHT = FRAME_HEIGHT - (FRAME_CONTENT_INSET * 2)

local CASES = {
    {
        id = 'off',
        shader_key = 'none',
    },
    {
        id = 'duotone',
        shader_key = 'duotone',
    },
    {
        id = 'posterize',
        shader_key = 'posterize',
    },
    {
        id = 'scanlines',
        shader_key = 'scanlines',
    },
}

local function new_frame(id)
    return Drawable.new({
        id = id,
        width = FRAME_WIDTH,
        height = FRAME_HEIGHT,
        backgroundColor = nil,
        borderColor = { 0.72, 0.75, 0.81 },
        borderWidth = 1,
        borderDashLength = 10,
        borderStyle = 'rough',
        borderPattern = 'dashed',
    })
end

local function new_group(id)
    return Container.new({
        id = id,
        x = FRAME_CONTENT_INSET,
        y = FRAME_CONTENT_INSET,
        width = GROUP_WIDTH,
        height = GROUP_HEIGHT,
        clipChildren = true,
    })
end

local function new_grid(id)
    return TransparentGrid.new({
        id = id,
        width = GROUP_WIDTH,
        height = GROUP_HEIGHT,
        primaryColor = DemoColors.names.slate_900,
        secondaryColor = DemoColors.names.slate_800,
    })
end

local function build_shaders()
    return {
        none = nil,
        duotone = love.graphics.newShader([[
            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
            {
                vec4 pixel = Texel(texture, texture_coords) * color;
                float luma = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
                vec3 dark = vec3(0.10, 0.17, 0.29);
                vec3 light = vec3(0.98, 0.79, 0.28);
                return vec4(mix(dark, light, luma), pixel.a);
            }
        ]]),
        posterize = love.graphics.newShader([[
            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
            {
                vec4 pixel = Texel(texture, texture_coords) * color;
                pixel.rgb = floor((pixel.rgb * 4.0) + 0.5) / 4.0;
                return pixel;
            }
        ]]),
        scanlines = love.graphics.newShader([[
            vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
            {
                vec4 pixel = Texel(texture, texture_coords) * color;
                float bands = 0.88 + (sin(screen_coords.y * 0.95) * 0.12);
                float sweep = 0.94 + (sin(screen_coords.x * 0.08) * 0.04);
                pixel.rgb *= bands * sweep;
                return pixel;
            }
        ]]),
    }
end

local function new_drawable_fixture(id, shader)
    local target = Drawable.new({
        id = id,
        x = 14,
        y = 14,
        width = 210,
        height = 150,
        interactive = true,
        shader = shader,
        clipChildren = true,
        backgroundColor = DemoColors.rgba(DemoColors.roles.surface_emphasis, 0.96),
        borderColor = DemoColors.roles.border_light,
        borderWidth = 2,
        cornerRadius = 16,
    })

    local header = Drawable.new({
        x = 16,
        y = 14,
        width = 112,
        height = 14,
        backgroundColor = DemoColors.rgba(DemoColors.roles.body, 0.88),
        cornerRadius = 7,
    })

    local card_a = Drawable.new({
        x = 22,
        y = 48,
        width = 82,
        height = 58,
        backgroundColor = DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.78),
        borderColor = DemoColors.roles.accent_red_line,
        borderWidth = 5,
        cornerRadius = 12,
    })

    local card_b = Drawable.new({
        x = 82,
        y = 72,
        width = 88,
        height = 58,
        backgroundColor = DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.78),
        borderColor = DemoColors.roles.accent_cyan_line,
        borderWidth = 5,
        cornerRadius = 12,
    })

    local badge = CircleShape.new({
        x = 138,
        y = 28,
        width = 42,
        height = 42,
        fillColor = DemoColors.roles.accent_amber_fill,
        strokeColor = DemoColors.roles.accent_amber_line,
        strokeWidth = 5,
    })

    local spot = CircleShape.new({
        x = 124,
        y = 92,
        width = 48,
        height = 48,
        fillColor = DemoColors.roles.accent_green_fill,
        strokeColor = DemoColors.roles.accent_green_line,
        strokeWidth = 5,
    })

    target:addChild(header)
    target:addChild(card_a)
    target:addChild(card_b)
    target:addChild(badge)
    target:addChild(spot)

    return target
end

local function new_shape_fixture(id, shader)
    return RectShape.new({
        id = id,
        x = 28,
        y = 26,
        width = 182,
        height = 120,
        interactive = true,
        shader = shader,
        fillColor = DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.92),
        strokeColor = '#fff2c7',
        strokeWidth = 10,
        strokeStyle = 'rough',
        strokePattern = 'dashed',
        strokeDashLength = 18,
        strokeGapLength = 8,
    })
end

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(stage)
            local root = stage.baseSceneLayer
            local shaders = build_shaders()

            for index = 1, #CASES do
                local case = CASES[index]
                local shader = shaders[case.shader_key]

                local drawable_frame = new_frame('shader-' .. case.id .. '-drawable-frame')
                local drawable_group = new_group('shader-' .. case.id .. '-drawable-group')
                local drawable_grid = new_grid('shader-' .. case.id .. '-drawable-grid')
                local drawable_target = new_drawable_fixture(
                    'shader-' .. case.id .. '-drawable-target',
                    shader
                )

                local shape_frame = new_frame('shader-' .. case.id .. '-shape-frame')
                local shape_group = new_group('shader-' .. case.id .. '-shape-group')
                local shape_grid = new_grid('shader-' .. case.id .. '-shape-grid')
                local shape_target = new_shape_fixture(
                    'shader-' .. case.id .. '-shape-target',
                    shader
                )

                drawable_group:addChild(drawable_grid)
                drawable_group:addChild(drawable_target)
                drawable_frame:addChild(drawable_group)

                shape_group:addChild(shape_grid)
                shape_group:addChild(shape_target)
                shape_frame:addChild(shape_group)

                root:addChild(drawable_frame)
                root:addChild(shape_frame)
            end

            return {
                title = 'Shader',
                description = 'Each column applies the same root shader preset to two different retained surfaces. The top row uses a Drawable with descendant content so the shader runs on the fully composited subtree result; the bottom row applies the same root shader to a RectShape so the shader runs on the fully composited fill-and-stroke result.',
            }
        end
    )
end
