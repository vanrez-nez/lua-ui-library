local ScreenHelper = require('demos.common.screen_helper')
local DemoAssets = require('demos.common.demo_assets')
local ImageBounceModel = require('demos.common.performance.image_bounce_model')
local UI = require('lib.ui')
local Env = require('lib.ui.utils.env')

local Image = UI.Image
local Texture = UI.Texture

return function(owner)
    return ScreenHelper.screen_wrapper(owner, function(stage)
        local root = stage.baseSceneLayer
        local texture = Texture.new({
            source = DemoAssets.load_image('assets/images/image.png'),
        })
        local initial_count = Env.parse_positive_integer('UI_PERF_IMAGE_COUNT', 3000)
        local spawn_batch = Env.parse_positive_integer('UI_PERF_IMAGE_SPAWN_BATCH', 100)
        local model = ImageBounceModel.new({
            item_width = 50,
            item_height = 50,
            create_item = function(x, y, velocity_x, velocity_y)
                local image = Image.new({
                    source = texture,
                    x = x,
                    y = y,
                    width = 50,
                    height = 50,
                    fit = 'contain',
                    sampling = 'linear',
                    decorative = true,
                })

                root:addChild(image)

                return {
                    node = image,
                    x = x,
                    y = y,
                    velocity_x = velocity_x,
                    velocity_y = velocity_y,
                }
            end,
            sync_item = function(item)
                item.node.x = item.x
                item.node.y = item.y
            end,
        })

        model:add(initial_count, stage.width, stage.height)

        return {
            title = 'Image',
            description = 'Image nodes bounce inside the screen bounds while sharing one Texture source. Click anywhere to spawn more with random directions.',
            sidebar = function()
                return {
                    'images: ' .. tostring(model:count()),
                    'spawn on click: +' .. tostring(spawn_batch),
                    'source: one shared Texture',
                }
            end,
            update = function(dt)
                model:update(dt, stage.width, stage.height)
            end,
            mousepressed = function(_, x, y, button)
                if button ~= 1 then
                    return false
                end

                model:add(spawn_batch, stage.width, stage.height, x - 25, y - 25)
                return true
            end,
        }
    end)
end
