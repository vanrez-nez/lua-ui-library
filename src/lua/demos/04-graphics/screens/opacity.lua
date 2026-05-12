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
local GRID_PRIMARY = { 0.12, 0.13, 0.17, 1 }
local GRID_SECONDARY = { 0.14, 0.16, 0.21, 1 }

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
                id = 'opacity-drawable-frame',
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
                id = 'opacity-drawable-group',
                x = FRAME_CONTENT_INSET,
                y = FRAME_CONTENT_INSET,
                width = GROUP_WIDTH,
                height = GROUP_HEIGHT,
                clipChildren = true,
            })
            local drawable_background = new_group_background('opacity-drawable-background')

            local drawable_a = Drawable.new({
                id = 'opacity-drawable-a',
                tag = 'Drawable A',
                x = 50,
                y = 45,
                width = 140,
                height = 100,
                interactive = true,
                backgroundColor = { 1, 0, 0 },
                borderColor = { 0, 1, 0 },
                borderWidth = 8,
                opacity = 1,
            })

            local drawable_b = Drawable.new({
                id = 'opacity-drawable-b',
                tag = 'Drawable B',
                x = 90,
                y = 80,
                width = 140,
                height = 100,
                interactive = true,
                backgroundColor = { 0, 1, 0 },
                borderColor = { 1, 0, 0 },
                borderWidth = 8,
                opacity = 1,
            })

            local drawable_c = Drawable.new({
                id = 'opacity-drawable-c',
                tag = 'Drawable C',
                x = 130,
                y = 115,
                width = 140,
                height = 100,
                interactive = true,
                backgroundColor = { 0, 0, 1 },
                borderColor = { 0, 1, 0 },
                borderWidth = 8,
                opacity = 1,
            })

            local shape_frame = Drawable.new({
                id = 'opacity-shape-frame',
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
                id = 'opacity-shape-group',
                x = FRAME_CONTENT_INSET,
                y = FRAME_CONTENT_INSET,
                width = GROUP_WIDTH,
                height = GROUP_HEIGHT,
                clipChildren = true,
            })
            local shape_background = new_group_background('opacity-shape-background')

            local shape_a = CircleShape.new({
                id = 'opacity-shape-a',
                tag = 'Shape A',
                x = 50,
                y = 25,
                width = 130,
                height = 130,
                interactive = true,
                fillColor = { 1, 0, 0 },
                strokeColor = { 0, 1, 0 },
                strokeWidth = 8,
                opacity = 1,
            })

            local shape_b = CircleShape.new({
                id = 'opacity-shape-b',
                tag = 'Shape B',
                x = 140,
                y = 25,
                width = 130,
                height = 130,
                interactive = true,
                fillColor = { 0, 1, 0 },
                strokeColor = { 1, 0, 0 },
                strokeWidth = 8,
                opacity = 1,
            })

            local shape_c = CircleShape.new({
                id = 'opacity-shape-c',
                tag = 'Shape C',
                x = 95,
                y = 105,
                width = 130,
                height = 130,
                interactive = true,
                fillColor = { 0, 0, 1 },
                strokeColor = { 0, 1, 0 },
                strokeWidth = 8,
                opacity = 1,
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
                title = 'Opacity',
                description = 'Compare overlapping Drawables and CircleShapes side by side under the same per-node opacity preset. Both node types share the same root opacity contract, so this screen shows the same compositing behavior on two different retained presentations: box-backed Drawables and primitive CircleShapes.',
            }
        end
    )
end
