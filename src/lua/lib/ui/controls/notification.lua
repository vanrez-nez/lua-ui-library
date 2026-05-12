local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local Button = require('lib.ui.controls.button')
local Control = require('lib.ui.controls.control')
local Assert = require('lib.ui.utils.assert')
local Schema = require('lib.ui.utils.schema')
local Constants = require('lib.ui.core.constants')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')
local StyleScope = require('lib.ui.render.style_scope')
local NotificationSchema = require('lib.ui.controls.notification_schema')

local Notification = Control:extends('Notification')
local enum_has = Enum.enum_has
local NOTIFICATION_SURFACE_SCOPE = StyleScope.create('notification', 'surface')

Notification.schema = Schema.extend(Control.schema, NotificationSchema)

local function effective_open(self)
    if self._open_controlled then
        return self.open == true
    end
    return self._open_uncontrolled == true
end

local function request_open_change(self, next_value)
    next_value = next_value == true
    if not self._open_controlled then
        self._open_uncontrolled = next_value
    end
    Control.call_if_function(self.onOpenChange, next_value)
end

local function effective_duration(self)
    local duration = self.duration
    if self.closeMethod == 'auto-dismiss' and duration == nil then
        return 5000
    end
    return duration
end

local function axis_group_key(self)
    return table.concat({
        self.edge,
        self.align,
        tostring(self.safeAreaAware),
    }, ':')
end

