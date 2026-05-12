local Assert = require('lib.ui.utils.assert')
local Container = require('lib.ui.core.container')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')
local Schema = require('lib.ui.utils.schema')
local Motion = require('lib.ui.motion')
local RootCompositor = require('lib.ui.render.root_compositor')
local Styling = require('lib.ui.render.styling')
local DrawableSchema = require('lib.ui.core.drawable_schema')
local Constants = require('lib.ui.core.constants')
local StyleScope = require('lib.ui.render.style_scope')

local max = math.max

local Drawable = Container:extends('Drawable')

Drawable._root_compositing_capabilities = {
    opacity = true,
    shader = true,
    blendMode = true,
}

Drawable.schema = Schema.extend(Container.schema, DrawableSchema)

local DEFAULT_FOCUS_RING_OFFSET = 2
local DEFAULT_FOCUS_RING_WIDTH = 2

local function get_effective_insets(self, key)
    return Insets.normalize(self[key])
end

local function get_motion_surface_value(self, key)
    local motion_state = self._motion_visual_state
    if motion_state == nil then
        return nil
    end

    return motion_state[key]
end

local function child_is_visible(child)
    return child.visible ~= false
end

local function get_local_content_rect(self)
    local padding = get_effective_insets(self, 'padding')
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0

    return Rectangle(
        padding.left,
        padding.top,
        max(0, width - padding.left - padding.right),
        max(0, height - padding.top - padding.bottom)
    )
end

local function get_child_parent_local_bounds(child)
    local matrix = child._local_transform_cache
    local width = child._resolved_width or 0
    local height = child._resolved_height or 0
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

local function assert_no_content_fill_dependency(self, children)
    if self.width == Constants.SIZE_MODE_CONTENT then
        for index = 1, #children do
            local child = children[index]

            if child_is_visible(child) and child.width == Constants.SIZE_MODE_FILL then
                Assert.fail(
                    'Drawable has a circular measurement dependency because '
                        .. 'width = "content" and a visible child has width = "fill"',
                    3
                )
            end
        end
    end

    if self.height == Constants.SIZE_MODE_CONTENT then
        for index = 1, #children do
            local child = children[index]

            if child_is_visible(child) and child.height == Constants.SIZE_MODE_FILL then
                Assert.fail(
                    'Drawable has a circular measurement dependency because '
                        .. 'height = "content" and a visible child has height = "fill"',
                    3
                )
            end
        end
    end
end

local get_effective_value = function(self, key)
    return self[key]
end

local function collect_child_entries(children)
    local entries = {}

    for index = 1, #children do
        local child = children[index]

        child:_set_layout_offset(0, 0)
        child:mark_dirty('measurement')
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

local function resolve_alignment_axis(origin, available_size, content_size, align)
    content_size = max(0, content_size)

    if available_size <= 0 then
        if align == Constants.ALIGN_STRETCH then
            return origin, 0
        end

        return origin, content_size
    end

    if align == Constants.ALIGN_STRETCH then
        return origin, available_size
    end

    if align == Constants.ALIGN_CENTER then
        return origin + ((available_size - content_size) / 2), content_size
    end

    if align == Constants.ALIGN_END then
        return origin + (available_size - content_size), content_size
    end

    return origin, content_size
end

local function resolve_content_rect(self, content_width, content_height)
    local content_box = get_local_content_rect(self)
    local x, width = resolve_alignment_axis(
        content_box.x,
        content_box.width,
        content_width,
        (get_effective_value(self, 'alignX') or Constants.ALIGN_START)
    )
    local y, height = resolve_alignment_axis(
        content_box.y,
        content_box.height,
        content_height,
        (get_effective_value(self, 'alignY') or Constants.ALIGN_START)
    )

    return Rectangle(x, y, width, height)
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
    local padding = get_effective_insets(self, 'padding')
    return self:_apply_content_measurement(
        padding.left + content_extent.width + padding.right,
        padding.top + content_extent.height + padding.bottom
    )
end

local function align_children(self, entries, content_extent)
    local content_rect = get_local_content_rect(self)
    local target_rect = resolve_content_rect(self, content_extent.width, content_extent.height)
    local shared_offset_x = target_rect.x - content_extent.x
    local shared_offset_y = target_rect.y - content_extent.y

    for index = 1, #entries do
        local entry = entries[index]
        local child = entry.child
        local width = nil
        local height = nil

        if self.alignX == Constants.ALIGN_STRETCH then
            width = target_rect.width
        end

        if self.alignY == Constants.ALIGN_STRETCH then
            height = target_rect.height
        end

        if width ~= nil or height ~= nil then
            child:_apply_resolved_size(width, height)
            child:_refresh_if_dirty()
            entry.bounds = get_child_parent_local_bounds(child)
        end

        local offset_x = shared_offset_x
        local offset_y = shared_offset_y

        if self.alignX == Constants.ALIGN_STRETCH then
            offset_x = content_rect.x - entry.bounds.x
        end

        if self.alignY == Constants.ALIGN_STRETCH then
            offset_y = content_rect.y - entry.bounds.y
        end

        child:_set_layout_offset(offset_x, offset_y)
        child:_refresh_if_dirty()
    end
end

local function refresh_drawable_content(self)
    local children = self._children

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

local function validate_style_scope_value(value, level)
    if value == nil then
        return
    end

    StyleScope.assert('Drawable.style_scope', value, level or 3)
end

local function validate_style_variant_value(value, level)
    Rule.validate(DrawableSchema.style_variant, 'Drawable.style_variant', value, nil, level or 3)
end


Drawable.__index = Drawable

