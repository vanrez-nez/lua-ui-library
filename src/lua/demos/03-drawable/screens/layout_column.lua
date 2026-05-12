local UI = require('lib.ui')

local Column = UI.Column
local Drawable = UI.Drawable

return function(owner, helpers)
    local description = 'Column is a layout component that arranges children vertically with gap, justify, and cross-axis alignment. Use it for stacked panels such as cards, menus, forms, or content sections.'

    return helpers.screen_wrapper(
        owner,
        function(stage)
            local root = stage.baseSceneLayer

            local parent = Column.new({
                id = 'layout-column-parent',
                width = 300,
                height = 500,
                padding = { 15, 15, 15, 15 },
                gap = 15,
                justify = 'start',
                align = 'center',
            })

            local header = Drawable.new({
                id = 'layout-column-header',
                width = 240,
                height = 60,
                padding = 10,
                margin = 0,
                backgroundColor = { 117, 184, 255, 38 },
                borderColor = { 117, 184, 255 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            local body = Drawable.new({
                id = 'layout-column-body',
                width = 240,
                height = 150,
                padding = 10,
                margin = { 10, 0, 10, 0 },
                backgroundColor = { 125, 235, 168, 51 },
                borderColor = { 125, 235, 168 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            local footer = Drawable.new({
                id = 'layout-column-footer',
                width = 180,
                height = 50,
                padding = { 10, 15, 10, 15 },
                margin = 0,
                backgroundColor = { 255, 208, 117, 51 },
                borderColor = { 255, 208, 117 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            parent:addChild(header)
            parent:addChild(body)
            parent:addChild(footer)
            root:addChild(parent)

            return {
                title = 'Layout: Column',
                description = description,
            }
        end
    )
end
