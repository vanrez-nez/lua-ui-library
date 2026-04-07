local Setup = {}

local DEFAULT_COLORS = {
    circle = { 0.28, 0.75, 0.95, 0.9 },
    triangle = { 0.98, 0.74, 0.28, 0.9 },
    diamond = { 0.45, 0.92, 0.58, 0.88 },
    probe = { 209, 95, 69, 224 },
}

local HOVER_COLORS = {
    circle = { 0.44, 0.86, 1.0, 1.0 },
    triangle = { 1.0, 0.84, 0.44, 1.0 },
    diamond = { 0.62, 1.0, 0.72, 1.0 },
    probe = { 235, 126, 98, 245 },
}

local ROTATION_SPEEDS = {
    circle = math.rad(18),
    triangle = math.rad(-26),
    diamond = math.rad(22),
}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('shapes_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

function Setup.install(args)
    local root = args.root
    local stage = args.stage
    local state = args.state

    local circle = find_required(root, 'shape-circle')
    local triangle = find_required(root, 'shape-triangle')
    local diamond = find_required(root, 'shape-diamond')
    local probe = find_required(root, 'mixed-drawable-probe')
    local base_rotations = {
        circle = circle.rotation or 0,
        triangle = triangle.rotation or 0,
        diamond = diamond.rotation or 0,
    }

    state.rotation_time = state.rotation_time or 0

    rawset(stage, '_demo_screen_hooks', {
        update = function(dt)
            state.rotation_time = (state.rotation_time or 0) + (dt or 0)

            circle.rotation = base_rotations.circle + (state.rotation_time * ROTATION_SPEEDS.circle)
            triangle.rotation = base_rotations.triangle + (state.rotation_time * ROTATION_SPEEDS.triangle)
            diamond.rotation = base_rotations.diamond + (state.rotation_time * ROTATION_SPEEDS.diamond)

            local mouse_x, mouse_y = love.mouse.getPosition()
            local target = stage:resolveTarget(mouse_x, mouse_y)

            circle.fillColor = target == circle and HOVER_COLORS.circle or DEFAULT_COLORS.circle
            triangle.fillColor = target == triangle and HOVER_COLORS.triangle or DEFAULT_COLORS.triangle
            diamond.fillColor = target == diamond and HOVER_COLORS.diamond or DEFAULT_COLORS.diamond
            probe.backgroundColor = target == probe and HOVER_COLORS.probe or DEFAULT_COLORS.probe

            state.current_target = target
            state.mouse_x = mouse_x
            state.mouse_y = mouse_y
        end,
        draw_overlay = function(graphics)
            local target = state.current_target
            local target_name = target and (target.tag or target.id or 'unnamed') or 'none'

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
