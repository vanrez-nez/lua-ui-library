local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Utils = require('lib.ui.utils.common')
local DrawHelpers = require('lib.ui.shapes.draw_helpers')
local ShapeFillSource = require('lib.ui.shapes.fill_source')
local ShapeFillPlacement = require('lib.ui.shapes.fill_placement')
local ShapeFillRenderer = require('lib.ui.shapes.fill_renderer')
local RuntimeProfiler = require('profiler.runtime_profiler')
local DirtyState = require('lib.ui.utils.dirty_state')
local ShapeSchema = require('lib.ui.core.shape_schema')

local Shape = Container:extends('Shape')
local WHITE_COLOR = { 1, 1, 1, 1 }

Shape._root_compositing_capabilities = {
    opacity = true,
    shader = true,
    blendMode = true,
}

Shape._schema = Utils.merge_tables(
    Utils.copy_table(Container._schema),
    ShapeSchema
)

local FILL_CACHE_KEYS = {
    fillColor = true,
    fillOpacity = true,
    fillGradient = true,
    fillTexture = true,
    fillRepeatX = true,
    fillRepeatY = true,
    fillOffsetX = true,
    fillOffsetY = true,
    fillAlignX = true,
    fillAlignY = true,
}

local FILL_MOTION_CACHE_KEYS = {
    fillColor = true,
    fillOpacity = true,
    fillGradient = true,
    fillTexture = true,
    fillRepeatX = true,
    fillRepeatY = true,
    fillOffsetX = true,
    fillOffsetY = true,
    fillAlignX = true,
    fillAlignY = true,
}

local PAINT_KEYS = {
    fillColor = true,
    fillOpacity = true,
    fillGradient = true,
    fillTexture = true,
    fillRepeatX = true,
    fillRepeatY = true,
    fillOffsetX = true,
    fillOffsetY = true,
    fillAlignX = true,
    fillAlignY = true,
    strokeColor = true,
    strokeOpacity = true,
    strokeWidth = true,
    strokeStyle = true,
    strokeJoin = true,
    strokeMiterLimit = true,
    strokePattern = true,
    strokeDashLength = true,
    strokeGapLength = true,
    strokeDashOffset = true,
    shader = true,
    opacity = true,
    blendMode = true,
}

local GEOMETRY_KEYS = {
    width = true,
    height = true,
    minWidth = true,
    minHeight = true,
    maxWidth = true,
    maxHeight = true,
    x = true,
    y = true,
    anchorX = true,
    anchorY = true,
    pivotX = true,
    pivotY = true,
    scaleX = true,
    scaleY = true,
    rotation = true,
    skewX = true,
    skewY = true,
    radius = true,
    cornerRadius = true,
    cornerRadiusTopLeft = true,
    cornerRadiusTopRight = true,
    cornerRadiusBottomRight = true,
    cornerRadiusBottomLeft = true,
}

local function copy_bounds_into(target, bounds)
    target = target or {}
    target.x = bounds.x or 0
    target.y = bounds.y or 0
    target.width = bounds.width or 0
    target.height = bounds.height or 0
    return target
end

local function ensure_indexed_point_buffer(buffer, count)
    for index = 1, count do
        if buffer[index] == nil then
            buffer[index] = { 0, 0 }
        end
    end

    for index = #buffer, count + 1, -1 do
        buffer[index] = nil
    end

    return buffer
end

local function ensure_named_point_buffer(buffer, count)
    for index = 1, count do
        if buffer[index] == nil then
            buffer[index] = {
                x = 0,
                y = 0,
            }
        end
    end

    for index = #buffer, count + 1, -1 do
        buffer[index] = nil
    end

    return buffer
end

local function bounds_match(cached_bounds, bounds)
    if cached_bounds == nil or bounds == nil then
        return false
    end

    return cached_bounds.x == (bounds.x or 0) and
        cached_bounds.y == (bounds.y or 0) and
        cached_bounds.width == (bounds.width or 0) and
        cached_bounds.height == (bounds.height or 0)
end

local function handle_paint_prop_change(_, _, watched_key, target)
    target.shape_dirty:mark('paint')

    if FILL_CACHE_KEYS[watched_key] then
        target:_invalidate_fill_resolution_cache()
    end
end

local function handle_geometry_prop_change(_, _, _, target)
    target.shape_dirty:mark('geometry')
end

Shape.__index = Shape

