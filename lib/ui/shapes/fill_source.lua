local Types = require('lib.ui.utils.types')

local FillSource = {}

local function default_fill_color()
    return { 1, 1, 1, 1 }
end

local function get_motion_value(shape, key)
    if not Types.is_table(shape) then
        return nil
    end

    local motion_state = rawget(shape, '_motion_visual_state')
    if motion_state == nil then
        return nil
    end

    return motion_state[key]
end

local function get_surface_value(shape, key, default)
    local value = get_motion_value(shape, key)

    if value == nil and Types.is_table(shape) then
        local ok, resolved = pcall(function()
            return shape[key]
        end)

        if ok then
            value = resolved
        end
    end

    if value == nil then
        return default
    end

    return value
end

function FillSource.resolve_surface(shape)
    return {
        fillColor = get_surface_value(shape, 'fillColor', default_fill_color()),
        fillOpacity = get_surface_value(shape, 'fillOpacity', 1),
        fillGradient = get_surface_value(shape, 'fillGradient', nil),
        fillTexture = get_surface_value(shape, 'fillTexture', nil),
        fillRepeatX = get_surface_value(shape, 'fillRepeatX', false) == true,
        fillRepeatY = get_surface_value(shape, 'fillRepeatY', false) == true,
        fillOffsetX = get_surface_value(shape, 'fillOffsetX', 0),
        fillOffsetY = get_surface_value(shape, 'fillOffsetY', 0),
        fillAlignX = get_surface_value(shape, 'fillAlignX', 'center'),
        fillAlignY = get_surface_value(shape, 'fillAlignY', 'center'),
    }
end

function FillSource.resolve_active_descriptor(fill_surface)
    fill_surface = fill_surface or {}

    local descriptor = {
        opacity = fill_surface.fillOpacity ~= nil and fill_surface.fillOpacity or 1,
        repeatX = fill_surface.fillRepeatX == true,
        repeatY = fill_surface.fillRepeatY == true,
        offsetX = fill_surface.fillOffsetX or 0,
        offsetY = fill_surface.fillOffsetY or 0,
        alignX = fill_surface.fillAlignX or 'center',
        alignY = fill_surface.fillAlignY or 'center',
    }

    if fill_surface.fillTexture ~= nil then
        descriptor.kind = 'texture'
        descriptor.source_prop = 'fillTexture'
        descriptor.source = fill_surface.fillTexture
        descriptor.texture = fill_surface.fillTexture
        return descriptor
    end

    if fill_surface.fillGradient ~= nil then
        descriptor.kind = 'gradient'
        descriptor.source_prop = 'fillGradient'
        descriptor.source = fill_surface.fillGradient
        descriptor.gradient = fill_surface.fillGradient
        return descriptor
    end

    local fill_color = fill_surface.fillColor or default_fill_color()

    descriptor.kind = 'color'
    descriptor.source_prop = 'fillColor'
    descriptor.source = fill_color
    descriptor.color = fill_color

    return descriptor
end

return FillSource
