local DemoColors = require('demos.common.colors')
local TransparentGrid = require('demos.common.transparent_grid')
local UI = require('lib.ui')

local Container = UI.Container
local Drawable = UI.Drawable
local CircleShape = UI.CircleShape

local FRAME_WIDTH = 320
local FRAME_HEIGHT = 260
local FRAME_CONTENT_INSET = 1
local GROUP_WIDTH = FRAME_WIDTH - (FRAME_CONTENT_INSET * 2)
local GROUP_HEIGHT = FRAME_HEIGHT - (FRAME_CONTENT_INSET * 2)

local MAGENTA_FILL = { 0.94, 0.34, 0.82 }
local MAGENTA_LINE = { 0.76, 0.18, 0.62 }
local CYAN_FILL = { 0.34, 0.9, 0.96 }
local CYAN_LINE = { 0.12, 0.67, 0.76 }
local YELLOW_FILL = { 0.98, 0.88, 0.32 }
local YELLOW_LINE = { 0.8, 0.67, 0.1 }
local GRID_PRIMARY = DemoColors.names.slate_900
local GRID_SECONDARY = DemoColors.names.slate_800

local function new_group_background(id)
    return TransparentGrid.new({
        id = id,
        width = GROUP_WIDTH,
        height = GROUP_HEIGHT,
        primaryColor = GRID_PRIMARY,
        secondaryColor = GRID_SECONDARY,
    })
end

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(stage)
            local root = stage.baseSceneLayer

            local drawable_frame = Drawable.new({
                id = 'blendmode-drawable-frame',
                width = FRAME_WIDTH,
                height = FRAME_HEIGHT,
                backgroundColor = nil,
                borderColor = { 0.72, 0.75, 0.81 },
                borderWidth = 1,
                borderDashLength = 10,
                borderStyle = 'rough',
                borderPattern = 'dashed',
            })

            local drawable_group = Container.new({
                id = 'blendmode-drawable-group',
                x = FRAME_CONTENT_INSET,
                y = FRAME_CONTENT_INSET,
                width = GROUP_WIDTH,
                height = GROUP_HEIGHT,
                clipChildren = true,
            })
            local drawable_background = new_group_background('blendmode-drawable-background')

            local drawable_a = Drawable.new({
                id = 'blendmode-drawable-a',
                tag = 'Drawable A',
                x = 50,
                y = 45,
                width = 140,
                height = 100,
                interactive = true,
                backgroundColor = MAGENTA_FILL,
                borderColor = MAGENTA_LINE,
                borderWidth = 8,
                blendMode = 'normal',
            })

            local drawable_b = Drawable.new({
                id = 'blendmode-drawable-b',
                tag = 'Drawable B',
                x = 90,
                y = 80,
                width = 140,
                height = 100,
                interactive = true,
                backgroundColor = CYAN_FILL,
                borderColor = CYAN_LINE,
                borderWidth = 8,
                blendMode = 'normal',
            })

            local drawable_c = Drawable.new({
                id = 'blendmode-drawable-c',
                tag = 'Drawable C',
                x = 130,
                y = 115,
                width = 140,
                height = 100,
                interactive = true,
                backgroundColor = YELLOW_FILL,
                borderColor = YELLOW_LINE,
                borderWidth = 8,
                blendMode = 'normal',
            })

            local shape_frame = Drawable.new({
                id = 'blendmode-shape-frame',
                width = FRAME_WIDTH,
                height = FRAME_HEIGHT,
                backgroundColor = nil,
                borderColor = { 0.72, 0.75, 0.81 },
                borderWidth = 1,
                borderDashLength = 10,
                borderStyle = 'rough',
                borderPattern = 'dashed',
            })

            local shape_group = Container.new({
                id = 'blendmode-shape-group',
                x = FRAME_CONTENT_INSET,
                y = FRAME_CONTENT_INSET,
                width = GROUP_WIDTH,
                height = GROUP_HEIGHT,
                clipChildren = true,
            })
            local shape_background = new_group_background('blendmode-shape-background')

            local shape_a = CircleShape.new({
                id = 'blendmode-shape-a',
                tag = 'Shape A',
                x = 50,
                y = 25,
                width = 130,
                height = 130,
                interactive = true,
                fillColor = MAGENTA_FILL,
                strokeColor = MAGENTA_LINE,
                strokeWidth = 8,
                blendMode = 'normal',
            })

            local shape_b = CircleShape.new({
                id = 'blendmode-shape-b',
                tag = 'Shape B',
                x = 140,
                y = 25,
                width = 130,
                height = 130,
                interactive = true,
                fillColor = CYAN_FILL,
                strokeColor = CYAN_LINE,
                strokeWidth = 8,
                blendMode = 'normal',
            })

            local shape_c = CircleShape.new({
                id = 'blendmode-shape-c',
                tag = 'Shape C',
                x = 95,
                y = 105,
                width = 130,
                height = 130,
                interactive = true,
                fillColor = YELLOW_FILL,
                strokeColor = YELLOW_LINE,
                strokeStyle = 'rough',
                strokeWidth = 8,
                blendMode = 'normal',
            })

            drawable_group:addChild(drawable_background)
            drawable_group:addChild(drawable_a)
            drawable_group:addChild(drawable_b)
            drawable_group:addChild(drawable_c)
            shape_group:addChild(shape_background)
            shape_group:addChild(shape_a)
            shape_group:addChild(shape_b)
            shape_group:addChild(shape_c)
            drawable_frame:addChild(drawable_group)
            shape_frame:addChild(shape_group)
            root:addChild(drawable_frame)
            root:addChild(shape_frame)

            return {
                title = 'Blend Mode',
                description = 'Compare overlapping Drawables and CircleShapes side by side under the same blend-mode preset. Click items to change the stacking order, then inspect the real overlap at the center of each frame.',
            }
        end
    )
end
