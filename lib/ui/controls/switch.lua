local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')
local Schema = require('lib.ui.utils.schema')
local Constants = require('lib.ui.core.constants')
local StyleScope = require('lib.ui.render.style_scope')
local SwitchSchema = require('lib.ui.controls.switch_schema')

local Switch = Drawable:extends('Switch')
local SWITCH_TRACK_SCOPE = StyleScope.create('switch', 'track')
local SWITCH_THUMB_SCOPE = StyleScope.create('switch', 'thumb')

Switch.SnapBehavior = {
    Nearest = 'nearest',
    Directional = 'directional',
}

local checked_value, request_checked =
    ControlUtils.controlled_value('checked', false, {
        callback = 'onCheckedChange',
        normalize = function(_, value)
            return value == true
        end,
    })

Switch.schema = Schema.extend(Drawable.schema, SwitchSchema)

function Switch:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = true,
    })
    Drawable.constructor(self, drawable_opts)
    self.checked = opts.checked
    self.onCheckedChange = opts.onCheckedChange
    self.disabled = opts.disabled == true
    self.dragThreshold = opts.dragThreshold or 10
    self.snapBehavior = opts.snapBehavior or 'nearest'
    self.label = opts.label
    self.description = opts.description
    self.pointerFocusCoupling = 'before'

    self._ui_switch_control = true

    if self.dragThreshold < 0 then
        Assert.fail('negative dragThreshold is invalid', 2)
    end

    if self.snapBehavior ~= 'nearest' and self.snapBehavior ~= 'directional' then
        Assert.fail('Switch.snapBehavior must be "nearest" or "directional"', 2)
    end

    self._checked_controlled = opts.checked ~= nil
    self._checked_uncontrolled = opts.checked == true
    self._dragging = false
    self._drag_start_x = 0
    self._drag_dx = 0
    self._last_drag_dx = 0

    local track = Drawable.new({
        tag = (self.tag and (self.tag .. '.track')) or 'switch.track',
        internal = true,
        width = 40,
        height = 24,
        interactive = false,
        focusable = false,
        style_scope = SWITCH_TRACK_SCOPE,
    })
    local thumb = Drawable.new({
        tag = (self.tag and (self.tag .. '.thumb')) or 'switch.thumb',
        internal = true,
        width = 18,
        height = 18,
        interactive = false,
        focusable = false,
        style_scope = SWITCH_THUMB_SCOPE,
    })
    track:addChild(thumb)
    Container.addChild(self, track)
    self.track = track
    self.thumb = thumb

    ControlUtils.assert_controlled_pair('checked', opts.checked, 'onCheckedChange', opts.onCheckedChange, 2)

    ControlUtils.add_control_listener(self, self, 'ui.activate', function(event)
        if self.disabled == true then return end
        if event.defaultPrevented then return end
        if self._dragging then return end

        request_checked(self, not checked_value(self))
    end)

    ControlUtils.add_control_listener(self, self, 'ui.drag', function(event)
        if self.disabled == true then return end

        if event.dragPhase == Constants.DRAG_PHASE_START then
            self._dragging = true
            self._drag_start_x = event.x or 0
            self._drag_dx = 0
            self._last_drag_dx = 0
            event:stopPropagation()
            return
        end

        if event.dragPhase == Constants.DRAG_PHASE_MOVE and self._dragging then
            local dx = (event.x or 0) - (self._drag_start_x or 0)
            self._last_drag_dx = self._drag_dx or 0
            self._drag_dx = dx
            event:stopPropagation()
            return
        end

        if event.dragPhase == Constants.DRAG_PHASE_END and self._dragging then
                local threshold = self.dragThreshold or 10
            local dx = self._drag_dx or 0
            local abs_dx = math.abs(dx)
            local current = checked_value(self)
            local next_value = current

            if abs_dx >= threshold then
                next_value = dx > 0
            else
                local crossed_midpoint = abs_dx > 0
                if crossed_midpoint then
                    if self.snapBehavior == 'directional' then
                        next_value = dx > 0
                    else
                        next_value = current
                    end
                end
            end

            self._dragging = false
            self._drag_dx = 0
            self._last_drag_dx = 0

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

function Switch:resolveStyleVariant()
    if self.disabled == true then
        return 'disabled'
    end

    if self._dragging == true then
        return 'dragging'
    end

    if checked_value(self) then
        return 'checked'
    end

    if self._focused == true then
        return 'focused'
    end

    return self.style_variant
end

function Switch:update(dt)
    Drawable.update(self, dt)

    local disabled = self.disabled == true
    ControlUtils.set_interaction_state(self, not disabled)

    if disabled then
        self._dragging = false
        self._drag_dx = 0
        self._last_drag_dx = 0
    end

    local track = self.track
    local thumb = self.thumb
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local track_width = math.max(32, math.min(width, 48))
    local track_height = math.max(18, math.min(height, 28))
    local thumb_size = math.max(12, track_height - 6)
    local variant = self:resolveStyleVariant()
    local thumb_x = checked_value(self) and (track_width - thumb_size - 3) or 3

    if track ~= nil then
        track.width = track_width
        track.height = track_height
        track.x = (width - track_width) * 0.5
        track.y = (height - track_height) * 0.5
        track:setStyleVariant(variant)
        track:markDirty()
    end

    if thumb ~= nil then
        thumb.width = thumb_size
        thumb.height = thumb_size
        thumb.x = thumb_x
        thumb.y = (track_height - thumb_size) * 0.5
        thumb:setStyleVariant(variant)
        thumb:markDirty()
    end

    return self
end

function Switch:on_destroy()
    ControlUtils.remove_control_listeners(self)
    Container.on_destroy(self)
end

return Switch
