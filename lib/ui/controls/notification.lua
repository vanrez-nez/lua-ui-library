local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local Button = require('lib.ui.controls.button')
local ControlUtils = require('lib.ui.controls.control_utils')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')

local Notification = Container:extends('Notification')

local NotificationSchema = {
    open = Rule.boolean(),
    onOpenChange = Rule.any(),
    closeMethod = Rule.any({ default = 'button' }),
    duration = Rule.number(),
    stackable = Rule.boolean(true),
    edge = Rule.any({ default = 'top' }),
    align = Rule.any({ default = 'center' }),
    safeAreaAware = Rule.boolean(true),
}

Notification._schema = ControlUtils.extend_schema(Container._schema, NotificationSchema)
Notification:implements(ControlUtils.overlay_mixin)

local function effective_open(self)
    if rawget(self, '_open_controlled') then
        return self.open == true
    end
    return rawget(self, '_open_uncontrolled') == true
end

local function request_open_change(self, next_value)
    next_value = next_value == true
    if not rawget(self, '_open_controlled') then
        rawset(self, '_open_uncontrolled', next_value)
    end
    ControlUtils.call_if_function(self.onOpenChange, next_value)
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
    local children = rawget(stage.overlayLayer, '_children')
    for index = 1, #children do
        local child = children[index]
        local owner = rawget(child, '_ui_notification_owner')
        if owner ~= nil and effective_open(owner) and axis_group_key(owner) == group_key and owner.stackable == true then
            out[#out + 1] = owner
        end
    end
    return out
end

local function position_surface(self, stage)
    local viewport = self.safeAreaAware and stage:getSafeAreaBounds() or stage:getViewport()
    local surface = rawget(self, 'surface')
    local surface_width = surface:getLocalBounds().width
    local surface_height = surface:getLocalBounds().height
    local margin = 12

    local x = viewport.x + margin
    local y = viewport.y + margin

    if self.edge == 'bottom' then
        y = viewport.y + viewport.height - surface_height - margin
    elseif self.edge == 'right' then
        x = viewport.x + viewport.width - surface_width - margin
    end

    if self.edge == 'top' or self.edge == 'bottom' then
        if self.align == 'center' then
            x = viewport.x + (viewport.width - surface_width) * 0.5
        elseif self.align == 'end' then
            x = viewport.x + viewport.width - surface_width - margin
        end
    else
        if self.align == 'center' then
            y = viewport.y + (viewport.height - surface_height) * 0.5
        elseif self.align == 'end' then
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
            local peer_surface = rawget(group[index], 'surface')
            local peer_bounds = peer_surface:getLocalBounds()
            if self.edge == 'top' then
                offset = offset + peer_bounds.height + 12
            elseif self.edge == 'bottom' then
                offset = offset + peer_bounds.height + 12
            elseif self.edge == 'left' then
                offset = offset + peer_bounds.width + 12
            else
                offset = offset + peer_bounds.width + 12
            end
        end

        if self.edge == 'top' then
            y = y + offset
        elseif self.edge == 'bottom' then
            y = y - offset
        elseif self.edge == 'left' then
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

    local base_opts = ControlUtils.base_opts(opts, {
        width = 0,
        height = 0,
        visible = false,
        interactive = false,
        focusable = false,
    })

    Container.constructor(self, base_opts)
    self.schema:define(NotificationSchema)
    self.open = opts.open
    self.onOpenChange = opts.onOpenChange
    self.closeMethod = opts.closeMethod or 'button'
    self.duration = opts.duration
    self.stackable = opts.stackable ~= false
    self.edge = opts.edge or 'top'
    self.align = opts.align or 'center'
    self.safeAreaAware = opts.safeAreaAware ~= false

    rawset(self, '_ui_notification_control', true)
    rawset(self, '_open_controlled', opts.open ~= nil)
    rawset(self, '_open_uncontrolled', opts.open == true)
    rawset(self, '_mounted_stage', nil)
    rawset(self, '_elapsed_ms', 0)
    rawset(self, '_last_open_state', effective_open(self))

    ControlUtils.assert_controlled_pair('open', opts.open, 'onOpenChange', opts.onOpenChange, 2)

    if self.closeMethod ~= 'button' and self.closeMethod ~= 'auto-dismiss' then
        Assert.fail('Notification.closeMethod must be "button" or "auto-dismiss"', 2)
    end
    if self.edge ~= 'top' and self.edge ~= 'bottom' and self.edge ~= 'left' and self.edge ~= 'right' then
        Assert.fail('Notification.edge is invalid', 2)
    end
    if self.align ~= 'start' and self.align ~= 'center' and self.align ~= 'end' then
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
    rawset(overlay_root, '_ui_notification_owner', self)
    local surface = Drawable.new({
        tag = (self.tag and (self.tag .. '.surface')) or 'notification.surface',
        internal = true,
        width = 280,
        height = 96,
        interactive = true,
        focusable = false,
    })
    rawset(surface, '_styling_context', {
        component = 'notification',
        part = 'surface',
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

    rawset(self, '_overlay_root', overlay_root)
    rawset(self, 'root', overlay_root)
    rawset(self, 'surface', surface)
    rawset(self, 'content', content)

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
        rawset(self, 'closeControl', close_control)
    end
end

function Notification.new(opts)
    return Notification(opts)
end

function Notification:addChild(child)
    return rawget(self, 'content'):addChild(child)
end

function Notification:removeChild(child)
    return rawget(self, 'content'):removeChild(child)
end

function Notification:update(dt)
    Container.update(self, dt)

    local wants_open = effective_open(self)
    local stage = ControlUtils.find_stage(self)
    local was_open = rawget(self, '_last_open_state')

    if wants_open and stage ~= nil then
        self:_attach_overlay(stage)
        position_surface(self, stage)
        if not was_open then
            rawset(self, '_elapsed_ms', 0)
            self:_raise_motion('enter', { defaultTarget = 'surface' })
        else
            self:_raise_motion('reflow', { defaultTarget = 'surface' })
        end
    else
        if rawget(self, '_mounted_stage') ~= nil then
            self:_detach_overlay()
        end
        if was_open and not wants_open then
            self:_raise_motion('exit', { defaultTarget = 'surface' })
        end
        rawset(self, '_elapsed_ms', 0)
    end

    if wants_open and self.closeMethod == 'auto-dismiss' then
        rawset(self, '_elapsed_ms', rawget(self, '_elapsed_ms') + ((dt or 0) * 1000))
        local duration = effective_duration(self)
        if duration ~= nil and rawget(self, '_elapsed_ms') >= duration then
            request_open_change(self, false)
        end
    end

    rawset(self, '_last_open_state', wants_open)
    return self
end

function Notification:on_destroy()
    ControlUtils.remove_control_listeners(self)
    self:_detach_overlay()
    rawget(self, '_overlay_root'):destroy()
    Container.on_destroy(self)
end

return Notification
