local UI = require('lib.ui')

local Drawable = UI.Drawable
local Flow = UI.Flow

return function(owner, helpers)
    local description = 'Flow places children in reading order and wraps them into new rows when space runs out. Use it for fluid groups such as tags, chips, or filter collections.'

    return helpers.screen_wrapper(
        owner,
        function(stage)
            local root = stage.baseSceneLayer

            local parent = Flow.new({
                id = 'layout-flow-parent',
                width = 500,
                height = 350,
                padding = { 15, 15, 15, 15 },
                gap = 15,
                wrap = true,
                justify = 'start',
                direction = 'ltr',
            })

            local alpha = Drawable.new({
                id = 'layout-flow-alpha',
                width = 150,
                height = 50,
                padding = { 10, 15, 10, 15 },
                margin = 0,
                backgroundColor = { 117, 184, 255, 38 },
                borderColor = { 117, 184, 255 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            local beta = Drawable.new({
                id = 'layout-flow-beta',
                width = 200,
                height = 70,
                padding = 10,
                margin = { 0, 10, 0, 10 },
                backgroundColor = { 125, 235, 168, 51 },
                borderColor = { 125, 235, 168 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            local gamma = Drawable.new({
                id = 'layout-flow-gamma',
                width = 250,
                height = 60,
                padding = { 10, 15, 10, 15 },
                margin = 0,
                backgroundColor = { 255, 208, 117, 51 },
                borderColor = { 255, 208, 117 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            local delta = Drawable.new({
                id = 'layout-flow-delta',
                width = 100,
                height = 50,
                padding = { 10, 15, 10, 15 },
                margin = 0,
                backgroundColor = { 210, 165, 255, 51 },
                borderColor = { 210, 165, 255 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            parent:addChild(alpha)
            parent:addChild(beta)
            parent:addChild(gamma)
            parent:addChild(delta)
            root:addChild(parent)

            return {
                title = 'Layout: Flow',
                description = description,
            }
        end
    )
end
