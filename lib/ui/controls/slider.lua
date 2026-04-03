local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')

local Slider = Drawable:extends('Slider')

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function normalize_value(self, value)
    local min_value = rawget(self, 'min') or 0
    local max_value = rawget(self, 'max') or 1
    value = clamp(value, min_value, max_value)

    local step = rawget(self, 'step')
    if step ~= nil then
        local steps = math.floor(((value - min_value) / step) + 0.5)
        value = min_value + (steps * step)
        value = clamp(value, min_value, max_value)
    end

    return value
end

local function effective_value(self)
    local current = rawget(self, '_value_controlled') and rawget(self, 'value') or rawget(self, '_value_uncontrolled')
    if current == nil then
        current = rawget(self, 'min') or 0
    end
    return normalize_value(self, current)
end

local function request_value(self, next_value)
    next_value = normalize_value(self, next_value)
    if rawget(self, '_value_controlled') then
        ControlUtils.call_if_function(rawget(self, 'onValueChange'), next_value)
        return
    end

    rawset(self, '_value_uncontrolled', next_value)
    ControlUtils.call_if_function(rawget(self, 'onValueChange'), next_value)
end

local function ratio_for_value(self, value)
    local min_value = rawget(self, 'min') or 0
    local max_value = rawget(self, 'max') or 1
    if max_value <= min_value then
        return 0
    end
    return (value - min_value) / (max_value - min_value)
end

local function value_from_pointer(self, x, y)
    local bounds = self:getWorldBounds()
    local orientation = rawget(self, 'orientation')
    local ratio = 0

    if orientation == 'vertical' then
        local denom = bounds.height <= 0 and 1 or bounds.height
        ratio = 1 - ((y - bounds.y) / denom)
    else
        local denom = bounds.width <= 0 and 1 or bounds.width
        ratio = (x - bounds.x) / denom
    end

    ratio = clamp(ratio, 0, 1)

    local min_value = rawget(self, 'min') or 0
    local max_value = rawget(self, 'max') or 1
    return min_value + ((max_value - min_value) * ratio)
end

local function sync_parts(self)
    local ratio = ratio_for_value(self, effective_value(self))
    rawset(self, '_value_ratio', ratio)

    local track = rawget(self, 'track')
    local thumb = rawget(self, 'thumb')
    local bounds = self:getLocalBounds()

    if rawget(self, 'orientation') == 'vertical' then
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
    rawset(self, 'pointerFocusCoupling', 'before')

    rawset(self, '_ui_slider_control', true)
    rawset(self, 'value', opts.value)
    rawset(self, 'onValueChange', opts.onValueChange)
    rawset(self, 'min', opts.min or 0)
    rawset(self, 'max', opts.max or 1)
    rawset(self, 'step', opts.step)
    rawset(self, 'orientation', opts.orientation or 'horizontal')
    rawset(self, 'disabled', opts.disabled == true)

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

    rawset(self, '_value_controlled', opts.value ~= nil)
    rawset(self, '_value_uncontrolled', normalize_value(self, opts.value or self.min))
    rawset(self, '_dragging', false)
    rawset(self, '_last_motion_value', effective_value(self))

    local track = Container.new({
        tag = (self.tag and (self.tag .. '.track')) or 'slider.track',
        internal = true,
        interactive = false,
        focusable = false,
    })
    local thumb = Container.new({
        tag = (self.tag and (self.tag .. '.thumb')) or 'slider.thumb',
        internal = true,
        interactive = false,
        focusable = false,
    })
    Container.addChild(self, track)
    Container.addChild(self, thumb)
    rawset(self, 'track', track)
    rawset(self, 'thumb', thumb)

    self:_add_event_listener('ui.activate', function(event)
        if self.disabled or event.defaultPrevented then
            return
        end

        if event.x ~= nil and event.y ~= nil then
            request_value(self, value_from_pointer(self, event.x, event.y))
            event:stopPropagation()
        end
    end)

    self:_add_event_listener('ui.drag', function(event)
        if self.disabled then
            return
        end

        if event.dragPhase == 'start' then
            rawset(self, '_dragging', true)
            request_value(self, value_from_pointer(self, event.x, event.y))
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'move' and rawget(self, '_dragging') then
            request_value(self, value_from_pointer(self, event.x, event.y))
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'end' then
            rawset(self, '_dragging', false)
            event:stopPropagation()
        end
    end)

    self:_add_event_listener('ui.scroll', function(event)
        if self.disabled then
            return
        end

        local step = rawget(self, 'step') or ((self.max - self.min) / 10)
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

    self:_add_event_listener('ui.navigate', function(event)
        if self.disabled or event.navigationMode ~= 'directional' then
            return
        end

        local step = rawget(self, 'step') or ((self.max - self.min) / 10)
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

    if rawget(self, '_dragging') then
        return 'dragging'
    end

    if rawget(self, '_focused') == true then
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
    local pv = rawget(self, '_public_values')
    local ev = rawget(self, '_effective_values')
    if pv then
        pv.enabled = not disabled
        pv.interactive = not disabled
        pv.focusable = not disabled
    end
    if ev then
        ev.enabled = not disabled
        ev.interactive = not disabled
        ev.focusable = not disabled
    end

    local value = effective_value(self)
    local previous = rawget(self, '_last_motion_value')
    if previous ~= value then
        self:_raise_motion(rawget(self, '_dragging') and 'value' or 'state-change', {
            defaultTarget = 'thumb',
            previousValue = previous,
            nextValue = value,
        })
    end
    rawset(self, '_last_motion_value', value)

    sync_parts(self)
    return self
end

return Slider