function Drawable:constructor(opts)
    Container.constructor(self, opts, nil, {
        allow_content_width = true,
        allow_content_height = true,
    })
    for key, value in pairs(opts or {}) do
        self[key] = value
    end
    validate_style_scope_value(self.style_scope, 3)
    validate_style_variant_value(self.style_variant, 3)
    self._ui_drawable_instance = true
    self._motion_visual_state = {}
    self._motion_last_request = nil
end

function Drawable.new(opts)
    return Drawable(opts)
end

function Drawable.is_drawable(value)
    return Types.is_instance(value, Drawable)
end

function Drawable:setStyleScope(scope)
    validate_style_scope_value(scope, 2)
    self.style_scope = scope
    self:markDirty()
    return self
end

function Drawable:setStyleVariant(variant)
    validate_style_variant_value(variant, 2)
    self.style_variant = variant
    self:markDirty()
    return self
end

function Drawable:resolveStyleVariant()
    return self.style_variant
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

local function color_input_is_visible(color, opacity)
    return Types.is_table(color) and ((color[4] or 1) * (opacity or 1)) > 0
end

local function resolve_local_border_paint_bounds(self, local_bounds)
    if not color_input_is_visible(
            get_effective_value(self, 'borderColor'),
            get_effective_value(self, 'borderOpacity')
        ) then
        return nil
    end

    local top = (get_effective_value(self, 'borderWidthTop') or 0) * 0.5
    local right = (get_effective_value(self, 'borderWidthRight') or 0) * 0.5
    local bottom = (get_effective_value(self, 'borderWidthBottom') or 0) * 0.5
    local left = (get_effective_value(self, 'borderWidthLeft') or 0) * 0.5

    if top == 0 and right == 0 and bottom == 0 and left == 0 then
        return nil
    end

    return Rectangle.from_edges(
        local_bounds.x - left,
        local_bounds.y - top,
        local_bounds.x + local_bounds.width + right,
        local_bounds.y + local_bounds.height + bottom
    )
end

local function resolve_local_outer_shadow_bounds(self, local_bounds)
    if get_effective_value(self, 'shadowInset') == true or
        not color_input_is_visible(
            get_effective_value(self, 'shadowColor'),
            get_effective_value(self, 'shadowOpacity')
        ) then
        return nil
    end

    local blur = get_effective_value(self, 'shadowBlur') or 0
    local margin = blur > 0 and math.ceil(blur) or 0
    local offset_x = get_effective_value(self, 'shadowOffsetX') or 0
    local offset_y = get_effective_value(self, 'shadowOffsetY') or 0

    return Rectangle.from_edges(
        local_bounds.x + offset_x - margin,
        local_bounds.y + offset_y - margin,
        local_bounds.x + local_bounds.width + offset_x + margin,
        local_bounds.y + local_bounds.height + offset_y + margin
    )
end

local function resolve_world_rect(self, local_rect)
    if local_rect == nil or local_rect:is_empty() then
        return Rectangle(0, 0, 0, 0)
    end

    local x1, y1 = self:localToWorld(local_rect.x, local_rect.y)
    local x2, y2 = self:localToWorld(local_rect.x + local_rect.width, local_rect.y)
    local x3, y3 = self:localToWorld(local_rect.x + local_rect.width, local_rect.y + local_rect.height)
    local x4, y4 = self:localToWorld(local_rect.x, local_rect.y + local_rect.height)

    return Rectangle.bounding_box({
        { x = x1, y = y1 },
        { x = x2, y = y2 },
        { x = x3, y = y3 },
        { x = x4, y = y4 },
    })
end

function Drawable:_resolve_root_compositing_world_paint_bounds()
    local local_bounds = self._local_bounds_cache or self:getLocalBounds()
    local paint_bounds = local_bounds:clone()
    local border_bounds = resolve_local_border_paint_bounds(self, local_bounds)
    local shadow_bounds = resolve_local_outer_shadow_bounds(self, local_bounds)

    if border_bounds ~= nil then
        paint_bounds = paint_bounds:union(border_bounds)
    end

    if shadow_bounds ~= nil then
        paint_bounds = paint_bounds:union(shadow_bounds)
    end

    return resolve_world_rect(self, paint_bounds)
end

function Drawable:resolveContentRect(content_width, content_height)
    Assert.number('content_width', content_width, 2)
    Assert.number('content_height', content_height, 2)

    local content_box = self:getContentRect()
    local x, width = resolve_alignment_axis(
        content_box.x,
        content_box.width,
        content_width,
        (get_effective_value(self, 'alignX') or Constants.ALIGN_START)
    )
    local y, height = resolve_alignment_axis(
        content_box.y,
        content_box.height,
        content_height,
        (get_effective_value(self, 'alignY') or Constants.ALIGN_START)
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
    assert_no_content_fill_dependency(self, self._children)
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

    local value = self[target_name]
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

    local state = surface._motion_visual_state
    if state == nil then
        state = {}
        surface._motion_visual_state = state
    end

    state[property_name] = value

    local plan_target = surface
    if plan_target._ui_container_instance ~= true then
        plan_target = self
    end

    if RootCompositor.motion_property_affects_node_plan(plan_target, property_name) then
        RootCompositor.invalidate_node_plan(plan_target)
    end

    return surface
end

function Drawable:_get_motion_value(target_name, property_name)
    local surface = self:_get_motion_surface(target_name)
    if surface == nil then
        return nil
    end

    local state = surface._motion_visual_state
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
    local props = Styling.assemble_props(self)
    Styling.draw(props, bounds, graphics)
end

return Drawable
