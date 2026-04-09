local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local Types = require('lib.ui.utils.types')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')
local Schema = require('lib.ui.utils.schema')
local Motion = require('lib.ui.motion')
local Styling = require('lib.ui.render.styling')

local max = math.max
local min = math.min

local Drawable = Container:extends('Drawable')

Drawable._root_compositing_capabilities = {
    opacity = true,
    shader = true,
    blendMode = true,
}

function Drawable.__index(self, key)
    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then return val end
    
    val = Container._walk_hierarchy(Drawable, key)
    if val ~= nil then return val end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        return Container._get_public_read_value(self, key)
    end

    return nil
end

function Drawable.__newindex(self, key, value)
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

Drawable._schema = Schema.merge(Container._schema, require('lib.ui.core.drawable_schema'))

local DEFAULT_FOCUS_RING_OFFSET = 2
local DEFAULT_FOCUS_RING_WIDTH = 2
local get_effective_value
local resolve_content_rect





local function copy_options(opts)
    if opts == nil then
        return {}
    end

    if not Types.is_table(opts) then
        Assert.fail('opts must be a table', 2)
    end

    local copy = {}

    for key, value in pairs(opts) do
        copy[key] = value
    end

    return copy
end



local function get_effective_insets(self, key)
    local effective_values = rawget(self, '_effective_values')
    return (effective_values and effective_values[key]) or Insets.zero()
end

local function get_motion_surface_value(self, key)
    local motion_state = rawget(self, '_motion_visual_state')
    if motion_state == nil then
        return nil
    end

    return motion_state[key]
end

local function child_is_visible(child)
    local effective_values = rawget(child, '_effective_values')

    if effective_values == nil then
        return true
    end

    return effective_values.visible ~= false
end

local function get_local_content_rect(self)
    local padding = get_effective_insets(self, 'padding')
    local width = rawget(self, '_resolved_width') or 0
    local height = rawget(self, '_resolved_height') or 0

    return Rectangle(
        padding.left,
        padding.top,
        max(0, width - padding.left - padding.right),
        max(0, height - padding.top - padding.bottom)
    )
end

local function get_child_parent_local_bounds(child)
    local matrix = rawget(child, '_local_transform_cache')
    local width = rawget(child, '_resolved_width') or 0
    local height = rawget(child, '_resolved_height') or 0
    local x1, y1 = matrix:transform_point(0, 0)
    local x2, y2 = matrix:transform_point(width, 0)
    local x3, y3 = matrix:transform_point(width, height)
    local x4, y4 = matrix:transform_point(0, height)

    return Rectangle.bounding_box({
        { x = x1, y = y1 },
        { x = x2, y = y2 },
        { x = x3, y = y3 },
        { x = x4, y = y4 },
    })
end

local function apply_resolved_size(node, width, height)
    local resolved_width = width
    local resolved_height = height

    if resolved_width == nil then
        resolved_width = rawget(node, '_resolved_width') or 0
    end

    if resolved_height == nil then
        resolved_height = rawget(node, '_resolved_height') or 0
    end

    if rawget(node, '_resolved_width') == resolved_width and
        rawget(node, '_resolved_height') == resolved_height then
        rawset(node, '_measurement_dirty', false)
        return false
    end

    rawset(node, '_resolved_width', resolved_width)
    rawset(node, '_resolved_height', resolved_height)
    rawset(node, '_measurement_dirty', false)
    rawset(node, '_local_bounds_cache', Rectangle(0, 0, resolved_width, resolved_height))
    rawset(node, '_local_transform_dirty', true)
    rawset(node, '_world_transform_dirty', true)
    rawset(node, '_bounds_dirty', true)
    rawset(node, '_world_inverse_dirty', true)

    if rawget(node, '_ui_layout_instance') == true and
        Types.is_function(node._refresh_layout_content_rect) then
        node:_refresh_layout_content_rect()
        rawset(node, '_layout_dirty', true)
    end

    local children = rawget(node, '_children') or {}

    for index = 1, #children do
        children[index]:_mark_parent_layout_dependency_dirty()
    end

    return true
