local DemoColors = require('demos.common.colors')

local function format_number(value)
    if value == nil then
        return 'nil'
    end

    if math.abs(value - math.floor(value)) < 0.001 then
        return tostring(math.floor(value + 0.5))
    end

    return string.format('%.2f', value)
end

local function make_row(helpers, label, badges)
    local row = {
        label = label,
        badges = {},
    }

    for index = 1, #badges do
        local badge = badges[index]
        row.badges[#row.badges + 1] = helpers.badge(badge[1], format_number(badge[2]))
    end

    return row
end

local function make_node_hint(helpers, node, badges, world_keys)
    local rows = {
        {
            label = 'node',
            badges = {
                helpers.badge(nil, rawget(node, '_demo_label')),
            },
        },
        make_row(helpers, 'props', badges),
    }

    if world_keys ~= nil then
        local world = node:getWorldBounds()
        local world_badges = {}

        if world_keys.x then
            world_badges[#world_badges + 1] = { 'x', world.x }
        end

        if world_keys.y then
            world_badges[#world_badges + 1] = { 'y', world.y }
        end

        if world_keys.w then
            world_badges[#world_badges + 1] = { 'w', world.width }
        end

        if world_keys.h then
            world_badges[#world_badges + 1] = { 'h', world.height }
        end

        rows[#rows + 1] = make_row(helpers, 'world', world_badges)
    end

    return rows
end

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Shows pivot-driven rotation on direct and nested nodes.',
        function(scope, stage)
            local root = stage.baseSceneLayer

            local single_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 280,
                height = 280,
            }, 'Single', DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.2), DemoColors.roles.accent_blue_line)
            helpers.set_hint(single_parent, function(node)
                local bounds = node:getLocalBounds()
                return make_node_hint(helpers, node, {
                    { 'w', bounds.width },
                    { 'h', bounds.height },
                }, { x = true, y = true, w = true, h = true })
            end)

            local single_child = helpers.make_node(scope, single_parent, {
                x = 82,
                y = 96,
                width = 116,
                height = 82,
                pivotX = 0.5,
                pivotY = 0.5,
                rotation = 0,
            }, 'Single Child', DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22), DemoColors.roles.accent_cyan_line)
            helpers.set_markers(single_child, {
                { type = 'pivot', color = DemoColors.roles.accent_red_line },
            })
            helpers.set_hint(single_child, function(node)
                return make_node_hint(helpers, node, {
                    { 'pivotX', node.pivotX },
                    { 'pivotY', node.pivotY },
                    { 'rotation', node.rotation },
                }, { x = true, y = true, w = true, h = true })
            end)

            local nested_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 320,
                height = 300,
            }, 'Nested', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2), DemoColors.roles.accent_green_line)
            helpers.set_hint(nested_parent, function(node)
                local bounds = node:getLocalBounds()
                return make_node_hint(helpers, node, {
                    { 'w', bounds.width },
                    { 'h', bounds.height },
                }, { x = true, y = true, w = true, h = true })
            end)

            local nested_child = helpers.make_node(scope, nested_parent, {
                x = 48,
                y = 54,
                width = 144,
                height = 100,
                pivotX = 0,
                pivotY = 0,
                rotation = 0,
            }, 'Nested Child', DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24), DemoColors.roles.accent_amber_line)
            helpers.set_markers(nested_child, {
                { type = 'pivot', color = DemoColors.roles.accent_red_line },
            })
            helpers.set_hint(nested_child, function(node)
                return make_node_hint(helpers, node, {
                    { 'pivotX', node.pivotX },
                    { 'pivotY', node.pivotY },
                    { 'rotation', node.rotation },
                }, { x = true, y = true, w = true, h = true })
            end)

            local nested_grandchild = helpers.make_node(scope, nested_child, {
                x = 88,
                y = 58,
                width = 84,
                height = 56,
                pivotX = 1,
                pivotY = 1,
                rotation = 0,
            }, 'Nested Grandchild', DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.24), DemoColors.roles.accent_red_line)
            helpers.set_markers(nested_grandchild, {
                { type = 'pivot', color = DemoColors.roles.accent_red_line },
            })
            helpers.set_hint(nested_grandchild, function(node)
                return make_node_hint(helpers, node, {
                    { 'pivotX', node.pivotX },
                    { 'pivotY', node.pivotY },
                    { 'rotation', node.rotation },
                }, { x = true, y = true, w = true, h = true })
            end)

            return {
                title = 'Pivot Rotation',
                description = 'Rotation stays tied to pivotX and pivotY, first on a single node and then through a nested transform chain.',
                update = function()
                    local time = love.timer.getTime()
                    local screen_width = love.graphics.getWidth()
                    local screen_height = love.graphics.getHeight()
                    local gap = 80
                    local total_width = single_parent.width + gap + nested_parent.width
                    local base_x = helpers.round((screen_width - total_width) * 0.5)

                    single_parent.x = base_x
                    nested_parent.x = base_x + single_parent.width + gap
                    single_parent.y = helpers.round((screen_height - single_parent.height) * 0.5)
                    nested_parent.y = helpers.round((screen_height - nested_parent.height) * 0.5)

                    single_child.rotation = math.sin(time * 1.5) * 1.1
                    nested_child.rotation = math.cos(time * 1.1) * 0.82
                    nested_grandchild.rotation = -math.sin(time * 2.1) * 1.35
                end,
            }
        end
    )
end
