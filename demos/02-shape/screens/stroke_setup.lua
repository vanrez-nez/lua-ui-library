local DemoColors = require('demos.common.colors')
local NativeControls = require('demos.common.native_controls')

local Setup = {}

local GRID_GAP_X = 90
local GRID_GAP_Y = 70
local CAPTION_WIDTH = 250
local CONTROL_TOP = 126
local CONTROL_TOP_OFFSET_RATIO = 0.10
local CONTROL_LABEL_GAP = 6
local CONTROL_GAP = 18
local CONTROL_ROW_GAP = 34
local SHAPE_TOP_GAP = 52
local SHAPE_BOTTOM_GAP = 60

local CASES = {
    {
        id = 'stroke-rect',
        label = 'Rect Stroke',
        dash_speed = 0,
    },
    {
        id = 'stroke-circle',
        label = 'Circle Dash',
        dash_speed = -80,
    },
    {
        id = 'stroke-triangle',
        label = 'Triangle Bevel',
        dash_speed = 0,
    },
    {
        id = 'stroke-diamond',
        label = 'Diamond Dash',
        dash_speed = 64,
    },
}

local STYLE_OPTIONS = {
    { label = 'smooth', value = 'smooth' },
    { label = 'rough', value = 'rough' },
}

local PATTERN_OPTIONS = {
    { label = 'solid', value = 'solid' },
    { label = 'dashed', value = 'dashed' },
}

local WIDTH_OPTIONS = {
    { label = '1', value = 1 },
    { label = '2', value = 2 },
    { label = '3', value = 3 },
    { label = '4', value = 4 },
    { label = '5', value = 5 },
    { label = '6', value = 6 },
    { label = '7', value = 7 },
    { label = '8', value = 8 },
    { label = '9', value = 9 },
    { label = '10', value = 10 },
}

local DASH_OPTIONS = {
    { label = '5', value = 5 },
    { label = '10', value = 10 },
    { label = '15', value = 15 },
    { label = '20', value = 20 },
    { label = '25', value = 25 },
    { label = '30', value = 30 },
}

local GAP_OPTIONS = {
    { label = '0', value = 0 },
    { label = '5', value = 5 },
    { label = '10', value = 10 },
    { label = '15', value = 15 },
    { label = '20', value = 20 },
}

local CONTROL_SPECS = {
    { key = 'style', label = 'Stroke Style', options = STYLE_OPTIONS },
    { key = 'pattern', label = 'Stroke Pattern', options = PATTERN_OPTIONS },
    { key = 'width', label = 'Stroke Width', options = WIDTH_OPTIONS },
    { key = 'dash', label = 'Stroke Dash', options = DASH_OPTIONS },
    { key = 'gap', label = 'Stroke Gap', options = GAP_OPTIONS },
}

local function build_navigator_layout(left_x, top_y, body_width, font)
    local nav_height = font:getHeight() + 12
    local arrow_width = 24

    return {
        left = {
            x = left_x,
            y = top_y,
            width = arrow_width,
            height = nav_height,
        },
        body = {
            x = left_x + arrow_width + 6,
            y = top_y,
            width = body_width,
            height = nav_height,
        },
        right = {
            x = left_x + arrow_width + 6 + body_width + 6,
            y = top_y,
            width = arrow_width,
            height = nav_height,
        },
    }
end

local function navigator_width(layout)
    return layout.right.x + layout.right.width - layout.left.x
end

local function max_option_body_width(font, control_specs)
    local width = 0

    for spec_index = 1, #control_specs do
        local options = control_specs[spec_index].options

        for option_index = 1, #options do
            width = math.max(width, font:getWidth(options[option_index].label))
        end
    end

    return width + 28
end

local function cycle_index(index, delta, total)
    local next_index = index + delta

    if next_index < 1 then
        return total
    end

    if next_index > total then
        return 1
    end

    return next_index
end

local function draw_centered_label(graphics, font, layout, text, y)
    graphics.print(
        text,
        layout.left.x + math.floor((navigator_width(layout) - font:getWidth(text)) * 0.5),
        y
    )
