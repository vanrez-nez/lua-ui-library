local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')
local MathUtils = require('lib.ui.utils.math')
local Rule = require('lib.ui.utils.rule')

local Slider = Drawable:extends('Slider')

local function normalize_value(self, value)
    local min_value = self.min or 0
    local max_value = self.max or 1
    value = MathUtils.clamp(value, min_value, max_value)

    local step = self.step
    if step ~= nil then
        local steps = math.floor(((value - min_value) / step) + 0.5)
        value = min_value + (steps * step)
        value = MathUtils.clamp(value, min_value, max_value)
    end

    return value
end

local effective_value, request_value =
    ControlUtils.controlled_value('value', function(self)
        return self.min or 0
    end, {
        normalize = normalize_value,
    })

Slider._control_schema = {
    value = Rule.any(),
    onValueChange = Rule.any(),
    min = Rule.number({ default = 0 }),
    max = Rule.custom(function(_, value, _, level, full_opts)
        value = (value == nil) and 1 or value
        Assert.number('Slider.max', value, level or 1)
        local min_value = (full_opts and full_opts.min) or 0
        if value <= min_value then
            Assert.fail('Slider.max must be greater than Slider.min', level or 1)
        end
        return value
    end, { default = 1 }),
    step = Rule.custom(function(_, value, _, level)
        if value == nil then return nil end
        Assert.number('Slider.step', value, level or 1)
        if value <= 0 then
            Assert.fail('Slider.step must be > 0 when provided', level or 1)
        end
        return value
    end),
    orientation = Rule.custom(function(_, value, _, level)
        value = value or 'horizontal'
        if value ~= 'horizontal' and value ~= 'vertical' then
            Assert.fail('Slider.orientation must be "horizontal" or "vertical"', level or 1)
        end
        return value
    end, { default = 'horizontal' }),
    disabled = Rule.boolean(false),
}

Slider._schema = ControlUtils.extend_schema(Drawable._schema, Slider._control_schema)

local function ratio_for_value(self, value)
    local min_value = self.min or 0
    local max_value = self.max or 1
    if max_value <= min_value then
        return 0
    end
    return (value - min_value) / (max_value - min_value)
end

local function value_from_pointer(self, x, y)
    local bounds = self:getWorldBounds()
    local orientation = self.orientation
    local ratio = 0

    if orientation == 'vertical' then
        local denom = bounds.height <= 0 and 1 or bounds.height
        ratio = 1 - ((y - bounds.y) / denom)
    else
        local denom = bounds.width <= 0 and 1 or bounds.width
        ratio = (x - bounds.x) / denom
    end

    ratio = MathUtils.clamp(ratio, 0, 1)

    local min_value = self.min or 0
    local max_value = self.max or 1
    return min_value + ((max_value - min_value) * ratio)
end

local function sync_parts(self)
    local ratio = ratio_for_value(self, effective_value(self))
    self._value_ratio = ratio

    local track = self.track
    local thumb = self.thumb
    local bounds = {
        width = self._resolved_width or 0,
        height = self._resolved_height or 0,
    }

    if self.orientation == 'vertical' then
        track.x = bounds.width * 0.35
        track.y = 0
        track.width = math.max(6, bounds.width * 0.3)
        track.height = bounds.height

        thumb.width = bounds.width
        thumb.height = math.min(24, math.max(12, bounds.height * 0.18))
        thumb.x = 0
        thumb.y = (bounds.height - thumb.height) * (1 - ratio)
    else
        track.x = 0
        track.y = bounds.height * 0.35
        track.width = bounds.width
        track.height = math.max(6, bounds.height * 0.3)

        thumb.width = math.min(24, math.max(12, bounds.width * 0.12))
        thumb.height = bounds.height
        thumb.x = (bounds.width - thumb.width) * ratio
        thumb.y = 0
    end

    track:markDirty()
    thumb:markDirty()
end

