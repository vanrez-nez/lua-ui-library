local TransparentGrid = require('demos.common.transparent_grid')
local UI = require('lib.ui')

local Container = UI.Container
local Drawable = UI.Drawable
local Image = UI.Image
local Texture = UI.Texture
local Sprite = UI.Sprite

local FRAME_SIZE = 180
local FRAME_CONTENT_INSET = 1
local GROUP_SIZE = FRAME_SIZE - (FRAME_CONTENT_INSET * 2)

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

local function new_case(id, source, opts)
    local frame = new_frame(id .. '-frame')
    local group = new_group(id .. '-group')
    local grid = new_grid(id .. '-grid')
    local image = Image.new({
        id = id .. '-image',
        width = GROUP_SIZE,
        height = GROUP_SIZE,
        source = source,
        fit = opts.fit,
        alignX = opts.alignX,
        alignY = opts.alignY,
        sampling = opts.sampling,
        scaleX = opts.scaleX,
        scaleY = opts.scaleY,
        rotation = opts.rotation,
    })

    group:addChild(grid)
    group:addChild(image)
    frame:addChild(group)

    return frame
end

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(stage)
            local root = stage.baseSceneLayer
            local texture = Texture.new({
                source = love.graphics.newImage('assets/images/image.png'),
            })
            local portrait_sprite = Sprite.new({
                texture = texture,
                region = {
                    x = 0,
                    y = 512,
                    width = 256,
                    height = 512,
                },
            })
            local detail_sprite = Sprite.new({
                texture = texture,
                region = {
                    x = 64,
                    y = 64,
                    width = 64,
                    height = 64,
                },
            })

            root:addChild(new_case('image-contain', portrait_sprite, {
                fit = 'contain',
                alignX = 'center',
                alignY = 'center',
                sampling = 'linear',
            }))
            root:addChild(new_case('image-cover', portrait_sprite, {
                fit = 'cover',
                alignX = 'center',
                alignY = 'center',
                sampling = 'linear',
            }))
            root:addChild(new_case('image-stretch', portrait_sprite, {
                fit = 'stretch',
                alignX = 'center',
                alignY = 'center',
                sampling = 'linear',
            }))
            root:addChild(new_case('image-none-center', portrait_sprite, {
                fit = 'none',
                alignX = 'center',
                alignY = 'center',
                sampling = 'linear',
            }))
            root:addChild(new_case('image-none-start', portrait_sprite, {
                fit = 'none',
                alignX = 'start',
                alignY = 'start',
                sampling = 'linear',
            }))
            root:addChild(new_case('image-none-end', portrait_sprite, {
                fit = 'none',
                alignX = 'end',
                alignY = 'end',
                sampling = 'linear',
            }))
            root:addChild(new_case('image-texture-source', texture, {
                fit = 'contain',
                alignX = 'center',
                alignY = 'center',
                sampling = 'linear',
            }))
            root:addChild(new_case('image-nearest-detail', detail_sprite, {
                fit = 'stretch',
                alignX = 'center',
                alignY = 'center',
                sampling = 'nearest',
            }))
            root:addChild(new_case('image-transform', portrait_sprite, {
                fit = 'contain',
                alignX = 'center',
                alignY = 'center',
                sampling = 'linear',
                scaleX = 0.85,
                scaleY = 1.15,
                rotation = math.rad(18),
            }))

            return {
                title = 'Image Presentation',
                description = 'Compare the retained Image primitive across fit modes, alignment under fit="none", Texture versus Sprite sources, nearest sampling on an enlarged detail crop, and inherited scale and rotation transforms on the image node itself.',
            }
        end
    )
end
