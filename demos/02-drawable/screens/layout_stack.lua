local UI = require('lib.ui')

local Drawable = UI.Drawable
local Stack = UI.Stack

return function(owner, helpers)
    local description = 'Stack is a layout component that lets children sit in the same area while still offering basic margin and padding behavior. Use it when you want a loose, non-sequential layout that allows overlapping its children, for example a card with a floating badge on top.'

    return helpers.screen_wrapper(
        owner,
        function(scope, stage)
            local root = stage.baseSceneLayer

            local parent = Stack.new({
                id = 'layout-stack-parent',
                width = 360,
                height = 240,
                padding = 15,
            })

            local backdrop = Drawable.new({
                id = 'layout-stack-backdrop',
                width = 'fill',
                height = 'fill',
                backgroundColor = { 117, 184, 255, 38 },
                borderColor = { 117, 184, 255 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            local surface = Drawable.new({
                id = 'layout-stack-surface',
                width = 'fill',
                height = 'fill',
                margin = 30,
                padding = 15,
                backgroundColor = { 125, 235, 168, 51 },
                borderColor = { 125, 235, 168 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            local badge = Drawable.new({
                id = 'layout-stack-badge',
                x = 220,
                y = 20,
                width = 110,
                height = 45,
                padding = { 10, 15, 10, 15 },
                backgroundColor = { 255, 208, 117, 51 },
                borderColor = { 255, 208, 117 },
                borderWidth = 1,
                borderStyle = 'rough',
            })

            parent:addChild(backdrop)
            parent:addChild(surface)
            parent:addChild(badge)
            root:addChild(parent)

            return {
                title = 'Layout: Stack',
                description = description,
            }
        end
    )
end
