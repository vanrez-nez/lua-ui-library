local DemoColors = require('demos.common.colors')

local CASES = {
    { label = 'Full', value = 1, x = 170 },
    { label = 'Soft', value = 0.5, x = 480 },
    { label = 'Hidden', value = 0, x = 790 },
}

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Shows how Drawable.opacity participates in retained subtree compositing while keeping the content box inspectable.',
        function(scope, stage)
            local root = stage.baseSceneLayer

            for index = 1, #CASES do
                local case = CASES[index]
                local node = helpers.make_node(scope, root, {
                    x = case.x,
                    y = 220,
                    width = 220,
                    height = 160,
                    padding = 10,
                    opacity = case.value,
                }, case.label, DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.2), DemoColors.roles.accent_cyan_line)
                helpers.show_content(node, 88, 44)
                helpers.set_hint(node, function(current)
                    return {
                        {
                            label = 'opacity',
                            badges = {
                                helpers.badge('opacity', helpers.format_scalar(current.opacity)),
                            },
                        },
                        {
                            label = 'rect.content',
                            badges = {
                                helpers.badge('content', helpers.format_rect(current:getContentRect())),
                            },
                        },
                    }
                end)
            end

            return {
                title = 'Opacity',
                description = 'Inspect the configured opacity values and compare them with the dedicated render-effects screen, where the same retained subtree compositing is made visually obvious.',
            }
        end
    )
end