function Slider:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = true,
    })
    Drawable.constructor(self, drawable_opts)
    self.schema:define(Slider._control_schema)
    self.value = opts.value
    self.onValueChange = opts.onValueChange
    self.min = opts.min or 0
    self.max = opts.max or 1
    self.step = opts.step
    self.orientation = opts.orientation or 'horizontal'
    self.disabled = opts.disabled == true
    ControlUtils.validate_control_schema(self, opts, Slider._control_schema, 2)
    self.pointerFocusCoupling = 'before'

    self._ui_slider_control = true

    if self.max <= self.min then
        Assert.fail('Slider.max must be greater than Slider.min', 2)
    end

    if self.step ~= nil and self.step <= 0 then
        Assert.fail('Slider.step must be > 0 when provided', 2)
    end

    if self.orientation ~= 'horizontal' and self.orientation ~= 'vertical' then
        Assert.fail('Slider.orientation must be "horizontal" or "vertical"', 2)
    end

    ControlUtils.assert_controlled_pair('value', opts.value, 'onValueChange', opts.onValueChange, 2)

    self._value_controlled = opts.value ~= nil
    self._value_uncontrolled = normalize_value(self, opts.value or self.min)
    self._dragging = false
    self._last_motion_value = effective_value(self)

    local track = Drawable.new({
        tag = (self.tag and (self.tag .. '.track')) or 'slider.track',
        internal = true,
        interactive = false,
        focusable = false,
    })
    local thumb = Drawable.new({
        tag = (self.tag and (self.tag .. '.thumb')) or 'slider.thumb',
        internal = true,
        interactive = false,
        focusable = false,
    })
    track._styling_context = {
        component = 'slider',
        part = 'track',
    }
    thumb._styling_context = {
        component = 'slider',
        part = 'thumb',
    }
    Container.addChild(self, track)
    Container.addChild(self, thumb)
    self.track = track
    self.thumb = thumb

    ControlUtils.add_control_listener(self, self, 'ui.activate', function(event)
        if self.disabled or event.defaultPrevented then
            return
        end

        if event.x ~= nil and event.y ~= nil then
            request_value(self, value_from_pointer(self, event.x, event.y))
            event:stopPropagation()
        end
    end)

    ControlUtils.add_control_listener(self, self, 'ui.drag', function(event)
        if self.disabled then
            return
        end

        if event.dragPhase == 'start' then
            self._dragging = true
            request_value(self, value_from_pointer(self, event.x, event.y))
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'move' and self._dragging then
            request_value(self, value_from_pointer(self, event.x, event.y))
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'end' then
            self._dragging = false
            event:stopPropagation()
        end
    end)

    ControlUtils.add_control_listener(self, self, 'ui.scroll', function(event)
        if self.disabled then
            return
        end

        local step = self.step or ((self.max - self.min) / 10)
        local next_value = effective_value(self)
        if event.deltaY < 0 or event.deltaX > 0 then
            next_value = next_value + step
        else
            next_value = next_value - step
        end
        request_value(self, next_value)
        event:preventDefault()
        event:stopPropagation()
    end)

    ControlUtils.add_control_listener(self, self, 'ui.navigate', function(event)
        if self.disabled or event.navigationMode ~= 'directional' then
            return
        end

        local step = self.step or ((self.max - self.min) / 10)
        local next_value = effective_value(self)
        if self.orientation == 'horizontal' then
            if event.direction == 'right' then
                next_value = next_value + step
            elseif event.direction == 'left' then
                next_value = next_value - step
            else
                return
            end
        else
            if event.direction == 'up' then
                next_value = next_value + step
            elseif event.direction == 'down' then
                next_value = next_value - step
            else
                return
            end
        end

        request_value(self, next_value)
        event:preventDefault()
        event:stopPropagation()
    end)
end

function Slider.new(opts)
    return Slider(opts)
end

function Slider:_resolve_visual_variant()
    if self.disabled then
        return 'disabled'
    end

    if self._dragging then
        return 'dragging'
    end

    if self._focused == true then
        return 'focused'
    end

    return 'base'
end

function Slider:_get_value()
    return effective_value(self)
end

function Slider:update(dt)
    Drawable.update(self, dt)

    local disabled = self.disabled == true
    ControlUtils.set_interaction_state(self, not disabled)

    local value = effective_value(self)
    local previous = self._last_motion_value
    if previous ~= value then
        self:_raise_motion(self._dragging and 'value' or 'state-change', {
            defaultTarget = 'thumb',
            previousValue = previous,
            nextValue = value,
        })
    end
    self._last_motion_value = value

    local variant = self:_resolve_visual_variant()
    self.track._styling_variant = variant
    self.thumb._styling_variant = variant
    sync_parts(self)
    return self
end

function Slider:on_destroy()
    ControlUtils.remove_control_listeners(self)
    Container.on_destroy(self)
end

return Slider
