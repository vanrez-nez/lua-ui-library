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
        'Shows scaleX and scaleY at direct and nested levels.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            local elapsed = 0

            local single_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 280,
                height = 260,
            }, 'Single', DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.2), DemoColors.roles.accent_blue_line)
            helpers.set_hint(single_parent, function(node)
                local bounds = node:getLocalBounds()
                return make_node_hint(helpers, node, {
                    { 'w', bounds.width },
                    { 'h', bounds.height },
                }, { x = true, y = true, w = true, h = true })
            end)

            local single_child = helpers.make_node(scope, single_parent, {
                x = 0,
                y = 0,
                width = 96,
                height = 80,
                pivotX = 0.5,
                pivotY = 0.5,
                scaleX = 1,
                scaleY = 1,
            }, 'Single Child', DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22), DemoColors.roles.accent_cyan_line)
            helpers.set_hint(single_child, function(node)
                return make_node_hint(helpers, node, {
                    { 'scaleX', node.scaleX },
                    { 'scaleY', node.scaleY },
                    { 'pivotX', node.pivotX },
                    { 'pivotY', node.pivotY },
                }, { w = true, h = true })
            end)

            local nested_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 320,
                height = 280,
            }, 'Nested', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2), DemoColors.roles.accent_green_line)
            helpers.set_hint(nested_parent, function(node)
                local bounds = node:getLocalBounds()
                return make_node_hint(helpers, node, {
                    { 'w', bounds.width },
                    { 'h', bounds.height },
                }, { x = true, y = true, w = true, h = true })
            end)

            local nested_child = helpers.make_node(scope, nested_parent, {
                x = 0,
                y = 0,
                width = 136,
                height = 98,
                pivotX = 0.5,
                pivotY = 0.5,
                scaleX = 1.2,
                scaleY = 0.85,
            }, 'Nested Child', DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24), DemoColors.roles.accent_amber_line)
            helpers.set_hint(nested_child, function(node)
                return make_node_hint(helpers, node, {
                    { 'scaleX', node.scaleX },
                    { 'scaleY', node.scaleY },
                }, { w = true, h = true })
            end)

            local nested_grandchild = helpers.make_node(scope, nested_child, {
                x = 0,
                y = 0,
                width = 72,
                height = 54,
                pivotX = 0.5,
                pivotY = 0.5,
                scaleX = 0.9,
                scaleY = 1.35,
            }, 'Nested Grandchild', DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.24), DemoColors.roles.accent_red_line)
            helpers.set_hint(nested_grandchild, function(node)
                return make_node_hint(helpers, node, {
                    { 'scaleX', node.scaleX },
                    { 'scaleY', node.scaleY },
                }, { w = true, h = true })
            end)

            return {
                title = 'Scaling',
                description = 'scaleX and scaleY stretch direct and nested nodes while the cases translate to keep the transforms easy to read.',
                update = function(dt)
                    elapsed = elapsed + dt
                    local screen_width = love.graphics.getWidth()
                    local screen_height = love.graphics.getHeight()
                    local gap = 84
                    local total_width = single_parent.width + gap + nested_parent.width
                    local base_x = helpers.round((screen_width - total_width) * 0.5)
                    local center_y = helpers.round((screen_height - math.max(single_parent.height, nested_parent.height)) * 0.5)

                    single_parent.x = base_x
                    single_parent.y = center_y + helpers.round(math.sin(elapsed * 0.9) * 18)

                    nested_parent.x = base_x + single_parent.width + gap
                    nested_parent.y = center_y + helpers.round(math.cos(elapsed * 1.05) * 18)

                    single_child.scaleX = 0.72 + ((math.sin(elapsed * 1.55) + 1) * 0.38)
                    single_child.scaleY = 0.62 + ((math.cos(elapsed * 1.2) + 1) * 0.34)

                    nested_child.scaleX = 1.08 + (math.sin(elapsed * 1.05) * 0.26)
                    nested_child.scaleY = 0.82 + (math.cos(elapsed * 1.25) * 0.22)

                    nested_grandchild.scaleX = 0.72 + (math.cos(elapsed * 1.8) * 0.18)
                    nested_grandchild.scaleY = 1.18 + (math.sin(elapsed * 1.45) * 0.32)

                    local single_parent_bounds = single_parent:getLocalBounds()
                    local nested_parent_bounds = nested_parent:getLocalBounds()
                    local nested_child_bounds = nested_child:getLocalBounds()
                    local single_child_bounds = single_child:getLocalBounds()
                    local nested_grandchild_bounds = nested_grandchild:getLocalBounds()

                    single_child.x = helpers.round((single_parent_bounds.width - single_child_bounds.width) * 0.5)
                    single_child.y = helpers.round((single_parent_bounds.height - single_child_bounds.height) * 0.5)

                    nested_child.x = helpers.round((nested_parent_bounds.width - nested_child_bounds.width) * 0.5)
                    nested_child.y = helpers.round((nested_parent_bounds.height - nested_child_bounds.height) * 0.5)

                    nested_grandchild.x = helpers.round((nested_child_bounds.width - nested_grandchild_bounds.width) * 0.5)
                    nested_grandchild.y = helpers.round((nested_child_bounds.height - nested_grandchild_bounds.height) * 0.5)
                end,
            }
        end
    )
end
