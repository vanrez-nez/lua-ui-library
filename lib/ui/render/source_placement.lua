local SourcePlacement = {}

local floor = math.floor

local function copy_bounds(bounds)
    return {
        x = bounds.x or 0,
        y = bounds.y or 0,
        width = bounds.width or 0,
        height = bounds.height or 0,
    }
end

function SourcePlacement.resolve_aligned_origin(axis_start, axis_size, source_size, align, offset)
    local origin = axis_start or 0
    local resolved_axis_size = axis_size or 0
    local resolved_source_size = source_size or 0

    if align == 'center' then
        origin = origin + ((resolved_axis_size - resolved_source_size) * 0.5)
    elseif align == 'end' then
        origin = origin + resolved_axis_size - resolved_source_size
    end

    return origin + (offset or 0)
end

local function resolve_tiling_axis(axis_start, axis_size, source_size, align, offset, repeat_axis)
    local origin = SourcePlacement.resolve_aligned_origin(
        axis_start,
        axis_size,
        source_size,
        align,
        offset
    )

    if repeat_axis ~= true or source_size <= 0 or axis_size <= 0 then
        return {
            origin = origin,
            start = origin,
            step = source_size,
            repeat_axis = repeat_axis == true,
        }
    end

    local start = origin + (floor((axis_start - origin) / source_size) * source_size)

    while start > axis_start do
        start = start - source_size
    end

    while (start + source_size) <= axis_start do
        start = start + source_size
    end

    return {
        origin = origin,
        start = start,
        step = source_size,
        repeat_axis = true,
    }
end

function SourcePlacement.resolve_tiled_placements(bounds, source_width, source_height, opts)
    local resolved_bounds = copy_bounds(bounds or {})
    local resolved_source_width = source_width or 0
    local resolved_source_height = source_height or 0

    opts = opts or {}

    local repeat_x = opts.repeatX == true
    local repeat_y = opts.repeatY == true

    local axis_x = resolve_tiling_axis(
        resolved_bounds.x,
        resolved_bounds.width,
        resolved_source_width,
        opts.alignX or 'start',
        opts.offsetX or 0,
        repeat_x
    )
    local axis_y = resolve_tiling_axis(
        resolved_bounds.y,
        resolved_bounds.height,
        resolved_source_height,
        opts.alignY or 'start',
        opts.offsetY or 0,
        repeat_y
    )

    local placements = {}
    if resolved_bounds.width <= 0 or
        resolved_bounds.height <= 0 or
        resolved_source_width <= 0 or
        resolved_source_height <= 0 then
        return {
            bounds = resolved_bounds,
            originX = axis_x.origin,
            originY = axis_y.origin,
            startX = axis_x.start,
            startY = axis_y.start,
            repeatX = repeat_x,
            repeatY = repeat_y,
            sourceWidth = resolved_source_width,
            sourceHeight = resolved_source_height,
            placements = placements,
        }
    end

    local max_x = resolved_bounds.x + resolved_bounds.width
    local max_y = resolved_bounds.y + resolved_bounds.height
    local placement_x = axis_x.start

    while true do
        local placement_y = axis_y.start

        while true do
            placements[#placements + 1] = {
                x = placement_x,
                y = placement_y,
                width = resolved_source_width,
                height = resolved_source_height,
                scaleX = 1,
                scaleY = 1,
            }

            if not repeat_y then
                break
            end

            placement_y = placement_y + resolved_source_height
            if placement_y >= max_y then
                break
            end
        end

        if not repeat_x then
            break
        end

        placement_x = placement_x + resolved_source_width
        if placement_x >= max_x then
            break
        end
    end

    return {
        bounds = resolved_bounds,
        originX = axis_x.origin,
        originY = axis_y.origin,
        startX = axis_x.start,
        startY = axis_y.start,
        repeatX = repeat_x,
        repeatY = repeat_y,
        sourceWidth = resolved_source_width,
        sourceHeight = resolved_source_height,
        placements = placements,
    }
end

return SourcePlacement