end

local function assert_no_content_fill_dependency(self, children)
    local effective_values = rawget(self, '_effective_values') or {}

    if effective_values.width == 'content' then
        for index = 1, #children do
            local child = children[index]
            local child_values = rawget(child, '_effective_values') or {}

            if child_is_visible(child) and child_values.width == 'fill' then
                Assert.fail(
                    'Drawable has a circular measurement dependency because width = "content" and a visible child has width = "fill"',
                    3
                )
            end
        end
    end

    if effective_values.height == 'content' then
        for index = 1, #children do
            local child = children[index]
            local child_values = rawget(child, '_effective_values') or {}

            if child_is_visible(child) and child_values.height == 'fill' then
                Assert.fail(
                    'Drawable has a circular measurement dependency because height = "content" and a visible child has height = "fill"',
                    3
                )
            end
        end
    end
end

local function collect_child_entries(children)
    local entries = {}

    for index = 1, #children do
        local child = children[index]

        child:_set_layout_offset(0, 0)
        rawset(child, '_measurement_dirty', true)
        child:_refresh_if_dirty()

        if child_is_visible(child) then
            entries[#entries + 1] = {
                child = child,
                bounds = get_child_parent_local_bounds(child),
            }
        end
    end

    return entries
end

local function measure_content_extent(self, entries)
    local content_rect = get_local_content_rect(self)
    local max_right = content_rect.x
    local max_bottom = content_rect.y

    for index = 1, #entries do
        local bounds = entries[index].bounds

        if bounds:right() > content_rect.x then
            max_right = max(max_right, bounds:right())
        end

        if bounds:bottom() > content_rect.y then
            max_bottom = max(max_bottom, bounds:bottom())
        end
    end

    return Rectangle(
        content_rect.x,
        content_rect.y,
        max(0, max_right - content_rect.x),
        max(0, max_bottom - content_rect.y)
    )
end

local function apply_content_measurement(self, content_extent)
    local effective_values = rawget(self, '_effective_values') or {}
    local padding = get_effective_insets(self, 'padding')
    local resolved_width = rawget(self, '_resolved_width') or 0
    local resolved_height = rawget(self, '_resolved_height') or 0

    if effective_values.width == 'content' then
        resolved_width = max(
            effective_values.minWidth or 0,
            min(
                effective_values.maxWidth or math.huge,
                padding.left + content_extent.width + padding.right
            )
        )
    end

    if effective_values.height == 'content' then
        resolved_height = max(
            effective_values.minHeight or 0,
            min(
                effective_values.maxHeight or math.huge,
                padding.top + content_extent.height + padding.bottom
            )
        )
    end

    if rawget(self, '_resolved_width') == resolved_width and
        rawget(self, '_resolved_height') == resolved_height then
        return false
    end

    rawset(self, '_resolved_width', resolved_width)
    rawset(self, '_resolved_height', resolved_height)
    rawset(self, '_local_bounds_cache', Rectangle(0, 0, resolved_width, resolved_height))
    rawset(self, '_local_transform_dirty', true)
    rawset(self, '_world_transform_dirty', true)
    rawset(self, '_bounds_dirty', true)
    rawset(self, '_world_inverse_dirty', true)

    local children = rawget(self, '_children') or {}

    for index = 1, #children do
        children[index]:_mark_parent_layout_dependency_dirty()
    end

    return true
end

