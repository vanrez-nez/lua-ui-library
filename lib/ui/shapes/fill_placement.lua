local GraphicsSource = require('lib.ui.render.graphics_source')
local SourcePlacement = require('lib.ui.render.source_placement')
local Rectangle = require('lib.ui.core.rectangle')
local RuntimeProfiler = require('profiler.runtime_profiler')
local Constants = require('lib.ui.core.constants')

local FillPlacement = {}
local PLACEMENT_MODE_STRETCH = 'stretch'

local function resolve_gradient_points(bounds, direction)
    if direction == Constants.ORIENTATION_VERTICAL then
        return bounds.x, bounds.y, bounds.x, bounds.y + bounds.height
    end

    return bounds.x, bounds.y, bounds.x + bounds.width, bounds.y
end

local function resolve_texture_placement(bounds, descriptor)
    local texture_source = descriptor.texture or descriptor.source
    local drawable, quad, source_width, source_height = GraphicsSource.resolve_draw_source(texture_source)
    local resolved_bounds = Rectangle.copy_bounds(bounds)
    local repeat_x = descriptor.repeatX == true
    local repeat_y = descriptor.repeatY == true
    local placement = {
        kind = 'texture',
        source_prop = descriptor.source_prop or 'fillTexture',
        source = texture_source,
        texture = descriptor.texture or texture_source,
        opacity = descriptor.opacity ~= nil and descriptor.opacity or 1,
        repeatX = repeat_x,
        repeatY = repeat_y,
        offsetX = descriptor.offsetX or 0,
        offsetY = descriptor.offsetY or 0,
        alignX = descriptor.alignX or Constants.ALIGN_CENTER,
        alignY = descriptor.alignY or Constants.ALIGN_CENTER,
        localBounds = resolved_bounds,
        drawable = drawable,
        quad = quad,
        sourceWidth = source_width,
        sourceHeight = source_height,
        placements = {},
    }

    if not repeat_x and not repeat_y then
        placement.placementMode = PLACEMENT_MODE_STRETCH
        placement.originX = resolved_bounds.x
        placement.originY = resolved_bounds.y
        placement.startX = placement.originX
        placement.startY = placement.originY

        if resolved_bounds.width > 0 and
            resolved_bounds.height > 0 and
            source_width > 0 and
            source_height > 0 then
            placement.placements[1] = {
                x = resolved_bounds.x,
                y = resolved_bounds.y,
                width = resolved_bounds.width,
                height = resolved_bounds.height,
                scaleX = resolved_bounds.width / source_width,
                scaleY = resolved_bounds.height / source_height,
            }
        end

        return placement
    end

    local tiled = SourcePlacement.resolve_tiled_placements(resolved_bounds, source_width, source_height, {
        alignX = placement.alignX,
        alignY = placement.alignY,
        offsetX = placement.offsetX,
        offsetY = placement.offsetY,
        repeatX = repeat_x,
        repeatY = repeat_y,
    })

    placement.placementMode = 'tile'
    placement.originX = tiled.originX
    placement.originY = tiled.originY
    placement.startX = tiled.startX
    placement.startY = tiled.startY
    placement.placements = tiled.placements

    return placement
end

function FillPlacement.resolve(bounds, descriptor)
    local profile_token = RuntimeProfiler.push_zone('FillPlacement.resolve')
    local resolved_bounds = Rectangle.copy_bounds(bounds or {})
    descriptor = descriptor or {}

    if descriptor.kind == 'texture' then
        local placement = resolve_texture_placement(resolved_bounds, descriptor)
        RuntimeProfiler.pop_zone(profile_token)
        return placement
    end

    if descriptor.kind == 'gradient' then
        local gradient = descriptor.gradient or descriptor.source
        local direction = (gradient and gradient.direction) or Constants.ORIENTATION_HORIZONTAL
        local start_x, start_y, end_x, end_y = resolve_gradient_points(resolved_bounds, direction)

        local placement = {
            kind = 'gradient',
            source_prop = descriptor.source_prop or 'fillGradient',
            source = gradient,
            gradient = gradient,
            opacity = descriptor.opacity ~= nil and descriptor.opacity or 1,
            placementMode = 'gradient',
            localBounds = resolved_bounds,
            span = Rectangle.copy_bounds(resolved_bounds),
            direction = direction,
            startX = start_x,
            startY = start_y,
            endX = end_x,
            endY = end_y,
        }
        RuntimeProfiler.pop_zone(profile_token)
        return placement
    end

    local fill_color = descriptor.color or descriptor.source or { 1, 1, 1, 1 }

    local placement = {
        kind = 'color',
        source_prop = descriptor.source_prop or 'fillColor',
        source = fill_color,
        color = fill_color,
        opacity = descriptor.opacity ~= nil and descriptor.opacity or 1,
        placementMode = 'flat',
        localBounds = resolved_bounds,
        span = Rectangle.copy_bounds(resolved_bounds),
    }
    RuntimeProfiler.pop_zone(profile_token)
    return placement
end

return FillPlacement
