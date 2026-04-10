local TransparentGrid = require('demos.common.transparent_grid')
local UI = require('lib.ui')

local Container = UI.Container
local Drawable = UI.Drawable
local Texture = UI.Texture

local FRAME_CONTENT_INSET = 1

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

            local frame = Drawable.new({
                id = 'texture-background-frame',
                width = 420,
                height = 320,
                backgroundColor = nil,
                borderColor = { 0.72, 0.75, 0.81 },
                borderWidth = 1,
                borderDashLength = 10,
                borderStyle = 'rough',
                borderPattern = 'dashed',
            })

            local group = Container.new({
                id = 'texture-background-group',
                x = FRAME_CONTENT_INSET,
                y = FRAME_CONTENT_INSET,
                width = frame.width - (FRAME_CONTENT_INSET * 2),
                height = frame.height - (FRAME_CONTENT_INSET * 2),
                clipChildren = true,
            })
            local grid = TransparentGrid.new({
                id = 'texture-background-grid',
                width = group.width,
                height = group.height,
            })
            local target = Drawable.new({
                id = 'texture-background-target',
                width = 260,
                height = 220,
                backgroundImage = texture,
                backgroundAlignX = 'center',
                backgroundAlignY = 'center',
                backgroundOffsetX = 0,
                backgroundOffsetY = 0,
                cornerRadius = 30,
                borderColor = { 0.72, 0.75, 0.81 },
                borderWidth = 2,
            })

            group:addChild(grid)
            group:addChild(target)
            frame:addChild(group)
            root:addChild(frame)

            return {
                title = 'Texture Background',
                description = 'Inspect Drawable backgroundImage using the labeled grid texture. Switch between a full Texture and Sprite subregions, then compare how alignment and offsets reposition the sampled source inside the Drawable bounds.',
            }
        end
    )
end
