local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')
local MathUtils = require('lib.ui.utils.math')
local Schema = require('lib.ui.utils.schema')
local Constants = require('lib.ui.core.constants')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')
local StyleScope = require('lib.ui.render.style_scope')
local SliderSchema = require('lib.ui.controls.slider_schema')

local Slider = Drawable:extends('Slider')
local enum_has = Enum.enum_has
local SLIDER_TRACK_SCOPE = StyleScope.create('slider', 'track')
local SLIDER_THUMB_SCOPE = StyleScope.create('slider', 'thumb')

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

Slider._control_schema = SliderSchema
Slider.schema = Schema.extend(Drawable.schema, Slider._control_schema)

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
    local min_value = self.min or 0
    local max_value = self.max or 1
    local ratio

    if orientation == Enums.Orientation.VERTICAL then
        local denom = bounds.height <= 0 and 1 or bounds.height
        ratio = 1 - ((y - bounds.y) / denom)
    else
        local denom = bounds.width <= 0 and 1 or bounds.width
        ratio = (x - bounds.x) / denom
    end

    ratio = MathUtils.clamp(ratio, 0, 1)
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

    if self.orientation == Enums.Orientation.VERTICAL then
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
    self.value = opts.value
    self.onValueChange = opts.onValueChange
    self.min = opts.min or 0
    self.max = opts.max or 1
    self.step = opts.step
    self.orientation = opts.orientation or Enums.Orientation.HORIZONTAL
    self.disabled = opts.disabled == true
    ControlUtils.validate_control_schema(self, opts, Slider._control_schema, 2)
    self.pointerFocusCoupling = Constants.POINTER_FOCUS_COUPLING_BEFORE

    self._ui_slider_control = true

    if self.max <= self.min then
        Assert.fail('Slider.max must be greater than Slider.min', 2)
    end

    if self.step ~= nil and self.step <= 0 then
        Assert.fail('Slider.step must be > 0 when provided', 2)
    end

    if not enum_has(Enums.Orientation, self.orientation) then
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
        style_scope = SLIDER_TRACK_SCOPE,
    })
    local thumb = Drawable.new({
        tag = (self.tag and (self.tag .. '.thumb')) or 'slider.thumb',
        internal = true,
        interactive = false,
        focusable = false,
        style_scope = SLIDER_THUMB_SCOPE,
    })
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

        if event.dragPhase == Constants.DRAG_PHASE_START then
            self._dragging = true
            request_value(self, value_from_pointer(self, event.x, event.y))
            event:stopPropagation()
            return
        end

        if event.dragPhase == Constants.DRAG_PHASE_MOVE and self._dragging then
            request_value(self, value_from_pointer(self, event.x, event.y))
            event:stopPropagation()
            return
        end

        if event.dragPhase == Constants.DRAG_PHASE_END then
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
        if self.disabled or event.navigationMode ~= Constants.NAVIGATION_MODE_DIRECTIONAL then
            return
        end

        local step = self.step or ((self.max - self.min) / 10)
        local next_value = effective_value(self)
        if self.orientation == Enums.Orientation.HORIZONTAL then
            if event.direction == Constants.NAVIGATION_DIRECTION_RIGHT then
                next_value = next_value + step
            elseif event.direction == Constants.NAVIGATION_DIRECTION_LEFT then
                next_value = next_value - step
            else
                return
            end
        else
            if event.direction == Constants.NAVIGATION_DIRECTION_UP then
                next_value = next_value + step
            elseif event.direction == Constants.NAVIGATION_DIRECTION_DOWN then
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

function Slider:resolveStyleVariant()
    if self.disabled then
        return 'disabled'
    end

    if self._dragging then
        return 'dragging'
    end

    if self._focused == true then
        return 'focused'
    end

    return self.style_variant
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

    local variant = self:resolveStyleVariant()
    self.track:setStyleVariant(variant)
    self.thumb:setStyleVariant(variant)
    sync_parts(self)
    return self
end

function Slider:on_destroy()
    ControlUtils.remove_control_listeners(self)
    Container.on_destroy(self)
end

return Slider