function Shape:constructor(opts)
    Container.constructor(self, opts, ShapeSchema)
    self.shape_dirty = DirtyState({ 'paint', 'geometry' })
    self.schema:define(ShapeSchema)

    for key in pairs(PAINT_KEYS) do
        self.props:watch(key, handle_paint_prop_change)
    end

    for key in pairs(GEOMETRY_KEYS) do
        self.props:watch(key, handle_geometry_prop_change)
    end

    for key, value in pairs(opts or {}) do
        self[key] = value
    end

    self.shape_dirty:mark('paint', 'geometry')
    self._ui_shape_instance = true
    self._fill_surface_cache = nil
    self._fill_active_descriptor_cache = nil
    self._fill_active_descriptor_cache_surface = nil
    self._fill_placement_cache = nil
    self._local_points = {}
    self._world_points = {}
    self._stroke_options = {}
    self._local_points_scratch = self._local_points
    self._world_bounds_points_scratch = nil
    self._transformed_points_scratch = self._world_points
    self._flattened_points_scratch = nil
    self._polygon_stroke_options_scratch = self._stroke_options
    self._polygon_stroke_mask_options_scratch = nil
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
    return self._local_bounds_cache or self:getLocalBounds()
end

function Shape:_get_local_point_buffer(count, target)
    local points = target or self._local_points

    if points == nil then
        points = {}
        self._local_points = points
    end

    self._local_points_scratch = points

    return ensure_indexed_point_buffer(points, count)
end

function Shape:_transform_local_points(local_points, target)
    local points = target or self._world_points

    if points == nil then
        points = {}
        self._world_points = points
    end

    self._transformed_points_scratch = points

    return DrawHelpers.transform_local_points(self, local_points, points)
end

function Shape:_flatten_points(points)
    local flattened = self._flattened_points_scratch

    if flattened == nil then
        flattened = {}
        self._flattened_points_scratch = flattened
    end

    return DrawHelpers.flatten_points(points, flattened)
end

function Shape:_get_local_points(out_table)
    local profile_token = RuntimeProfiler.push_zone('Shape._get_local_points')
    local bounds = self:_get_shape_local_bounds()
    local points = self:_get_local_point_buffer(4, out_table)
    points[1][1] = bounds.x
    points[1][2] = bounds.y
    points[2][1] = bounds.x + bounds.width
    points[2][2] = bounds.y
    points[3][1] = bounds.x + bounds.width
    points[3][2] = bounds.y + bounds.height
    points[4][1] = bounds.x
    points[4][2] = bounds.y + bounds.height
    RuntimeProfiler.pop_zone(profile_token)
    return points
end

function Shape:_get_world_bounds_points()
    local matrix = self._world_transform_cache
    local local_points = self:_get_local_points()
    local world_points = self._world_bounds_points_scratch

    if world_points == nil then
        world_points = {}
        self._world_bounds_points_scratch = world_points
    end

    if matrix == nil then
        for index = #world_points, 1, -1 do
            world_points[index] = nil
        end
        return world_points
    end

    ensure_named_point_buffer(world_points, #local_points)

    for index = 1, #local_points do
        local point = local_points[index]
        local world_x, world_y = matrix:transform_point(point[1], point[2])
        world_points[index].x = world_x
        world_points[index].y = world_y
    end

    return world_points
end

function Shape:_invalidate_fill_resolution_cache()
    self._fill_surface_cache = nil
    self._fill_active_descriptor_cache = nil
    self._fill_active_descriptor_cache_surface = nil
    self._fill_placement_cache = nil
    return self
end

function Shape:_resolve_fill_surface()
    local cached_surface = self._fill_surface_cache

    if cached_surface ~= nil then
        return cached_surface
    end

    local surface = ShapeFillSource.resolve_surface(self)
    self._fill_surface_cache = surface
    return surface
end

function Shape:_resolve_active_fill_source()
    local fill_surface = self:_resolve_fill_surface()
    local cached_descriptor = self._fill_active_descriptor_cache

    if cached_descriptor ~= nil and self._fill_active_descriptor_cache_surface == fill_surface then
        return cached_descriptor
    end

    local descriptor = ShapeFillSource.resolve_active_descriptor(fill_surface)
    self._fill_active_descriptor_cache_surface = fill_surface
    self._fill_active_descriptor_cache = descriptor
    return descriptor
end

function Shape:_resolve_active_fill_placement(local_bounds, active_fill)
    local profile_token = RuntimeProfiler.push_zone('Shape._resolve_active_fill_placement')
    local resolved_bounds = local_bounds or self:getLocalBounds()
    active_fill = active_fill or self:_resolve_active_fill_source()
    local cached_placement = self._fill_placement_cache

    if cached_placement ~= nil and
        cached_placement.active_fill == active_fill and
        bounds_match(cached_placement.bounds, resolved_bounds) then
        RuntimeProfiler.pop_zone(profile_token)
        return cached_placement.placement
    end

    local placement = ShapeFillPlacement.resolve(
        resolved_bounds,
        active_fill
    )
    local placement_cache = cached_placement or {}
    placement_cache.active_fill = active_fill
    placement_cache.bounds = copy_bounds_into(placement_cache.bounds, resolved_bounds)
    placement_cache.placement = placement
    self._fill_placement_cache = placement_cache
    RuntimeProfiler.pop_zone(profile_token)
    return placement
end

function Shape:_apply_motion_value(target_name, property_name, value)
    local surface = Container._apply_motion_value(self, target_name, property_name, value)

    if surface == self and FILL_MOTION_CACHE_KEYS[property_name] then
        self:_invalidate_fill_resolution_cache()
    end

    return surface
end

function Shape:_refresh_if_dirty()
    local geometry_was_dirty = self.dirty:is_any(
        'measurement',
        'local_transform',
        'world_transform',
        'bounds'
    )

    Container._refresh_if_dirty(self)

    if geometry_was_dirty then
        self.shape_dirty:mark('geometry')
    end
end

function Shape:_resolve_polygon_stroke_options(target)
    local profile_token = RuntimeProfiler.push_zone('Shape._resolve_polygon_stroke_options')
    local stroke = target or self._stroke_options

    if stroke == nil then
        stroke = {}
        self._stroke_options = stroke
    end

    self._polygon_stroke_options_scratch = stroke

    stroke.color = self.strokeColor
    stroke.opacity = self.strokeOpacity or 1
    stroke.width = self.strokeWidth or 0
    stroke.style = self.strokeStyle or 'smooth'
    stroke.join = self.strokeJoin or 'miter'
    stroke.miter_limit = self.strokeMiterLimit or 10
    stroke.pattern = self.strokePattern or 'solid'
    stroke.dash_length = self.strokeDashLength or 8
    stroke.gap_length = self.strokeGapLength or 4
    stroke.dash_offset = self.strokeDashOffset or 0
    stroke.node_opacity = nil
    RuntimeProfiler.pop_zone(profile_token)
    return stroke
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
        self:_resolve_active_fill_placement(nil, active_fill)
    )
