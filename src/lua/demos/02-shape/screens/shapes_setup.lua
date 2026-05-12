local Setup = {}
local UI = require('lib.ui')

local Drawable = UI.Drawable

local DEFAULT_COLORS = {
    rect = { 0.93, 0.48, 0.43, 0.9 },
    circle = { 0.28, 0.75, 0.95, 0.9 },
    triangle = { 0.98, 0.74, 0.28, 0.9 },
    diamond = { 0.45, 0.92, 0.58, 0.88 },
}

local HOVER_COLORS = {
    rect = { 1.0, 0.63, 0.57, 1.0 },
    circle = { 0.44, 0.86, 1.0, 1.0 },
    triangle = { 1.0, 0.84, 0.44, 1.0 },
    diamond = { 0.62, 1.0, 0.72, 1.0 },
}

local ROTATION_SPEEDS = {
    rect = math.rad(14),
    circle = math.rad(18),
    triangle = math.rad(-26),
    diamond = math.rad(22),
}

local GRID_GAP_X = 100
local GRID_GAP_Y = 80

local FRAME_STYLE = {
    backgroundColor = nil,
    borderColor = { 116 / 255, 136 / 255, 168 / 255, 1 },
    borderWidth = 1,
    borderPattern = 'dashed',
    borderDashLength = 8,
    borderStyle = 'rough',
}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('shapes_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function create_bounds_frame(id)
    return Drawable.new({
        id = id,
        zIndex = -1,
        pivotX = 0,
        pivotY = 0,
        backgroundColor = nil,
        borderColor = FRAME_STYLE.borderColor,
        borderWidth = FRAME_STYLE.borderWidth,
        borderPattern = FRAME_STYLE.borderPattern,
        borderDashLength = FRAME_STYLE.borderDashLength,
        borderStyle = FRAME_STYLE.borderStyle,
    })
end

local function sync_bounds_frame(frame, node)
    local bounds = node:getWorldBounds()
    local border_width = FRAME_STYLE.borderWidth or 0
    local inset = border_width * 0.5
    local frame_x = bounds.x + inset
    local frame_y = bounds.y + inset
    local frame_width = math.max(0, bounds.width - border_width)
    local frame_height = math.max(0, bounds.height - border_width)
    local next_visible = bounds.width > 0 and bounds.height > 0
    local changed = frame.x ~= frame_x or
        frame.y ~= frame_y or
        frame.width ~= frame_width or
        frame.height ~= frame_height or
        frame.visible ~= next_visible

    frame.x = frame_x
    frame.y = frame_y
    frame.width = frame_width
    frame.height = frame_height
    frame.visible = next_visible

    return changed
end

local function attach_shape_hint(helpers, node, label)
    helpers.set_hint_name(node, label)
    helpers.set_hint_fields(node, {
        rows = {
            { label = 'size', source = 'opts', keys = { 'width', 'height' } },
            { label = 'scale', source = 'opts', keys = { 'scaleX', 'scaleY' } },
            { label = 'pivot', source = 'opts', keys = { 'pivotX', 'pivotY' } },
        },
    })
end

local function layout_shape_grid(root, shapes)
    local viewport = root:getWorldBounds()
    local rect_bounds = shapes.rect:getLocalBounds()
    local circle_bounds = shapes.circle:getLocalBounds()
    local triangle_bounds = shapes.triangle:getLocalBounds()
    local diamond_bounds = shapes.diamond:getLocalBounds()

    local left_column_width = math.max(rect_bounds.width, triangle_bounds.width)
    local right_column_width = math.max(circle_bounds.width, diamond_bounds.width)
    local top_row_height = math.max(rect_bounds.height, circle_bounds.height)
    local bottom_row_height = math.max(triangle_bounds.height, diamond_bounds.height)

    local grid_width = left_column_width + GRID_GAP_X + right_column_width
    local grid_height = top_row_height + GRID_GAP_Y + bottom_row_height
    local base_x = math.floor(viewport.x + ((viewport.width - grid_width) * 0.5))
    local base_y = math.floor(viewport.y + ((viewport.height - grid_height) * 0.5))

    local entries = {
        {
            node = shapes.rect,
            x = base_x + math.floor((left_column_width - rect_bounds.width) * 0.5),
            y = base_y + math.floor((top_row_height - rect_bounds.height) * 0.5),
        },
        {
            node = shapes.circle,
            x = base_x + left_column_width + GRID_GAP_X + math.floor((right_column_width - circle_bounds.width) * 0.5),
            y = base_y + math.floor((top_row_height - circle_bounds.height) * 0.5),
        },
        {
            node = shapes.triangle,
            x = base_x + math.floor((left_column_width - triangle_bounds.width) * 0.5),
            y = base_y + top_row_height + GRID_GAP_Y + math.floor((bottom_row_height - triangle_bounds.height) * 0.5),
        },
        {
            node = shapes.diamond,
            x = base_x + left_column_width + GRID_GAP_X + math.floor((right_column_width - diamond_bounds.width) * 0.5),
            y = base_y + top_row_height + GRID_GAP_Y + math.floor((bottom_row_height - diamond_bounds.height) * 0.5),
        },
    }
    local changed = false

    for index = 1, #entries do
        local entry = entries[index]
        if entry.node.x ~= entry.x or entry.node.y ~= entry.y then
            entry.node.x = entry.x
            entry.node.y = entry.y
            changed = true
        end
    end

    return changed
end

function Setup.install(args)
    local root = args.root
    local stage = args.stage
    local state = args.state
    local helpers = args.helpers

    local rect = find_required(root, 'shape-rect')
    local circle = find_required(root, 'shape-circle')
    local triangle = find_required(root, 'shape-triangle')
    local diamond = find_required(root, 'shape-diamond')
    local shapes = {
        rect = rect,
        circle = circle,
        triangle = triangle,
        diamond = diamond,
    }
    local bounds_frames = {
        { frame = root:addChild(create_bounds_frame('shape-rect-bounds-frame')), node = rect },
        { frame = root:addChild(create_bounds_frame('shape-circle-bounds-frame')), node = circle },
        { frame = root:addChild(create_bounds_frame('shape-triangle-bounds-frame')), node = triangle },
        { frame = root:addChild(create_bounds_frame('shape-diamond-bounds-frame')), node = diamond },
    }

    helpers.set_markers(rect, {
        { type = 'pivot', color = { 1.0, 0.72, 0.66, 1.0 } },
    })
    attach_shape_hint(helpers, rect, 'rect')
    helpers.set_markers(circle, {
        { type = 'pivot', color = { 0.66, 0.91, 1.0, 1.0 } },
    })
    attach_shape_hint(helpers, circle, 'circle')
    helpers.set_markers(triangle, {
        { type = 'pivot', color = { 1.0, 0.90, 0.56, 1.0 } },
    })
    attach_shape_hint(helpers, triangle, 'triangle')
    helpers.set_markers(diamond, {
        { type = 'pivot', color = { 0.74, 1.0, 0.80, 1.0 } },
    })
    attach_shape_hint(helpers, diamond, 'diamond')

    local base_rotations = {
        rect = rect.rotation or 0,
        circle = circle.rotation or 0,
        triangle = triangle.rotation or 0,
        diamond = diamond.rotation or 0,
    }

    state.rotation_time = state.rotation_time or 0

    layout_shape_grid(root, shapes)

    for index = 1, #bounds_frames do
        local entry = bounds_frames[index]
        sync_bounds_frame(entry.frame, entry.node)
    end

    rawset(stage, '_demo_screen_hooks', {
        update = function(dt)
            state.rotation_time = (state.rotation_time or 0) + (dt or 0)

            rect.rotation = base_rotations.rect + (state.rotation_time * ROTATION_SPEEDS.rect)
            circle.rotation = base_rotations.circle + (state.rotation_time * ROTATION_SPEEDS.circle)
            triangle.rotation = base_rotations.triangle + (state.rotation_time * ROTATION_SPEEDS.triangle)
            diamond.rotation = base_rotations.diamond + (state.rotation_time * ROTATION_SPEEDS.diamond)

            local mouse_x, mouse_y = love.mouse.getPosition()
            local target = stage:resolveTarget(mouse_x, mouse_y)

            rect.fillColor = target == rect and HOVER_COLORS.rect or DEFAULT_COLORS.rect
            circle.fillColor = target == circle and HOVER_COLORS.circle or DEFAULT_COLORS.circle
            triangle.fillColor = target == triangle and HOVER_COLORS.triangle or DEFAULT_COLORS.triangle
            diamond.fillColor = target == diamond and HOVER_COLORS.diamond or DEFAULT_COLORS.diamond

            state.current_target = target
            state.mouse_x = mouse_x
            state.mouse_y = mouse_y
        end,
        after_update = function()
            local changed = layout_shape_grid(root, shapes)

            for index = 1, #bounds_frames do
                local entry = bounds_frames[index]
                if sync_bounds_frame(entry.frame, entry.node) then
                    changed = true
                end
            end

            return changed
        end,
        draw_overlay = function(graphics)
            local target = state.current_target
            local target_name = target and (target.tag or target.id or 'unnamed') or 'none'
            local draw_context = helpers._draw_context

            if draw_context ~= nil and target ~= nil then
                draw_context.hovered_node = target
                draw_context.hovered_area = 1
            end

            graphics.setColor(0.05, 0.07, 0.10, 0.92)
            graphics.rectangle('fill', 80, 38, 730, 52, 10, 10)
            graphics.setColor(0.92, 0.95, 1.0, 1.0)
            graphics.print(
                'target: ' .. target_name .. '    mouse: ' ..
                    math.floor(state.mouse_x or 0) .. ', ' ..
                    math.floor(state.mouse_y or 0),
                96,
                54
            )
        end,
    })
end

return Setup