end

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('stroke_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function make_badges(helpers, items)
    local badges = {}

    for index = 1, #items do
        local item = items[index]
        badges[#badges + 1] = helpers.badge(item[1], item[2])
    end

    return badges
end

local function attach_stroke_hint(helpers, node, case)
    helpers.set_hint_name(node, case.label)
    helpers.set_hint(node, function(current)
        local detail_badges

        if current.strokePattern == 'dashed' then
            detail_badges = make_badges(helpers, {
                { 'dash', tostring(current.strokeDashLength or 0) },
                { 'gap', tostring(current.strokeGapLength or 0) },
                { 'offset', tostring(math.floor(current.strokeDashOffset or 0)) },
            })
        else
            detail_badges = make_badges(helpers, {
                { 'join', tostring(current.strokeJoin or 'none') },
                { 'strokeOpacity', tostring(current.strokeOpacity or 1) },
            })
        end

        return {
            {
                label = 'stroke',
                badges = make_badges(helpers, {
                    { 'width', tostring(current.strokeWidth or 0) },
                    { 'style', tostring(current.strokeStyle or 'smooth') },
                    { 'pattern', tostring(current.strokePattern or 'solid') },
                }),
            },
            {
                label = 'detail',
                badges = detail_badges,
            },
        }
    end)
end

local function apply_control_state(state, nodes)
    local style = STYLE_OPTIONS[state.style_index].value
    local pattern = PATTERN_OPTIONS[state.pattern_index].value
    local width = WIDTH_OPTIONS[state.width_index].value
    local dash_length = DASH_OPTIONS[state.dash_index].value
    local gap_length = GAP_OPTIONS[state.gap_index].value

    for _, node in pairs(nodes) do
        node.strokeStyle = style
        node.strokePattern = pattern
        node.strokeWidth = width
        node.strokeDashLength = dash_length
        node.strokeGapLength = gap_length
    end
end

local function build_selector_layouts(root, title_font)
    local viewport = root:getWorldBounds()
    local body_width = max_option_body_width(title_font, CONTROL_SPECS)
    local probe_layout = build_navigator_layout(0, 0, body_width, title_font)
    local control_width = navigator_width(probe_layout)
    local control_top = viewport.y + CONTROL_TOP + math.floor(viewport.height * CONTROL_TOP_OFFSET_RATIO)
    local first_row_count = 3
    local second_row_count = 2
    local first_row_width = (control_width * first_row_count) + (CONTROL_GAP * (first_row_count - 1))
    local second_row_width = (control_width * second_row_count) + CONTROL_GAP
    local first_row_x = math.floor((viewport.width - first_row_width) * 0.5)
    local second_row_x = math.floor((viewport.width - second_row_width) * 0.5)
    local first_row_y = control_top
    local second_row_y = first_row_y
        + probe_layout.body.height
        + title_font:getHeight()
        + CONTROL_LABEL_GAP
        + CONTROL_ROW_GAP

    return {
        style = build_navigator_layout(first_row_x, first_row_y, body_width, title_font),
        pattern = build_navigator_layout(
            first_row_x + control_width + CONTROL_GAP,
            first_row_y,
            body_width,
            title_font
        ),
        width = build_navigator_layout(
            first_row_x + ((control_width + CONTROL_GAP) * 2),
            first_row_y,
            body_width,
            title_font
        ),
        dash = build_navigator_layout(second_row_x, second_row_y, body_width, title_font),
        gap = build_navigator_layout(second_row_x + control_width + CONTROL_GAP, second_row_y, body_width, title_font),
        bottom = second_row_y + probe_layout.body.height,
        body_width = body_width,
    }
end

local function layout_shape_grid(root, cases, nodes, selector_layouts)
    local viewport = root:getWorldBounds()
    local top_row_height = 0
    local bottom_row_height = 0
    local left_column_width = CAPTION_WIDTH
    local right_column_width = CAPTION_WIDTH
    local changed = false

    for index = 1, 2 do
        local bounds = nodes[cases[index].id]:getLocalBounds()
        top_row_height = math.max(top_row_height, bounds.height)
    end

    for index = 3, 4 do
        local bounds = nodes[cases[index].id]:getLocalBounds()
        bottom_row_height = math.max(bottom_row_height, bounds.height)
    end

    local grid_width = left_column_width + GRID_GAP_X + right_column_width
    local grid_height = top_row_height + GRID_GAP_Y + bottom_row_height
    local base_x = math.floor(viewport.x + ((viewport.width - grid_width) * 0.5))
    local available_y = selector_layouts.bottom + SHAPE_TOP_GAP
    local available_height = viewport.height - available_y - SHAPE_BOTTOM_GAP
    local base_y = math.floor(available_y + math.max(0, (available_height - grid_height) * 0.5))
    local layouts = {
        {
            cell_x = base_x,
            cell_y = base_y,
            cell_width = left_column_width,
            cell_height = top_row_height,
        },
        {
            cell_x = base_x + left_column_width + GRID_GAP_X,
            cell_y = base_y,
            cell_width = right_column_width,
            cell_height = top_row_height,
        },
        {
            cell_x = base_x,
            cell_y = base_y + top_row_height + GRID_GAP_Y,
            cell_width = left_column_width,
            cell_height = bottom_row_height,
        },
        {
            cell_x = base_x + left_column_width + GRID_GAP_X,
            cell_y = base_y + top_row_height + GRID_GAP_Y,
            cell_width = right_column_width,
            cell_height = bottom_row_height,
        },
    }

    for index = 1, #cases do
        local case = cases[index]
        local node = nodes[case.id]
        local bounds = node:getLocalBounds()
        local layout = layouts[index]
        local next_x = layout.cell_x + math.floor((layout.cell_width - bounds.width) * 0.5)
        local next_y = layout.cell_y + math.floor((layout.cell_height - bounds.height) * 0.5)

        if node.x ~= next_x or node.y ~= next_y then
            node.x = next_x
            node.y = next_y
            changed = true
        end
    end

    return changed
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local stage = args.stage
    local state = args.state
    local title_font = love.graphics.newFont(12)
    local label_font = love.graphics.newFont(12)
    local nodes = {}
    local selector_layouts = nil

    state.style_index = state.style_index or 1
    state.pattern_index = state.pattern_index or 2
    state.width_index = state.width_index or 4
    state.dash_index = state.dash_index or 4
    state.gap_index = state.gap_index or 3
    state.dash_time = state.dash_time or 0

    for index = 1, #CASES do
        local case = CASES[index]
        local node = find_required(root, case.id)
        nodes[case.id] = node
        attach_stroke_hint(helpers, node, case)
    end

    apply_control_state(state, nodes)

    rawset(stage, '_demo_screen_hooks', {
        update = function(dt)
            state.dash_time = (state.dash_time or 0) + (dt or 0)
            apply_control_state(state, nodes)

            for index = 1, #CASES do
                local case = CASES[index]
                if case.dash_speed ~= nil and case.dash_speed ~= 0 then
                    nodes[case.id].strokeDashOffset = state.dash_time * case.dash_speed
                end
            end

            state.mouse_x, state.mouse_y = love.mouse.getPosition()
            state.current_target = stage:resolveTarget(state.mouse_x, state.mouse_y)
        end,
        after_update = function()
            selector_layouts = build_selector_layouts(root, title_font)
            return layout_shape_grid(root, CASES, nodes, selector_layouts)
        end,
        mousepressed = function(x, y, button)
            local function cycle_control(key, delta, options)
                state[key] = cycle_index(state[key], delta, #options)
                apply_control_state(state, nodes)
                return true
            end

            if button ~= 1 or selector_layouts == nil then
                return false
            end

            for index = 1, #CONTROL_SPECS do
                local spec = CONTROL_SPECS[index]
                local layout = selector_layouts[spec.key]
                local state_key = spec.key .. '_index'

                if NativeControls.point_in_rect(layout.left, x, y) then
                    return cycle_control(state_key, -1, spec.options)
                end

                if NativeControls.point_in_rect(layout.right, x, y) then
                    return cycle_control(state_key, 1, spec.options)
                end
            end

            return false
        end,
        draw_overlay = function(graphics)
            local draw_context = helpers._draw_context
            local mouse_x = state.mouse_x or 0
            local mouse_y = state.mouse_y or 0

            if selector_layouts ~= nil then
                for index = 1, #CONTROL_SPECS do
                    local spec = CONTROL_SPECS[index]
                    local layout = selector_layouts[spec.key]
                    local option = spec.options[state[spec.key .. '_index']]
                    local label_y = layout.body.y - label_font:getHeight() - CONTROL_LABEL_GAP

                    graphics.setColor(DemoColors.roles.text_muted)
                    graphics.setFont(label_font)
                    draw_centered_label(graphics, label_font, layout, spec.label, label_y)

                    NativeControls.draw_navigator(
                        graphics,
                        title_font,
                        layout,
                        option.label,
                        NativeControls.point_in_rect(layout.left, mouse_x, mouse_y),
                        NativeControls.point_in_rect(layout.right, mouse_x, mouse_y)
                    )
                end
            end

            if draw_context ~= nil and state.current_target ~= nil then
                draw_context.hovered_node = state.current_target
                draw_context.hovered_area = 1
            end
        end,
    })
end

return Setup
