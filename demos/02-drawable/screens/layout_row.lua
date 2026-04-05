local UI = require('lib.ui')

local Drawable = UI.Drawable
local Row = UI.Row

return function(owner, helpers)
    local description = 'Row is a layout component that arranges children horizontally with gap, justify, and cross-axis alignment. Use it for horizontal groups such as toolbars, action bars, or compact status strips.'

    return helpers.screen_wrapper(
        owner,
        description,
        function(scope, stage)
            local root = stage.baseSceneLayer

            local parent = Row.new({
                id = 'layout-row-parent',
                width = 840,
                height = 110,
                padding = { 15, 15, 15, 15 },
                gap = 15,
                justify = 'start',
                align = 'center',
            })

            local leading = Drawable.new({
                id = 'layout-row-leading',
                width = 130,
                height = 65,
                padding = 8,
                margin = 0,
                backgroundColor = { 117, 184, 255, 38 },
                borderColor = { 117, 184, 255 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            local content = Drawable.new({
                id = 'layout-row-content',
                width = 360,
                height = 70,
                padding = 10,
                margin = { 0, 10, 0, 10 },
                backgroundColor = { 125, 235, 168, 51 },
                borderColor = { 125, 235, 168 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            local action = Drawable.new({
                id = 'layout-row-action',
                width = 180,
                height = 50,
                padding = { 10, 15, 10, 15 },
                margin = 0,
                backgroundColor = { 255, 208, 117, 51 },
                borderColor = { 255, 208, 117 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            parent:addChild(leading)
            parent:addChild(content)
            parent:addChild(action)
            root:addChild(parent)

            return {
                title = 'Layout: Row',
                description = description,
            }
        end
    )
end