local function collect_notification_surfaces(stage, group_key, out)
    local children = stage.overlayLayer._children
    for index = 1, #children do
        local child = children[index]
        local owner = child._ui_notification_owner
        if owner ~= nil and
            effective_open(owner) and
            axis_group_key(owner) == group_key and
            owner.stackable == true then
            out[#out + 1] = owner
        end
    end
    return out
end

local function position_surface(self, stage)
    local viewport = self.safeAreaAware and stage:getSafeAreaBounds() or stage:getViewport()
    local surface = self.surface
    local surface_width = surface:getLocalBounds().width
    local surface_height = surface:getLocalBounds().height
    local margin = 12

    local x = viewport.x + margin
    local y = viewport.y + margin

    if self.edge == Constants.EDGE_BOTTOM then
        y = viewport.y + viewport.height - surface_height - margin
    elseif self.edge == Constants.EDGE_RIGHT then
        x = viewport.x + viewport.width - surface_width - margin
    end

    if self.edge == Constants.EDGE_TOP or self.edge == Constants.EDGE_BOTTOM then
        if self.align == Constants.ALIGN_CENTER then
            x = viewport.x + (viewport.width - surface_width) * 0.5
        elseif self.align == Constants.ALIGN_END then
            x = viewport.x + viewport.width - surface_width - margin
        end
    else
        if self.align == Constants.ALIGN_CENTER then
            y = viewport.y + (viewport.height - surface_height) * 0.5
        elseif self.align == Constants.ALIGN_END then
            y = viewport.y + viewport.height - surface_height - margin
        end
    end

    if self.stackable == true then
        local group = collect_notification_surfaces(stage, axis_group_key(self), {})
        local offset = 0
        for index = 1, #group do
            if group[index] == self then
                break
            end
            local peer_surface = group[index].surface
            local peer_bounds = peer_surface:getLocalBounds()
            if self.edge == Constants.EDGE_TOP then
                offset = offset + peer_bounds.height + 12
            elseif self.edge == Constants.EDGE_BOTTOM then
                offset = offset + peer_bounds.height + 12
            elseif self.edge == Constants.EDGE_LEFT then
                offset = offset + peer_bounds.width + 12
            else
                offset = offset + peer_bounds.width + 12
            end
        end

        if self.edge == Constants.EDGE_TOP then
            y = y + offset
        elseif self.edge == Constants.EDGE_BOTTOM then
            y = y - offset
        elseif self.edge == Constants.EDGE_LEFT then
            x = x + offset
        else
            x = x - offset
        end
    end

    surface.x = x
    surface.y = y
    surface:markDirty()
end

function Notification:constructor(opts)
    opts = opts or {}
    Assert.table('opts', opts, 2)

    Control.constructor(self, opts, {
        width = 0,
        height = 0,
        visible = false,
        interactive = false,
        focusable = false,
    })
    self.open = opts.open
    self.onOpenChange = opts.onOpenChange
    self.closeMethod = opts.closeMethod or 'button'
    self.duration = opts.duration
    self.stackable = opts.stackable ~= false
    self.edge = opts.edge or Enums.Edge.TOP
    self.align = opts.align or Enums.SourceAlign.CENTER
    self.safeAreaAware = opts.safeAreaAware ~= false

    self._ui_notification_control = true
    self._open_controlled = opts.open ~= nil
    self._open_uncontrolled = opts.open == true
    self._mounted_stage = nil
    self._elapsed_ms = 0
    self._last_open_state = effective_open(self)

    Control.assert_controlled_pair('open', opts.open, 'onOpenChange', opts.onOpenChange, 2)

    if self.closeMethod ~= 'button' and self.closeMethod ~= 'auto-dismiss' then
        Assert.fail('Notification.closeMethod must be "button" or "auto-dismiss"', 2)
    end
    if not enum_has(Enums.Edge, self.edge) then
        Assert.fail('Notification.edge is invalid', 2)
    end
    if not enum_has(Enums.SourceAlign, self.align) then
        Assert.fail('Notification.align is invalid', 2)
    end
    if self.closeMethod == 'auto-dismiss' and effective_duration(self) ~= nil and effective_duration(self) <= 0 then
        Assert.fail('Notification.duration must be > 0 for auto-dismiss', 2)
    end

    local overlay_root = Container.new({
        tag = (self.tag and (self.tag .. '.overlay')) or 'notification.overlay',
        internal = true,
        width = 'fill',
        height = 'fill',
        interactive = false,
        focusable = false,
    })
    Container._allow_fill_from_parent(overlay_root, { width = true, height = true })
    overlay_root._ui_notification_owner = self
    local surface = Drawable.new({
        tag = (self.tag and (self.tag .. '.surface')) or 'notification.surface',
        internal = true,
        width = 280,
        height = 96,
        interactive = true,
        focusable = false,
        style_scope = NOTIFICATION_SURFACE_SCOPE,
    })
    local content = Container.new({
        tag = (self.tag and (self.tag .. '.content')) or 'notification.content',
        internal = true,
        width = 'fill',
        height = 'fill',
        interactive = false,
        focusable = false,
    })
    Container._allow_fill_from_parent(content, { width = true, height = true })
    Container._allow_child_fill(content, { width = true, height = true })
    overlay_root:addChild(surface)
    surface:addChild(content)

    self._overlay_root = overlay_root
    self.root = overlay_root
    self.surface = surface
    self.content = content

    if opts.content ~= nil then
        content:addChild(opts.content)
    end

    if self.closeMethod == 'button' then
        local close_control = Button.new({
            tag = (self.tag and (self.tag .. '.close')) or 'notification.close',
            internal = true,
            width = 28,
            height = 28,
            onActivate = function()
                request_open_change(self, false)
            end,
        })
        surface:addChild(close_control)
        self.closeControl = close_control
    end
end

function Notification.new(opts)
    return Notification(opts)
end

function Notification:addChild(child)
    return self.content:addChild(child)
end

function Notification:removeChild(child)
    return self.content:removeChild(child)
end

function Notification:update(dt)
    Container.update(self, dt)

    local wants_open = effective_open(self)
    local stage = self:findStage()
    local was_open = self._last_open_state

    if wants_open and stage ~= nil then
        self:_attach_overlay(stage)
        position_surface(self, stage)
        if not was_open then
            self._elapsed_ms = 0
            self:_raise_motion('enter', { defaultTarget = 'surface' })
        else
            self:_raise_motion('reflow', { defaultTarget = 'surface' })
        end
    else
        if self._mounted_stage ~= nil then
            self:_detach_overlay()
        end
        if was_open and not wants_open then
            self:_raise_motion('exit', { defaultTarget = 'surface' })
        end
        self._elapsed_ms = 0
    end

    if wants_open and self.closeMethod == 'auto-dismiss' then
        self._elapsed_ms = self._elapsed_ms + ((dt or 0) * 1000)
        local duration = effective_duration(self)
        if duration ~= nil and self._elapsed_ms >= duration then
            request_open_change(self, false)
        end
    end

    self._last_open_state = wants_open
    return self
end

function Notification:on_destroy()
    self:removeControlListeners()
    self:_detach_overlay()
    self._overlay_root:destroy()
    Container.on_destroy(self)
end

return Notification
