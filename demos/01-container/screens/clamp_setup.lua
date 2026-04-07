local DemoColors = require('demos.common.colors')

local Setup = {}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('clamp_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function clamp_hint(helpers, mode)
    return function(current)
        local bounds = current:getLocalBounds()
        local rows = {}

        if mode == 'width' then
            rows[#rows + 1] = {
                label = 'size.props',
                badges = {
                    helpers.badge('width', tostring(current.width)),
                },
            }
            rows[#rows + 1] = {
                label = 'size.resolved',
                badges = {
                    helpers.badge('w', helpers.round(bounds.width)),
                },
            }
            rows[#rows + 1] = {
                label = 'clamp.width',
                badges = {
                    helpers.badge('minW', tostring(current.minWidth)),
                    helpers.badge('maxW', tostring(current.maxWidth)),
                },
            }
        elseif mode == 'height' then
            rows[#rows + 1] = {
                label = 'size.props',
                badges = {
                    helpers.badge('height', tostring(current.height)),
                },
            }
            rows[#rows + 1] = {
                label = 'size.resolved',
                badges = {
                    helpers.badge('h', helpers.round(bounds.height)),
                },
            }
            rows[#rows + 1] = {
                label = 'clamp.height',
                badges = {
                    helpers.badge('minH', tostring(current.minHeight)),
                    helpers.badge('maxH', tostring(current.maxHeight)),
                },
            }
        elseif mode == 'both' then
            rows[#rows + 1] = {
                label = 'size.props',
                badges = {
                    helpers.badge('width', tostring(current.width)),
                    helpers.badge('height', tostring(current.height)),
                },
            }
            rows[#rows + 1] = {
                label = 'size.resolved',
                badges = {
                    helpers.badge('w', helpers.round(bounds.width)),
                    helpers.badge('h', helpers.round(bounds.height)),
                },
            }
            rows[#rows + 1] = {
                label = 'clamp.width',
                badges = {
                    helpers.badge('minW', tostring(current.minWidth)),
                    helpers.badge('maxW', tostring(current.maxWidth)),
                },
            }
            rows[#rows + 1] = {
                label = 'clamp.height',
                badges = {
                    helpers.badge('minH', tostring(current.minHeight)),
                    helpers.badge('maxH', tostring(current.maxHeight)),
                },
            }
        else
            rows[#rows + 1] = {
                label = 'size.resolved',
                badges = {
                    helpers.badge('w', helpers.round(bounds.width)),
                    helpers.badge('h', helpers.round(bounds.height)),
                },
            }
        end

        return rows
    end
end

local function apply_box(helpers, node, label, fill_color, line_color, mode)
    helpers.mark_box(node, label, fill_color, line_color)
    helpers.set_hint(node, clamp_hint(helpers, mode))
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local stage = args.stage
    local elapsed = 0
    local parent_gap = 60

    local width_parent = find_required(root, 'clamp-width-parent')
    local width_case = find_required(root, 'clamp-width-case')
    local height_parent = find_required(root, 'clamp-height-parent')
    local height_case = find_required(root, 'clamp-height-case')
    local both_parent = find_required(root, 'clamp-both-parent')
    local both_case = find_required(root, 'clamp-both-case')

    apply_box(
        helpers,
        width_parent,
        'width parent',
        DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.22),
        DemoColors.roles.accent_violet_line,
        'parent'
    )
    apply_box(
        helpers,
        width_case,
        'width clamp',
        DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24),
        DemoColors.roles.accent_blue_line,
        'width'
    )
    apply_box(
        helpers,
        height_parent,
        'height parent',
        DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.22),
        DemoColors.roles.accent_violet_line,
        'parent'
    )
    apply_box(
        helpers,
        height_case,
        'height clamp',
        DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22),
        DemoColors.roles.accent_green_line,
        'height'
    )
    apply_box(
        helpers,
        both_parent,
        'both parent',
        DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.22),
        DemoColors.roles.accent_violet_line,
        'parent'
    )
    apply_box(
        helpers,
        both_case,
        'both clamp',
        DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24),
        DemoColors.roles.accent_amber_line,
        'both'
    )

    rawset(stage, '_demo_screen_hooks', {
        update = function(dt)
            elapsed = elapsed + dt

            width_parent.width = helpers.round(200 + (math.sin(elapsed * 1.35) * 70))
            height_parent.height = helpers.round(120 + (math.cos(elapsed * 1.1) * 40))
            both_parent.width = helpers.round(250 + (math.sin(elapsed * 1.2) * 70))
            both_parent.height = helpers.round(130 + (math.cos(elapsed * 1.45) * 30))

            local screen_width = love.graphics.getWidth()
            local screen_height = love.graphics.getHeight()
            local total_height = width_parent.height + height_parent.height + both_parent.height + (parent_gap * 2)
            local top = helpers.round((screen_height - total_height) * 0.5)

            width_parent.x = helpers.round((screen_width - width_parent.width) * 0.5)
            width_parent.y = top

            height_parent.x = helpers.round((screen_width - height_parent.width) * 0.5)
            height_parent.y = width_parent.y + width_parent.height + parent_gap

            both_parent.x = helpers.round((screen_width - both_parent.width) * 0.5)
            both_parent.y = height_parent.y + height_parent.height + parent_gap
        end,
    })
end

return Setup