end

function Shape:_refresh_shape_geometry()
    local local_points = self:_get_local_points(self._local_points)
    self:_transform_local_points(local_points, self._world_points)
    return local_points, self._world_points
end

function Shape:_refresh_shape_paint()
    return self:_resolve_polygon_stroke_options(self._stroke_options)
end

function Shape:_draw_rect_fallback(graphics, active_fill)
    if self._allow_rect_draw_fallback == false or
        active_fill.kind ~= 'color' or
        not Types.is_function(graphics.rectangle) then
        return false
    end

    local bounds = self:getWorldBounds()
    local fill_color = active_fill.color or { 1, 1, 1, 1 }

    return DrawHelpers.with_fill_color(graphics, fill_color, active_fill.opacity, function()
        graphics.rectangle(
            'fill',
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height
        )
    end)
end

function Shape:_draw_fill(graphics, active_fill)
    active_fill = active_fill or self:_resolve_active_fill_source()

    if active_fill.kind == 'color' and not Types.is_function(graphics.polygon) then
        return self:_draw_rect_fallback(graphics, active_fill)
    end

    return self:_render_active_fill(
        graphics,
        self._local_points,
        self._world_points,
        active_fill
    )
end

function Shape:_draw_stroke(graphics)
    return DrawHelpers.draw_polygon_stroke(
        graphics,
        self._world_points,
        self._stroke_options
    )
end

function Shape:draw(graphics)
    local profile_token = RuntimeProfiler.push_zone('Shape.draw')

    if not Types.is_table(graphics) then
        RuntimeProfiler.pop_zone(profile_token)
        return
    end

    self:_refresh_if_dirty()

    local bounds = self:getWorldBounds()
    if bounds.width <= 0 or bounds.height <= 0 then
        RuntimeProfiler.pop_zone(profile_token)
        return
    end

    local shape_dirty = self.shape_dirty

    if shape_dirty:is_dirty('geometry') then
        self:_refresh_shape_geometry()
        shape_dirty:clear('geometry')
    end

    if shape_dirty:is_dirty('paint') then
        self:_refresh_shape_paint()
        shape_dirty:clear('paint')
    end

    local active_fill = self:_resolve_active_fill_source()
    self:_draw_fill(graphics, active_fill)
    self:_draw_stroke(graphics)

    RuntimeProfiler.pop_zone(profile_token)
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
    local stroke = self:_resolve_polygon_stroke_options(self._polygon_stroke_mask_options_scratch)
    if self._polygon_stroke_mask_options_scratch == nil then
        self._polygon_stroke_mask_options_scratch = stroke
    end
    stroke.color = WHITE_COLOR
    stroke.opacity = 1
    stroke.node_opacity = 1

    return DrawHelpers.draw_polygon_stroke(graphics, world_points, stroke)
end

function Shape:_draw_root_compositing_result_clip(graphics)
    if not Types.is_table(graphics) then
        return
    end

    local local_points = self:_get_local_points()
    local world_points = self:_transform_local_points(local_points)
    local active_fill = self:_resolve_active_fill_source()

    if active_fill_is_visible(active_fill) and Types.is_function(graphics.polygon) then
        graphics.polygon('fill', self:_flatten_points(world_points))
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
