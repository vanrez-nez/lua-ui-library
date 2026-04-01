local Drawable = require('lib.ui.core.drawable')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')

local Switch = Drawable:extends('Switch')

local function checked_value(self)
    if rawget(self, '_checked_controlled') then
        return rawget(self, 'checked') == true
    end
    return rawget(self, '_checked_uncontrolled') == true
end

local function request_checked(self, next_value)
    local on_change = rawget(self, 'onCheckedChange')
    if rawget(self, '_checked_controlled') then
        ControlUtils.call_if_function(on_change, next_value)
        return
    end

    rawset(self, '_checked_uncontrolled', next_value)
    ControlUtils.call_if_function(on_change, next_value)
end

function Switch:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = true,
    })
    Drawable.constructor(self, drawable_opts)
    rawset(self, 'pointerFocusCoupling', 'before')

    rawset(self, '_ui_switch_control', true)
    rawset(self, 'checked', opts.checked)
    rawset(self, 'onCheckedChange', opts.onCheckedChange)
    rawset(self, 'disabled', opts.disabled == true)
    rawset(self, 'dragThreshold', opts.dragThreshold or 10)
    rawset(self, 'snapBehavior', opts.snapBehavior or 'nearest')
    rawset(self, 'label', opts.label)
    rawset(self, 'description', opts.description)

    if self.dragThreshold < 0 then
        Assert.fail('negative dragThreshold is invalid', 2)
    end

    if self.snapBehavior ~= 'nearest' and self.snapBehavior ~= 'directional' then
        Assert.fail('Switch.snapBehavior must be "nearest" or "directional"', 2)
    end

    rawset(self, '_checked_controlled', opts.checked ~= nil)
    rawset(self, '_checked_uncontrolled', opts.checked == true)
    rawset(self, '_dragging', false)
    rawset(self, '_drag_start_x', 0)
    rawset(self, '_drag_dx', 0)
    rawset(self, '_last_drag_dx', 0)

    ControlUtils.assert_controlled_pair('checked', opts.checked, 'onCheckedChange', opts.onCheckedChange, 2)

    self:_add_event_listener('ui.activate', function(event)
        if rawget(self, '_destroyed') then return end
        if rawget(self, 'disabled') == true then return end
        if event.defaultPrevented then return end
        if rawget(self, '_dragging') then return end

        request_checked(self, not checked_value(self))
    end)

    self:_add_event_listener('ui.drag', function(event)
        if rawget(self, '_destroyed') then return end
        if rawget(self, 'disabled') == true then return end

        if event.dragPhase == 'start' then
            rawset(self, '_dragging', true)
            rawset(self, '_drag_start_x', event.x or 0)
            rawset(self, '_drag_dx', 0)
            rawset(self, '_last_drag_dx', 0)
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'move' and rawget(self, '_dragging') then
            local dx = (event.x or 0) - (rawget(self, '_drag_start_x') or 0)
            rawset(self, '_last_drag_dx', rawget(self, '_drag_dx') or 0)
            rawset(self, '_drag_dx', dx)
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'end' and rawget(self, '_dragging') then
            local threshold = rawget(self, 'dragThreshold') or 10
            local dx = rawget(self, '_drag_dx') or 0
            local abs_dx = math.abs(dx)
            local current = checked_value(self)
            local next_value = current

            if abs_dx >= threshold then
                next_value = dx > 0
            else
                local crossed_midpoint = abs_dx > 0
                if crossed_midpoint then
                    if rawget(self, 'snapBehavior') == 'directional' then
                        next_value = dx > 0
                    else
                        next_value = current
                    end
                end
            end

            rawset(self, '_dragging', false)
            rawset(self, '_drag_dx', 0)
            rawset(self, '_last_drag_dx', 0)

            if next_value ~= current then
                request_checked(self, next_value)
            end

            event:stopPropagation()
            return
        end
    end)
end

function Switch.new(opts)
    return Switch(opts)
end

function Switch:_get_checked_state()
    return checked_value(self)
end

function Switch:update(dt)
    Drawable.update(self, dt)

    local disabled = rawget(self, 'disabled') == true
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

    if disabled then
        rawset(self, '_dragging', false)
        rawset(self, '_drag_dx', 0)
        rawset(self, '_last_drag_dx', 0)
    end

    return self
end

return Switch
