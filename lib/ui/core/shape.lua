local Container = require('lib.ui.core.container')
local Schema = require('lib.ui.utils.schema')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')
local ShapeFillSource = require('lib.ui.shapes.fill_source')
local ShapeFillPlacement = require('lib.ui.shapes.fill_placement')
local ShapeFillRenderer = require('lib.ui.shapes.fill_renderer')

local Shape = Container:extends('Shape')

Shape._root_compositing_capabilities = {
    opacity = true,
    shader = true,
    blendMode = true,
}

Shape._schema = Schema.merge(Container._schema, require('lib.ui.core.shape_schema'))

function Shape.__index(self, key)
    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then
        return val
    end

    val = Container._walk_hierarchy(Shape, key)
    if val ~= nil then
        return val
    end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        return Container._get_public_read_value(self, key)
    end

    return nil
end

function Shape.__newindex(self, key, value)
    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        Container._set_public_value(self, key, value, 2)

        local rule = allowed_public_keys[key]
        if Types.is_table(rule) and Types.is_function(rule.set) then
            rule.set(self, value)
        end
        return
    end

    rawset(self, key, value)
end

function Shape:constructor(opts)
    Container.constructor(self, opts)
    rawset(self, '_ui_shape_instance', true)
end

function Shape.new(opts)
    return Shape(opts)
end

function Shape:addChild()
    Assert.fail('Shape may not contain child nodes', 2)
end

function Shape:removeChild()
    Assert.fail('Shape may not contain child nodes', 2)
end

function Shape:_get_shape_local_bounds()
    return rawget(self, '_local_bounds_cache') or self:getLocalBounds()
end

function Shape:_get_local_points()
    local bounds = self:_get_shape_local_bounds()

    return {
        { bounds.x, bounds.y },
        { bounds.x + bounds.width, bounds.y },
        { bounds.x + bounds.width, bounds.y + bounds.height },
        { bounds.x, bounds.y + bounds.height },
    }
end

