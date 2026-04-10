local DemoColors = require('demos.common.colors')

local CASES = {
    {
        label    = 'solid + smooth',
        pattern  = 'solid',
        style    = 'smooth',
        x        = 280,
        y        = 200,
        fill     = DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.15),
        line     = DemoColors.roles.accent_blue_line,
    },
    {
        label    = 'solid + rough',
        pattern  = 'solid',
        style    = 'rough',
        x        = 720,
        y        = 200,
        fill     = DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.15),
        line     = DemoColors.roles.accent_green_line,
    },
    {
        label    = 'dashed + smooth',
        pattern  = 'dashed',
        style    = 'smooth',
        dash_offset = 5,
        x        = 280,
        y        = 440,
        fill     = DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.15),
        line     = DemoColors.roles.accent_amber_line,
    },
    {
        label    = 'dashed + rough',
        pattern  = 'dashed',
        style    = 'rough',
        dash_offset = -5,
        x        = 720,
        y        = 440,
        fill     = DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.15),
        line     = DemoColors.roles.accent_violet_line,
    },
}

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(stage)
            local root = stage.baseSceneLayer

            for i = 1, #CASES do
                local case = CASES[i]
                local props = {
                    x            = case.x,
                    y            = case.y,
                    width        = 220,
                    height       = 160,
                    padding      = 16,
                    cornerRadius = 8,
                    borderWidth  = 2,
                    borderStyle  = case.style,
                    borderPattern = case.pattern,
                }
                if case.pattern == 'dashed' then
                    props.borderDashLength = 8
                    props.borderGapLength  = 6
                    props.borderDashOffset = case.dash_offset or 0
                end
                local node = helpers.make_node(root, props, case.label, case.fill, case.line)
                helpers.set_hint(node, function(current)
                    local badges = {
                        helpers.badge('borderPattern', current.borderPattern or 'solid'),
                        helpers.badge('borderStyle',   current.borderStyle   or 'smooth'),
                        helpers.badge('borderWidth',   helpers.format_scalar(current.borderWidthTop or 0)),
                    }
                    if current.borderPattern == 'dashed' then
                        badges[#badges + 1] = helpers.badge('borderDashLength', helpers.format_scalar(current.borderDashLength or 8))
                        badges[#badges + 1] = helpers.badge('borderGapLength',  helpers.format_scalar(current.borderGapLength  or 6))
                        badges[#badges + 1] = helpers.badge('borderDashOffset', helpers.format_scalar(current.borderDashOffset or 0))
                    end
                    return {
                        {
                            label  = 'border',
                            badges = badges,
                        },
                    }
                end)
            end

            return {
                title       = 'Borders',
                description = 'Each node demonstrates one combination. Top row: solid borders. Bottom row: dashed borders. Left column: smooth (antialiased). Right column: rough (aliased).',
            }
        end
    )
end
