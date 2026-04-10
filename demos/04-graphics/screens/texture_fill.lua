local TransparentGrid = require('demos.common.transparent_grid')
local UI = require('lib.ui')

local Container = UI.Container
local Drawable = UI.Drawable
local RectShape = UI.RectShape
local CircleShape = UI.CircleShape
local Texture = UI.Texture

local FRAME_CONTENT_INSET = 1

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(scope, stage)
            local root = stage.baseSceneLayer
            local image = scope:track(love.graphics.newImage('assets/images/image.png'))
            local texture = Texture.new({
                source = image,
            })

            if type(image.setFilter) == 'function' then
                image:setFilter('nearest', 'nearest')
            end

            local rect_frame = Drawable.new({
                id = 'texture-fill-rect-frame',
                width = 280,
                height = 280,
                backgroundColor = nil,
                borderColor = { 0.72, 0.75, 0.81 },
                borderWidth = 1,
                borderDashLength = 10,
                borderStyle = 'rough',
                borderPattern = 'dashed',
            })
            local rect_group = Container.new({
                id = 'texture-fill-rect-group',
                x = FRAME_CONTENT_INSET,
                y = FRAME_CONTENT_INSET,
                width = rect_frame.width - (FRAME_CONTENT_INSET * 2),
                height = rect_frame.height - (FRAME_CONTENT_INSET * 2),
                clipChildren = true,
            })
            local rect_grid = TransparentGrid.new({
                id = 'texture-fill-rect-grid',
                width = rect_group.width,
                height = rect_group.height,
            })
            local rect_target = RectShape.new({
                id = 'texture-fill-rect-target',
                width = 220,
                height = 220,
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

            local circle_frame = Drawable.new({
                id = 'texture-fill-circle-frame',
                width = 280,
                height = 280,
                backgroundColor = nil,
                borderColor = { 0.72, 0.75, 0.81 },
                borderWidth = 1,
                borderDashLength = 10,
                borderStyle = 'rough',
                borderPattern = 'dashed',
            })
            local circle_group = Container.new({
                id = 'texture-fill-circle-group',
                x = FRAME_CONTENT_INSET,
                y = FRAME_CONTENT_INSET,
                width = circle_frame.width - (FRAME_CONTENT_INSET * 2),
                height = circle_frame.height - (FRAME_CONTENT_INSET * 2),
                clipChildren = true,
            })
            local circle_grid = TransparentGrid.new({
                id = 'texture-fill-circle-grid',
                width = circle_group.width,
                height = circle_group.height,
            })
            local circle_target = CircleShape.new({
                id = 'texture-fill-circle-target',
                width = 220,
                height = 220,
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

            rect_group:addChild(rect_grid)
            rect_group:addChild(rect_target)
            rect_frame:addChild(rect_group)
            circle_group:addChild(circle_grid)
            circle_group:addChild(circle_target)
            circle_frame:addChild(circle_group)
            root:addChild(rect_frame)
            root:addChild(circle_frame)

            return {
                title = 'Texture Fill',
                description = 'Inspect Shape fillTexture on RectShape and CircleShape using the labeled grid texture. Switch between full Texture and Sprite subregions, then compare repeat mode, alignment, and offsets through the shape-owned fill placement contract.',
            }
        end
    )
end
