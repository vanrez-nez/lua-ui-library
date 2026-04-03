local DemoColors = require('demos.common.colors')

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Uses a demo-local harness trigger to inspect Drawable motion descriptors because bare Drawable does not own a built-in interaction phase.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            local elapsed = 0
            local toggle = false

            local adapter_log = {
                'waiting for first request',
            }

            local function make_descriptor(target_value)
                return {
                    target = 'root',
                    properties = {
                        opacity = {
                            from = 0,
                            to = target_value,
                            easing = 'linear',
                        },
                    },
                    onStep = function(info)
                        adapter_log = {
                            'phase       ' .. tostring(info.phase),
                            'target      ' .. tostring(info.target),
                            'progress    ' .. tostring(info.progress),
                            'nextValue   ' .. tostring(info.nextValue),
                        }
                    end,
                }
            end

            local left = helpers.make_node(scope, root, {
                x = 250,
                y = 220,
                width = 280,
                height = 180,
                padding = 15,
                motion = {
                    reflow = make_descriptor(0.25),
                },
            }, 'Low Fade', DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.2), DemoColors.roles.accent_blue_line)
            helpers.show_content(left, 96, 44)
            helpers.show_motion_bar(left)

            local right = helpers.make_node(scope, root, {
                x = 700,
                y = 220,
                width = 280,
                height = 180,
                padding = 15,
                motion = {
                    reflow = make_descriptor(0.85),
                },
            }, 'High Fade', DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.2), DemoColors.roles.accent_cyan_line)
            helpers.show_content(right, 96, 44)
            helpers.show_motion_bar(right)

            for _, node in ipairs({ left, right }) do
                helpers.set_hint(node, function(current)
                    local last = rawget(current, '_motion_last_request')
                    local completed = last and last.completed and last.completed[1] or nil
                    return {
                        {
                            label = 'motion',
                            badges = {
                                helpers.badge('phase', last and last.phase or 'none'),
                                helpers.badge('target', completed and completed.target or 'none'),
                                helpers.badge('opacity', helpers.format_scalar(current.opacity)),
                                helpers.badge('motion.opacity', helpers.format_scalar(current:_get_motion_value('root', 'opacity') or 0)),
                            },
                        },
                    }
                end)
            end

            local function trigger_request(node)
                helpers.request_motion(node, 'reflow', {
                    defaultTarget = 'root',
                    previousValue = toggle and 'high' or 'low',
                    nextValue = toggle and 'low' or 'high',
                })
            end

            return {
                title = 'Motion',
                description = 'Green bars show the harness-written motion opacity state. Requests are driven locally through the shared motion runtime for inspection.',
                update = function(dt)
                    elapsed = elapsed + dt
                    if elapsed >= 1.2 then
                        elapsed = 0
                        toggle = not toggle
                        trigger_request(toggle and left or right)
                    end
                end,
                sidebar = function()
                    return {
                        adapter_log[1],
                        adapter_log[2] or '',
                        adapter_log[3] or '',
                        adapter_log[4] or '',
                    }
                end,
            }
        end
    )
end