function Shape:_get_world_bounds_points()
    local matrix = rawget(self, '_world_transform_cache')
    local local_points = self:_get_local_points()
    local world_points = {}

    if matrix == nil then
        return world_points
    end

    for index = 1, #local_points do
        local point = local_points[index]
        local world_x, world_y = matrix:transform_point(point[1], point[2])
        world_points[#world_points + 1] = { x = world_x, y = world_y }
    end

    return world_points
end

function Shape:_resolve_fill_surface()
    return ShapeFillSource.resolve_surface(self)
end

function Shape:_resolve_active_fill_source()
    return ShapeFillSource.resolve_active_descriptor(self:_resolve_fill_surface())
end

function Shape:_resolve_active_fill_placement(local_bounds)
    return ShapeFillPlacement.resolve(
        local_bounds or self:getLocalBounds(),
        self:_resolve_active_fill_source()
    )
end

function Shape:_resolve_polygon_stroke_options()
    return {
        color = self.strokeColor,
        opacity = self.strokeOpacity or 1,
        width = self.strokeWidth or 0,
        style = self.strokeStyle or 'smooth',
        join = self.strokeJoin or 'miter',
        miter_limit = self.strokeMiterLimit or 10,
        pattern = self.strokePattern or 'solid',
        dash_length = self.strokeDashLength or 8,
        gap_length = self.strokeGapLength or 4,
        dash_offset = self.strokeDashOffset or 0,
    }
end

local function active_fill_is_visible(active_fill)
    if active_fill == nil then
        return false
    end

    if (active_fill.opacity or 1) <= 0 then
        return false
    end

    if active_fill.kind ~= 'color' then
        return true
    end

    local color = active_fill.color or { 1, 1, 1, 1 }
    return (color[4] or 1) > 0
end

function Shape:_is_active_fill_visible(active_fill)
    return active_fill_is_visible(active_fill or self:_resolve_active_fill_source())
end

function Shape:_render_active_fill(graphics, local_points, world_points, active_fill)
    active_fill = active_fill or self:_resolve_active_fill_source()

    if active_fill.kind == 'color' then
        return DrawHelpers.draw_polygon_fill(
            graphics,
            world_points,
            active_fill.color,
            active_fill.opacity
        )
    end

    return ShapeFillRenderer.draw(
        self,
        graphics,
        local_points,
        self:_resolve_active_fill_placement()
    )
end

function Shape:draw(graphics)
    if not Types.is_table(graphics) then
        return
    end

    local bounds = self:getWorldBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        return
    end

    local active_fill = self:_resolve_active_fill_source()

    if active_fill.kind ~= 'color' or Types.is_function(graphics.polygon) then
        local local_points = self:_get_local_points()
        local world_points = DrawHelpers.transform_local_points(self, local_points)

        return self:_render_active_fill(graphics, local_points, world_points, active_fill)
    end

    if not Types.is_function(graphics.rectangle) then
        return
    end

    local fill_color = active_fill.color or { 1, 1, 1, 1 }
    local alpha = (fill_color[4] or 1) * (active_fill.opacity or 1)

    if alpha <= 0 then
        return
    end

    local restore_red = nil
    local restore_green = nil
    local restore_blue = nil
    local restore_alpha = nil

    if Types.is_function(graphics.getColor) then
        restore_red, restore_green, restore_blue, restore_alpha = graphics.getColor()
    end

    if Types.is_function(graphics.setColor) then
        graphics.setColor(
            fill_color[1] or 1,
            fill_color[2] or 1,
            fill_color[3] or 1,
            alpha
        )
    end

    graphics.rectangle(
        'fill',
        bounds.x,
        bounds.y,
        bounds.width,
        bounds.height
    )

    if restore_red ~= nil and Types.is_function(graphics.setColor) then
        graphics.setColor(
            restore_red,
            restore_green,
            restore_blue,
            restore_alpha
        )
    end
end

function Shape:_requires_shape_result_clip()
    return false
end

function Shape:_has_visible_root_result_stroke()
    local stroke_color = self.strokeColor

    return Types.is_table(stroke_color) and
        (self.strokeWidth or 0) > 0 and
        ((stroke_color[4] or 1) * (self.strokeOpacity or 1)) > 0
end

function Shape:_resolve_root_compositing_result_clip()
    if not self:_requires_shape_result_clip() and not self:_has_visible_root_result_stroke() then
        return nil
    end

    return {
        kind = 'stencil_mask',
    }
end

function Shape:_draw_root_compositing_result_stroke_mask(graphics, world_points)
    local stroke = self:_resolve_polygon_stroke_options()
    stroke.color = { 1, 1, 1, 1 }
    stroke.opacity = 1
    stroke.node_opacity = 1

    return DrawHelpers.draw_polygon_stroke(graphics, world_points, stroke)
end

function Shape:_draw_root_compositing_result_clip(graphics)
    if not Types.is_table(graphics) then
        return
    end

    local local_points = self:_get_local_points()
    local world_points = DrawHelpers.transform_local_points(self, local_points)
    local active_fill = self:_resolve_active_fill_source()

    if active_fill_is_visible(active_fill) and Types.is_function(graphics.polygon) then
        graphics.polygon('fill', DrawHelpers.flatten_points(world_points))
    end

    if self:_has_visible_root_result_stroke() then
        self:_draw_root_compositing_result_stroke_mask(graphics, world_points)
    end
end

function Shape:_contains_local_point(local_x, local_y)
    local bounds = self:getLocalBounds()

    return bounds:contains_point(local_x, local_y)
end

function Shape:get_local_centroid()
    local bounds = self:getLocalBounds()

    return bounds.x + (bounds.width / 2), bounds.y + (bounds.height / 2)
end

function Shape:set_centroid_pivot()
    local bounds = self:getLocalBounds()

    if bounds.width == 0 or bounds.height == 0 then
        return
    end

    local centroid_x, centroid_y = self:get_local_centroid()

    Assert.number('centroid_x', centroid_x, 2)
    Assert.number('centroid_y', centroid_y, 2)

    self.pivotX = centroid_x / bounds.width
    self.pivotY = centroid_y / bounds.height
end

function Shape:containsPoint(x, y)
    local local_x, local_y = self:worldToLocal(x, y)

    return self:_contains_local_point(local_x, local_y)
end

function Shape:_is_effectively_targetable(x, y, state)
    return Container._is_effectively_targetable(self, x, y, state) and
        self:containsPoint(x, y)
end

return Shape
