local DemoColors = require('demos.common.colors')

local CASES = {
    {
        column = 'padding',
        label = 'Top',
        padding = { 20, 0, 0, 0 },
        margin = 0,
        show_padding = true,
        show_margin = false,
        fill = DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2),
        line = DemoColors.roles.accent_green_line,
    },
    {
        column = 'padding',
        label = 'Right',
        padding = { 0, 20, 0, 0 },
        margin = 0,
        show_padding = true,
        show_margin = false,
        fill = DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2),
        line = DemoColors.roles.accent_green_line,
    },
    {
        column = 'padding',
        label = 'Bottom',
        padding = { 0, 0, 20, 0 },
        margin = 0,
        show_padding = true,
        show_margin = false,
        fill = DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2),
        line = DemoColors.roles.accent_green_line,
    },
    {
        column = 'padding',
        label = 'Left',
        padding = { 0, 0, 0, 20 },
        margin = 0,
        show_padding = true,
        show_margin = false,
        fill = DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2),
        line = DemoColors.roles.accent_green_line,
    },
    {
        column = 'padding',
        label = 'Mixed',
        padding = { 5, 10, 20, 15 },
        margin = 0,
        show_padding = true,
        show_margin = false,
        fill = DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.2),
        line = DemoColors.roles.accent_green_line,
    },
    {
        column = 'margin',
        label = 'Top',
        padding = 10,
        margin = { 20, 0, 0, 0 },
        show_padding = false,
        show_margin = true,
        fill = DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.2),
        line = DemoColors.roles.accent_violet_line,
    },
    {
        column = 'margin',
        label = 'Right',
        padding = 10,
        margin = { 0, 20, 0, 0 },
        show_padding = false,
        show_margin = true,
        fill = DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.2),
        line = DemoColors.roles.accent_violet_line,
    },
    {
        column = 'margin',
        label = 'Bottom',
        padding = 10,
        margin = { 0, 0, 20, 0 },
        show_padding = false,
        show_margin = true,
        fill = DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.2),
        line = DemoColors.roles.accent_violet_line,
    },
    {
        column = 'margin',
        label = 'Left',
        padding = 10,
        margin = { 0, 0, 0, 20 },
        show_padding = false,
        show_margin = true,
        fill = DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.2),
        line = DemoColors.roles.accent_violet_line,
    },
    {
        column = 'margin',
        label = 'Mixed',
        padding = 10,
        margin = { 5, 10, 20, 15 },
        show_padding = false,
        show_margin = true,
        fill = DemoColors.rgba(DemoColors.roles.accent_violet_fill, 0.2),
        line = DemoColors.roles.accent_violet_line,
    },
}

local BOX_SIZE = 100
local COLUMN_GAP = 260
local ROW_GAP = 30

local function has_insets(insets)
    return insets ~= nil
        and (insets.top ~= 0 or insets.right ~= 0 or insets.bottom ~= 0 or insets.left ~= 0)
end

local function append_inset_groups(entries, helpers, label, insets)
    if not has_insets(insets) then
        return
    end

    entries[#entries + 1] = {
        label = label .. '.vertical',
        badges = {
            helpers.badge('top', helpers.format_scalar(insets.top)),
            helpers.badge('bottom', helpers.format_scalar(insets.bottom)),
        },
    }

    entries[#entries + 1] = {
        label = label .. '.horizontal',
        badges = {
            helpers.badge('left', helpers.format_scalar(insets.left)),
            helpers.badge('right', helpers.format_scalar(insets.right)),
        },
    }
end

local function build_hint(helpers, node, case)
    local entries = {
        {
            label = 'container',
            badges = {
                helpers.badge('bounds', helpers.format_rect(node:getLocalBounds())),
            },
        },
        {
            label = 'target',
            badges = {
                helpers.badge('content', helpers.format_rect(node:getContentRect())),
            },
        },
    }

    if case.show_padding then
        append_inset_groups(entries, helpers, 'padding', node.padding)
    end

    if case.show_margin then
        append_inset_groups(entries, helpers, 'margin', node.margin)
    end

    return entries
end

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Left column isolates padding one side at a time, then shows a mixed case. Right column does the same for margin. The main box is always the drawable container. Padding adds an inner target box; margin adds an outer guide. Hover a case to inspect the affected edges directly.',
        function(scope, stage)
            local root = stage.baseSceneLayer
            local nodes = {}

            for index = 1, #CASES do
                local case = CASES[index]
                local node = helpers.make_node(scope, root, {
                    x = 0,
                    y = 0,
                    width = BOX_SIZE,
                    height = BOX_SIZE,
                    padding = case.padding,
                    margin = case.margin,
                }, case.label, case.fill, case.line)

                if case.show_padding then
                    rawset(node, '_demo_show_content', true)
                end

                if case.show_margin then
                    helpers.show_margin(node)
                end

                helpers.set_hint(node, function(current)
                    return build_hint(helpers, current, case)
                end)

                nodes[#nodes + 1] = {
                    node = node,
                    column = case.column,
                    row_index = ((index - 1) % 5),
                }
            end

            return {
                title = 'Padding / Margin',
                description = 'This demo compares padding and margin side by side. On the left, padding keeps the target box contained inside its parent, so the target shrinks and shifts inward. On the right, margin does not resize the target box; instead, the outer guide expands around the same parent bounds. The last row in each column combines multiple edges so the mixed case can be compared against the single-edge cases above it.',
                update = function()
                    local screen_width = love.graphics.getWidth()
                    local screen_height = love.graphics.getHeight()
                    local total_width = (BOX_SIZE * 2) + COLUMN_GAP
                    local total_height = (BOX_SIZE * 5) + (ROW_GAP * 4)
                    local start_x = math.floor((screen_width - total_width) * 0.5 + 0.5)
                    local start_y = math.floor((screen_height - total_height) * 0.5 + 0.5)
                    local column_x = {
                        padding = start_x,
                        margin = start_x + BOX_SIZE + COLUMN_GAP,
                    }

                    for index = 1, #nodes do
                        local entry = nodes[index]
                        entry.node.x = column_x[entry.column]
                        entry.node.y = start_y + (entry.row_index * (BOX_SIZE + ROW_GAP))
                    end
                end,
            }
        end
    )
end
