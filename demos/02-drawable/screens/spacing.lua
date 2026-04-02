local DemoColors = require('demos.common.colors')

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Separates internal padding from external margin without implying sibling layout behavior.',
        function(scope, stage)
            local root = stage.baseSceneLayer

            local padded_a = helpers.make_node(scope, root, {
                x = 120,
                y = 180,
                width = 220,
                height = 170,
                padding = 8,
            }, 'padding 8', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2), DemoColors.roles.accent_green_line)
            helpers.show_content(padded_a, 90, 42)

            local padded_b = helpers.make_node(scope, root, {
                x = 390,
                y = 180,
                width = 220,
                height = 170,
                padding = { 12, 28, 36, 20 },
            }, 'padding 12/28/36/20', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2), DemoColors.roles.accent_green_line)
            helpers.show_content(padded_b, 90, 42)

            local margin_a = helpers.make_node(scope, root, {
                x = 760,
                y = 196,
                width = 190,
                height = 138,
                margin = 18,
                padding = 12,
            }, 'margin 18', DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.2), DemoColors.roles.accent_violet_line)
            helpers.show_margin(margin_a)
            helpers.show_content(margin_a, 76, 36)

            local margin_b = helpers.make_node(scope, root, {
                x = 1030,
                y = 204,
                width = 190,
                height = 138,
                margin = { 10, 32, 22, 14 },
                padding = 12,
            }, 'margin 10/32/22/14', DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.2), DemoColors.roles.accent_violet_line)
            helpers.show_margin(margin_b)
            helpers.show_content(margin_b, 76, 36)

            helpers.set_hint(padded_a, function(node)
                return {
                    {
                        label = 'props',
                        badges = {
                            helpers.badge('padding', helpers.format_insets(node.padding)),
                        },
                    },
                    {
                        label = 'rect',
                        badges = {
                            helpers.badge('content', helpers.format_rect(node:getContentRect())),
                        },
                    },
                }
            end)

            helpers.set_hint(padded_b, function(node)
                return {
                    {
                        label = 'props',
                        badges = {
                            helpers.badge('padding', helpers.format_insets(node.padding)),
                        },
                    },
                    {
                        label = 'rect',
                        badges = {
                            helpers.badge('content', helpers.format_rect(node:getContentRect())),
                        },
                    },
                }
            end)

            for _, node in ipairs({ margin_a, margin_b }) do
                helpers.set_hint(node, function(current)
                    return {
                        {
                            label = 'props',
                            badges = {
                                helpers.badge('margin', helpers.format_insets(current.margin)),
                            },
                        },
                        {
                            label = 'rect',
                            badges = {
                                helpers.badge('bounds', helpers.format_rect(current:getLocalBounds())),
                            },
                        },
                        {
                            label = 'rect',
                            badges = {
                                helpers.badge('content', helpers.format_rect(current:getContentRect())),
                            },
                        },
                    }
                end)
            end

            return {
                title = 'Padding / Margin',
                description = 'Padding changes the drawable content box. Gold outlines show the external margin guide; the node bounds themselves do not grow.',
            }
        end
    )
end