local function align_children(self, entries, content_extent)
    local effective_values = rawget(self, '_effective_values') or {}
    local content_rect = get_local_content_rect(self)
    local target_rect = resolve_content_rect(self, content_extent.width, content_extent.height)
    local shared_offset_x = target_rect.x - content_extent.x
    local shared_offset_y = target_rect.y - content_extent.y

    for index = 1, #entries do
        local entry = entries[index]
        local child = entry.child
        local width = nil
        local height = nil

        if effective_values.alignX == 'stretch' then
            width = target_rect.width
        end

        if effective_values.alignY == 'stretch' then
            height = target_rect.height
        end

        if width ~= nil or height ~= nil then
            apply_resolved_size(child, width, height)
            child:_refresh_if_dirty()
            entry.bounds = get_child_parent_local_bounds(child)
        end

        local offset_x = shared_offset_x
        local offset_y = shared_offset_y

        if effective_values.alignX == 'stretch' then
            offset_x = content_rect.x - entry.bounds.x
        end

        if effective_values.alignY == 'stretch' then
            offset_y = content_rect.y - entry.bounds.y
        end

        child:_set_layout_offset(offset_x, offset_y)
        child:_refresh_if_dirty()
    end
end

local function refresh_drawable_content(self)
    local children = rawget(self, '_children') or {}

    assert_no_content_fill_dependency(self, children)

    local entries = collect_child_entries(children)
    local content_extent = measure_content_extent(self, entries)

    if apply_content_measurement(self, content_extent) then
        Container._refresh_if_dirty(self)
        entries = collect_child_entries(children)
        content_extent = measure_content_extent(self, entries)
    end

    align_children(self, entries, content_extent)
end

local function resolve_alignment_axis(origin, available_size, content_size, align)
    content_size = max(0, content_size)

    if available_size <= 0 then
        if align == 'stretch' then
            return origin, 0
        end

        return origin, content_size
    end

    if align == 'stretch' then
        return origin, available_size
    end

    if align == 'center' then
        return origin + ((available_size - content_size) / 2), content_size
    end

    if align == 'end' then
        return origin + (available_size - content_size), content_size
    end

    return origin, content_size
end

resolve_content_rect = function(self, content_width, content_height)
    local content_box = get_local_content_rect(self)
    local x, width = resolve_alignment_axis(
        content_box.x,
        content_box.width,
        content_width,
        (get_effective_value(self, 'alignX') or 'start')
    )
    local y, height = resolve_alignment_axis(
        content_box.y,
        content_box.height,
        content_height,
        (get_effective_value(self, 'alignY') or 'start')
    )

    return Rectangle(x, y, width, height)
end



function Drawable.__index(self, key)
    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then return val end
    
    val = Container._walk_hierarchy(Drawable, key)
    if val ~= nil then return val end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        return Container._get_public_read_value(self, key)
    end

    return nil
end

function Drawable.__newindex(self, key, value)
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

function Drawable:constructor(opts)
    self:_initialize(opts)
end

function Drawable:_initialize(opts)
    Container._initialize(self, opts, Drawable._schema, {
        allow_content_width = true,
        allow_content_height = true,
    })
    self._ui_drawable_instance = true
    rawset(self, '_motion_visual_state', {})
    rawset(self, '_motion_last_request', nil)
end

function Drawable.new(opts)
    return Drawable(opts)
end

function Drawable.is_drawable(value)
    return Types.is_instance(value, Drawable)
end

function Drawable:getContentRect()
    local bounds = self:getLocalBounds()
    return bounds:inset(get_effective_insets(self, 'padding'))
end

function Drawable:_resolve_root_compositing_extras()
    local compositing_extras = {
        mask = get_effective_value(self, 'mask'),
        translationX = get_motion_surface_value(self, 'translationX') or 0,
        translationY = get_motion_surface_value(self, 'translationY') or 0,
        scaleX = 1,
        scaleY = 1,
        rotation = get_motion_surface_value(self, 'rotation') or 0,
    }

    local scale_x = get_motion_surface_value(self, 'scaleX')
    local scale_y = get_motion_surface_value(self, 'scaleY')

    if scale_x ~= nil then
        compositing_extras.scaleX = scale_x
    end

    if scale_y ~= nil then
        compositing_extras.scaleY = scale_y
    end

    return compositing_extras
end

get_effective_value = function(self, key)
    local effective_values = rawget(self, '_effective_values')
    return effective_values and effective_values[key]
end

