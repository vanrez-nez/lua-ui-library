local UI = require('lib.ui')
local Setup = require('demos.02-drawable.screens.nested_spacing_setup')

local Drawable = UI.Drawable

local BOX_SIZES = {
    outer = 150,
    middle = 100,
    inner = 50,
}

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'This advanced screen uses one nested Drawable stack with three levels. Use the top navigator to choose Inner, Middle, or Outer. Each child is positioned from its parent using the parent\'s real `resolveContentRect()` result. Padding changes the parent content box and therefore shifts the next child. Margin remains inspectable external input.',
        function(scope, stage)
            local root = stage.baseSceneLayer

            local outer = Drawable.new({
                x = 0,
                y = 0,
                width = BOX_SIZES.outer,
                height = BOX_SIZES.outer,
                padding = 10,
                margin = 0,
                alignX = 'center',
                alignY = 'center',
            })

            local middle = Drawable.new({
                x = 0,
                y = 0,
                width = BOX_SIZES.middle,
                height = BOX_SIZES.middle,
                padding = 10,
                margin = 10,
                alignX = 'center',
                alignY = 'center',
            })

            local inner = Drawable.new({
                x = 0,
                y = 0,
                width = BOX_SIZES.inner,
                height = BOX_SIZES.inner,
                padding = 5,
                margin = 5,
                alignX = 'center',
                alignY = 'center',
            })

            root:addChild(outer)
            outer:addChild(middle)
            middle:addChild(inner)

            local nodes = { outer, middle, inner }
            local setup = Setup.install({
                scope = scope,
                owner = owner,
                helpers = helpers,
                nodes = nodes,
            })

            local function layout_scene()
                local screen_width = love.graphics.getWidth()
                local screen_height = love.graphics.getHeight()
                local content_top = owner.header_height + 52
                local content_bottom = screen_height - owner.footer_height - 24
                local content_height = math.max(1, content_bottom - content_top)

                outer.x = math.floor((screen_width - BOX_SIZES.outer) * 0.5 + 0.5)
                outer.y = math.floor(content_top + ((content_height - BOX_SIZES.outer) * 0.5) + 0.5)

                local middle_rect = outer:resolveContentRect(BOX_SIZES.middle, BOX_SIZES.middle)
                middle.x = middle_rect.x
                middle.y = middle_rect.y
                middle.width = BOX_SIZES.middle
                middle.height = BOX_SIZES.middle

                local inner_rect = middle:resolveContentRect(BOX_SIZES.inner, BOX_SIZES.inner)
                inner.x = inner_rect.x
                inner.y = inner_rect.y
                inner.width = BOX_SIZES.inner
                inner.height = BOX_SIZES.inner
            end

            return {
                title = 'Nested Spacing',
                description = 'Use the top navigator to choose Inner, Middle, or Outer. Each nested box keeps its own fixed size, and the next child is positioned from the parent\'s real `resolveContentRect()` result. Padding changes the parent content box and therefore shifts the next child. Margin is still real and inspectable, but it remains external input and does not lay out descendants.',
                mousepressed = function(_, x, y, button)
                    return setup.mousepressed(x, y, button)
                end,
                update = function()
                    layout_scene()
                    setup.update()
                end,
                draw_overlay = function(graphics)
                    setup.draw_overlay(graphics)
                end,
            }
        end
    )
end
