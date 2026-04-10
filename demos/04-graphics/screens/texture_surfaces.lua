local TransparentGrid = require('demos.common.transparent_grid')
local UI = require('lib.ui')

local Container = UI.Container
local Drawable = UI.Drawable
local RectShape = UI.RectShape
local CircleShape = UI.CircleShape
local Texture = UI.Texture

local FRAME_SIZE = 250
local FRAME_CONTENT_INSET = 1
local GROUP_SIZE = FRAME_SIZE - (FRAME_CONTENT_INSET * 2)
local TARGET_SIZE = 200

local function new_frame(id)
    return Drawable.new({
        id = id,
        width = FRAME_SIZE,
        height = FRAME_SIZE,
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
        width = GROUP_SIZE,
        height = GROUP_SIZE,
        clipChildren = true,
    })
end

local function new_grid(id)
    return TransparentGrid.new({
        id = id,
        width = GROUP_SIZE,
        height = GROUP_SIZE,
    })
end

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(stage)
            local root = stage.baseSceneLayer
            local image = love.graphics.newImage('assets/images/image.png')
            local texture = Texture.new({
                source = image,
            })

            if type(image.setFilter) == 'function' then
                image:setFilter('nearest', 'nearest')
            end

            local drawable_frame = new_frame('texture-surfaces-drawable-frame')
            local drawable_group = new_group('texture-surfaces-drawable-group')
            local drawable_grid = new_grid('texture-surfaces-drawable-grid')
            local drawable_target = Drawable.new({
                id = 'texture-surfaces-drawable-target',
                width = TARGET_SIZE,
                height = TARGET_SIZE,
                backgroundImage = texture,
                backgroundRepeatX = true,
                backgroundRepeatY = true,
                backgroundAlignX = 'center',
                backgroundAlignY = 'center',
                backgroundOffsetX = 0,
                backgroundOffsetY = 0,
                cornerRadius = 30,
                borderColor = { 0.72, 0.75, 0.81 },
                borderWidth = 2,
            })

            local rect_frame = new_frame('texture-surfaces-rect-frame')
            local rect_group = new_group('texture-surfaces-rect-group')
            local rect_grid = new_grid('texture-surfaces-rect-grid')
            local rect_target = RectShape.new({
                id = 'texture-surfaces-rect-target',
                width = TARGET_SIZE,
                height = TARGET_SIZE,
                fillTexture = texture,
                fillRepeatX = true,
                fillRepeatY = true,
                fillAlignX = 'center',
                fillAlignY = 'center',
                fillOffsetX = 0,
                fillOffsetY = 0,
                strokeColor = { 0.72, 0.75, 0.81 },
                strokeWidth = 2,
            })

            local circle_frame = new_frame('texture-surfaces-circle-frame')
            local circle_group = new_group('texture-surfaces-circle-group')
            local circle_grid = new_grid('texture-surfaces-circle-grid')
            local circle_target = CircleShape.new({
                id = 'texture-surfaces-circle-target',
                width = TARGET_SIZE,
                height = TARGET_SIZE,
                fillTexture = texture,
                fillRepeatX = true,
                fillRepeatY = true,
                fillAlignX = 'center',
                fillAlignY = 'center',
                fillOffsetX = 0,
                fillOffsetY = 0,
                strokeColor = { 0.72, 0.75, 0.81 },
                strokeWidth = 2,
            })

            drawable_group:addChild(drawable_grid)
            drawable_group:addChild(drawable_target)
            drawable_frame:addChild(drawable_group)

            rect_group:addChild(rect_grid)
            rect_group:addChild(rect_target)
            rect_frame:addChild(rect_group)

            circle_group:addChild(circle_grid)
            circle_group:addChild(circle_target)
            circle_frame:addChild(circle_group)

            root:addChild(drawable_frame)
            root:addChild(rect_frame)
            root:addChild(circle_frame)

            return {
                title = 'Texture Surfaces',
                description = 'Compare one texture source across the raw subregion preview, Drawable backgroundImage, RectShape fillTexture, and CircleShape fillTexture. Repeat, alignment, and offsets are shared controls here; when repeat is Off, the shapes switch to stretch mode while Drawable keeps a single placed source tile.',
            }
        end
    )
end
