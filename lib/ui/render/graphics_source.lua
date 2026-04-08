local Types = require('lib.ui.utils.types')
local Texture = require('lib.ui.graphics.texture')
local Sprite = require('lib.ui.graphics.sprite')

local GraphicsSource = {}

local function read_method_number(source, method_name)
    local ok, method = pcall(function()
        if source == nil then
            return nil
        end

        return source[method_name]
    end)

    if not ok then
        return nil
    end

    if not Types.is_function(method) then
        return nil
    end

    local ok, value = pcall(method, source)
    if ok and Types.is_number(value) then
        return value
    end

    return nil
end

local function read_field_number(source, field_name)
    if source == nil then
        return nil
    end

    local ok, value = pcall(function()
        return source[field_name]
    end)

    if ok and Types.is_number(value) then
        return value
    end

    return nil
end

function GraphicsSource.get_intrinsic_dimensions(source)
    if source == nil then
        return 0, 0
    end

    local width = nil
    local height = nil

    local ok, get_intrinsic_dimensions = pcall(function()
        return source.getIntrinsicDimensions
    end)

    if not ok then
        get_intrinsic_dimensions = nil
    end

    if Types.is_function(get_intrinsic_dimensions) then
        local ok, resolved_width, resolved_height = pcall(get_intrinsic_dimensions, source)
        if ok and Types.is_number(resolved_width) and Types.is_number(resolved_height) then
            width = resolved_width
            height = resolved_height
        end
    end

    if width == nil then
        width = read_method_number(source, 'getWidth') or read_field_number(source, 'width') or 0
    end

    if height == nil then
        height = read_method_number(source, 'getHeight') or read_field_number(source, 'height') or 0
    end

    return width, height
end

local function create_sprite_quad(sprite)
    local texture = sprite:getTexture()
    local region = sprite:getRegion()

    if love == nil or love.graphics == nil or not Types.is_function(love.graphics.newQuad) then
        return nil
    end

    return love.graphics.newQuad(
        region.x,
        region.y,
        region.width,
        region.height,
        texture:getWidth(),
        texture:getHeight()
    )
end

function GraphicsSource.resolve_draw_source(source)
    local source_width, source_height = GraphicsSource.get_intrinsic_dimensions(source)
    if source_width <= 0 or source_height <= 0 then
        return nil, nil, 0, 0
    end

    if Types.is_instance(source, Texture) then
        local drawable = source:getDrawable()
        if drawable == nil then
            return nil, nil, 0, 0
        end

        return drawable, nil, source_width, source_height
    end

    if Types.is_instance(source, Sprite) then
        local texture = source:getTexture()
        local region = source:getRegion()
        local drawable = texture and texture:getDrawable() or nil

        if drawable == nil or region == nil then
            return nil, nil, 0, 0
        end

        return drawable, create_sprite_quad(source), source_width, source_height
    end

    return nil, nil, 0, 0
end

return GraphicsSource
