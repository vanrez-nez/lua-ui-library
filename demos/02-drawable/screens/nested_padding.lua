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
                width = 'content',
                height = 'content',
                padding = 10,
                backgroundColor = { 36, 59, 47, 46 },
                borderColor = { 78, 138, 99 },
                borderWidth = 1
            })

            local middle = Drawable.new({
                id = 'nested-spacing-middle',
                x = 0,
                y = 0,
                width = 'content',
                height = 'content',
                padding = 10,
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
                backgroundColor = { 31, 64, 68, 51 },
                borderColor = { 79, 164, 173 },
                borderWidth = 1
            })

            root:addChild(outer)
            outer:addChild(middle)
            middle:addChild(inner)

            return {
                title = 'Nested Padding',
                description = 'Use this screen to see how Drawable padding changes the content box immediately and, on content-sized ancestors, also changes measured border-box size through the nesting chain. Outer and middle grow from child border-box measurement, while the fixed-size inner leaf keeps the same outer size and only insets its own content.',
            }
        end
    )
end
