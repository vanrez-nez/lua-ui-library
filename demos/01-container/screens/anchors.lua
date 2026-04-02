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
        'Shows anchor placement at direct and nested levels while parents resize.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            local elapsed = 0

            local single_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 260,
                height = 240,
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
                height = 72,
                anchorX = 0.5,
                anchorY = 0.5,
                pivotX = 0.5,
                pivotY = 0.5,
                rotation = 0,
            }, 'Single Child', DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22), DemoColors.roles.accent_cyan_line)
            helpers.set_markers(single_child, {
                { type = 'anchor', color = DemoColors.roles.accent_highlight },
                { type = 'pivot', color = DemoColors.roles.accent_red_line },
            })
            helpers.set_hint(single_child, function(node)
                return make_node_hint(helpers, node, {
                    { 'x', node.x },
                    { 'y', node.y },
                    { 'anchorX', node.anchorX },
                    { 'anchorY', node.anchorY },
                }, { x = true, y = true })
            end)

            local nested_parent = helpers.make_node(scope, root, {
                x = 0,
                y = 0,
                width = 292,
                height = 264,
            }, 'Nested', DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2), DemoColors.roles.accent_green_line)
            helpers.set_hint(nested_parent, function(node)
                local bounds = node:getLocalBounds()
                return make_node_hint(helpers, node, {
                    { 'w', bounds.width },
                    { 'h', bounds.height },
                }, { x = true, y = true, w = true, h = true })
            end)

            local nested_child = helpers.make_node(scope, nested_parent, {
                x = -28,
                y = -24,
                width = 132,
                height = 96,
                anchorX = 1,
                anchorY = 1,
            }, 'Nested Child', DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24), DemoColors.roles.accent_amber_line)
            helpers.set_markers(nested_child, {
                { type = 'anchor', color = DemoColors.roles.accent_highlight },
            })
            helpers.set_hint(nested_child, function(node)
                return make_node_hint(helpers, node, {
                    { 'x', node.x },
                    { 'y', node.y },
                    { 'anchorX', node.anchorX },
                    { 'anchorY', node.anchorY },
                }, { x = true, y = true })
            end)

            local nested_grandchild = helpers.make_node(scope, nested_child, {
                x = 0,
                y = 0,
                width = 58,
                height = 44,
                anchorX = 0.5,
                anchorY = 0.5,
                pivotX = 0.5,
                pivotY = 0.5,
                rotation = 0,
            }, 'Nested Grandchild', DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.24), DemoColors.roles.accent_red_line)
            helpers.set_markers(nested_grandchild, {
                { type = 'anchor', color = DemoColors.roles.accent_highlight },
                { type = 'pivot', color = DemoColors.roles.accent_red_line },
            })
            helpers.set_hint(nested_grandchild, function(node)
                return make_node_hint(helpers, node, {
                    { 'x', node.x },
                    { 'y', node.y },
                    { 'anchorX', node.anchorX },
                    { 'anchorY', node.anchorY },
                }, { x = true, y = true })
            end)

            return {
                title = 'Anchor Placement',
                description = 'Parents resize while anchorX and anchorY keep direct and nested children attached to parent-relative positions.',
                update = function(dt)
                    elapsed = elapsed + dt
                    local screen_width = love.graphics.getWidth()
                    local screen_height = love.graphics.getHeight()
                    local gap = 72

                    single_parent.width = helpers.round(260 + (math.sin(elapsed * 1.1) * 54))
                    single_parent.height = helpers.round(240 + (math.cos(elapsed * 0.9) * 44))
                    nested_parent.width = helpers.round(292 + (math.cos(elapsed * 0.95) * 58))
                    nested_parent.height = helpers.round(264 + (math.sin(elapsed * 1.05) * 46))

                    local total_width = single_parent.width + gap + nested_parent.width
                    local base_x = helpers.round((screen_width - total_width) * 0.5)

                    single_parent.x = base_x
                    nested_parent.x = base_x + single_parent.width + gap

                    single_parent.y = helpers.round((screen_height - single_parent.height) * 0.5)
                    nested_parent.y = helpers.round((screen_height - nested_parent.height) * 0.5)

                    single_child.rotation = math.sin(elapsed * 1.4) * 0.3
                    nested_grandchild.rotation = math.cos(elapsed * 1.7) * 0.42
                end,
            }
        end
    )
end
