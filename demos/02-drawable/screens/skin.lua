local DemoColors = require('demos.common.colors')

local CASES = {
    {
        label = 'base skin',
        x = 170,
        skin = { id = 'panel.base', variant = 'default', radius = 10 },
    },
    {
        label = 'hover skin',
        x = 480,
        skin = { id = 'panel.hover', variant = 'hover', radius = 14 },
    },
    {
        label = 'danger skin',
        x = 790,
        skin = { id = 'panel.danger', variant = 'danger', radius = 14 },
    },
}

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Keeps skin resolution on the Drawable surface visible as stored data without turning the demo into a theme-system showcase.',
        function(scope, stage)
            local root = stage.baseSceneLayer

            for index = 1, #CASES do
                local case = CASES[index]
                local node = helpers.make_node(scope, root, {
                    x = case.x,
                    y = 220,
                    width = 220,
                    height = 160,
                    padding = 14,
                    skin = case.skin,
                }, case.label, DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.18), DemoColors.roles.accent_red_line)
                helpers.show_content(node, 88, 44)
                helpers.set_hint(node, {
                    {
                        label = 'props',
                        badges = {
                            helpers.badge('skin.id', case.skin.id),
                            helpers.badge('skin.variant', case.skin.variant),
                            helpers.badge('skin.radius', case.skin.radius),
                        },
                    },
                })
            end

            return {
                title = 'Skin',
                description = 'Skin stays on the stable Drawable surface, but this screen avoids implying token resolution or part-specific theming behavior that belongs to later systems.',
            }
        end
    )
end
