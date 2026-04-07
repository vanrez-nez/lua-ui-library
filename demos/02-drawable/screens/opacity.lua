local UI = require('lib.ui')

local Drawable = UI.Drawable

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(scope, stage)
            local root = stage.baseSceneLayer

            local frame = Drawable.new({
                id = 'opacity-frame',
                width = 320,
                height = 220,
                backgroundColor = nil,
                borderColor = { 184, 191, 207 },
                borderWidth = 1,
                borderDashLength = 8,
                borderStyle = 'rough',
                borderPattern = 'dashed',
            })

            local opacity_subtree = Drawable.new({
                id = 'opacity-subtree',
                width = 260,
                height = 180,
                opacity = 0.5,
                visible = true,
            })

            local left_circle = Drawable.new({
                id = 'opacity-left-circle',
                x = 20,
                y = 40,
                width = 110,
                height = 110,
                backgroundColor = { 107, 235, 250, 204 },
                borderColor = { 107, 235, 250 },
                borderWidth = 1,
                cornerRadius = 999,
            })

            local right_circle = Drawable.new({
                id = 'opacity-right-circle',
                x = 90,
                y = 40,
                width = 110,
                height = 110,
                backgroundColor = { 195, 143, 250, 204 },
                borderColor = { 195, 143, 250 },
                borderWidth = 1,
                cornerRadius = 999,
            })

            opacity_subtree:addChild(left_circle)
            opacity_subtree:addChild(right_circle)
            root:addChild(frame)
            root:addChild(opacity_subtree)

            return {
                title = 'Opacity',
                description = 'Shows that Drawable.opacity fades a retained subtree as one composited unit, while visible = false suppresses rendering without detaching the subtree from retained state.',
            }
        end
    )
end
