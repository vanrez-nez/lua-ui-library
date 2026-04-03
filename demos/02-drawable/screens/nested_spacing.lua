local UI = require('lib.ui')

local Drawable = UI.Drawable

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(scope, stage)
            local root = stage.baseSceneLayer

            local outer = Drawable.new({
                id = 'nested-spacing-outer',
                x = 0,
                y = 0,
                width = 150,
                height = 150,
                padding = 10,
                margin = 0,
                backgroundColor = { 36, 59, 47, 46 },
                borderColor = { 78, 138, 99 },
                borderWidth = 1
            })

            local middle = Drawable.new({
                id = 'nested-spacing-middle',
                x = 0,
                y = 0,
                width = 100,
                height = 100,
                padding = 10,
                margin = 10,
                backgroundColor = { 52, 40, 74, 46 },
                borderColor = { 131, 98, 184 },
                borderWidth = 1
            })

            local inner = Drawable.new({
                id = 'nested-spacing-inner',
                x = 0,
                y = 0,
                width = 50,
                height = 50,
                padding = 5,
                margin = 5,
                backgroundColor = { 31, 64, 68, 51 },
                borderColor = { 79, 164, 173 },
                borderWidth = 1
            })

            root:addChild(outer)
            outer:addChild(middle)
            middle:addChild(inner)

            return {
                title = 'Nested Spacing',
                description = 'This screen is intentionally just one retained Drawable nesting chain: outer contains middle, and middle contains inner.',
            }
        end
    )
end