function Drawable:resolveContentRect(content_width, content_height)
    Assert.number('content_width', content_width, 2)
    Assert.number('content_height', content_height, 2)

    local content_box = self:getContentRect()
    local x, width = resolve_alignment_axis(
        content_box.x,
        content_box.width,
        content_width,
        (get_effective_value(self, 'alignX') or 'start')
    )
    local y, height = resolve_alignment_axis(
        content_box.y,
        content_box.height,
        content_height,
        (get_effective_value(self, 'alignY') or 'start')
    )

    return Rectangle(x, y, width, height)
end

function Drawable:_refresh_if_dirty()
    Container._refresh_if_dirty(self)
    refresh_drawable_content(self)
    Container._refresh_if_dirty(self)
end

function Drawable:_prepare_for_layout_pass()
    Container._prepare_for_layout_pass(self)
    assert_no_content_fill_dependency(self, rawget(self, '_children') or {})
    return self
end

function Drawable:_draw_default_focus_indicator(graphics)
    if not Types.is_table(graphics) or not Types.is_function(graphics.rectangle) then
        return self
    end

    local bounds = self:getWorldBounds()
    local restore_red = nil
    local restore_green = nil
    local restore_blue = nil
    local restore_alpha = nil
    local restore_line_width = nil

    if Types.is_function(graphics.getColor) then
        restore_red, restore_green, restore_blue, restore_alpha = graphics.getColor()
    end

    if Types.is_function(graphics.getLineWidth) then
        restore_line_width = graphics.getLineWidth()
    end

    if Types.is_function(graphics.setColor) then
        graphics.setColor(1, 1, 1, 1)
    end

    if Types.is_function(graphics.setLineWidth) then
        graphics.setLineWidth(DEFAULT_FOCUS_RING_WIDTH)
    end

    graphics.rectangle(
        'line',
        bounds.x - DEFAULT_FOCUS_RING_OFFSET,
        bounds.y - DEFAULT_FOCUS_RING_OFFSET,
        bounds.width + (DEFAULT_FOCUS_RING_OFFSET * 2),
        bounds.height + (DEFAULT_FOCUS_RING_OFFSET * 2)
    )

    if restore_line_width ~= nil and Types.is_function(graphics.setLineWidth) then
        graphics.setLineWidth(restore_line_width)
    end

    if restore_red ~= nil and Types.is_function(graphics.setColor) then
        graphics.setColor(
            restore_red,
            restore_green,
            restore_blue,
            restore_alpha
        )
    end

    return self
end

function Drawable:_get_motion_surface(target_name)
    if target_name == nil or target_name == 'root' then
        return self
    end

    local value = rawget(self, target_name)
    if Types.is_table(value) then
        return value
    end

    return nil
end

function Drawable:_apply_motion_value(target_name, property_name, value)
    local surface = self:_get_motion_surface(target_name)
    if surface == nil then
        Assert.fail('unknown motion surface "' .. tostring(target_name) .. '"', 2)
    end

    local state = rawget(surface, '_motion_visual_state')
    if state == nil then
        state = {}
        rawset(surface, '_motion_visual_state', state)
    end

    state[property_name] = value
    return surface
end

function Drawable:_get_motion_value(target_name, property_name)
    local surface = self:_get_motion_surface(target_name)
    if surface == nil then
        return nil
    end

    local state = rawget(surface, '_motion_visual_state') or {}
    return state[property_name]
end

function Drawable:_raise_motion(phase, payload)
    return Motion.request(self, phase, payload or {})
end

-- Draw method called by the stage draw cycle before _draw_control.
-- Paints the styling layer (shadow, background, border) using the resolved
-- props from the four-level cascade. Runs unconditionally — Styling.draw
-- handles the empty-props case without painting anything.
function Drawable:draw(graphics)
    local bounds = self:getWorldBounds()
    local props = Styling.assemble_props(self, rawget(self, '_styling_context'))
    Styling.draw(props, bounds, graphics)
end

return Drawable
