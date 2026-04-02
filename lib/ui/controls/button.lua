local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local ControlUtils = require('lib.ui.controls.control_utils')

local Button = Drawable:extends('Button')

local function effective_disabled(self)
    return rawget(self, 'disabled') == true
end

local function set_pressed(self, value)
    value = value == true

    local controlled = rawget(self, '_pressed_controlled') == true
    if controlled then
        local on_change = rawget(self, 'onPressedChange')
        ControlUtils.call_if_function(on_change, value)
        return
    end

    rawset(self, '_pressed_uncontrolled', value)
end

local function get_pressed(self)
    if rawget(self, '_pressed_controlled') then
        return rawget(self, 'pressed') == true
    end
    return rawget(self, '_pressed_uncontrolled') == true
end

function Button:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = true,
    })
    Drawable.constructor(self, drawable_opts)
    rawset(self, 'pointerFocusCoupling', 'before')

    rawset(self, '_ui_button_control', true)

    rawset(self, 'pressed', opts.pressed)
    rawset(self, 'onPressedChange', opts.onPressedChange)
    rawset(self, 'onActivate', opts.onActivate)
    rawset(self, 'disabled', opts.disabled == true)
    rawset(self, '_pressed_controlled', opts.pressed ~= nil)
    rawset(self, '_pressed_uncontrolled', false)
    rawset(self, '_hovered', false)
    rawset(self, '_pressing_pointer', false)

    ControlUtils.assert_controlled_pair('pressed', opts.pressed, 'onPressedChange', opts.onPressedChange, 2)

    local content = Container({
        tag = 'button_content',
        width = 'fill',
        height = 'fill',
        interactive = false,
    })
    Container.addChild(self, content)
    rawset(self, '_content_slot', content)

    if opts.content ~= nil then
        self:_set_content_internal(opts.content)
    end

    rawset(self, 'surface', self)
    rawset(self, 'border', self)
    rawset(self, '_last_visual_variant', self:_resolve_visual_variant())

    self:_add_event_listener('ui.activate', function(event)
        if rawget(self, '_destroyed') then return end
        if effective_disabled(self) then return end

        if event.defaultPrevented then
            return
        end

        set_pressed(self, false)
        ControlUtils.call_if_function(rawget(self, 'onActivate'), self, event)
    end)

    self:_add_event_listener('ui.drag', function(event)
        if rawget(self, '_destroyed') then return end
        if effective_disabled(self) then return end

        if event.dragPhase == 'start' then
            rawset(self, '_pressing_pointer', true)
            set_pressed(self, true)
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'move' then
            local inside = self:containsPoint(event.x, event.y)
            set_pressed(self, inside)
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'end' then
            rawset(self, '_pressing_pointer', false)
            set_pressed(self, false)
            event:stopPropagation()
            return
        end
    end)
end

function Button.new(opts)
    return Button(opts)
end

function Button:_set_content_internal(node)
    if node == nil then
        return self
    end

    Assert.table('node', node, 2)
    local slot = rawget(self, '_content_slot')
    local children = rawget(slot, '_children') or {}
    for i = #children, 1, -1 do
        slot:removeChild(children[i])
    end
    slot:addChild(node)
    return self
end

function Button:_is_pressed()
    return get_pressed(self)
end

function Button:_resolve_visual_variant()
    if rawget(self, 'disabled') == true then
        return 'disabled'
    end

    if get_pressed(self) then
        return 'pressed'
    end

    if rawget(self, '_hovered') == true then
        return 'hovered'
    end

    if rawget(self, '_focused') == true then
        return 'focused'
    end

    return 'base'
end

function Button:update(dt)
    Drawable.update(self, dt)

    local disabled = effective_disabled(self)
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
        rawset(self, '_hovered', false)
        rawset(self, '_pressing_pointer', false)
        if not rawget(self, '_pressed_controlled') then
            rawset(self, '_pressed_uncontrolled', false)
        end
        return self
    end

    if love ~= nil and love.mouse ~= nil and Types.is_function(love.mouse.getPosition) then
        local mx, my = love.mouse.getPosition()
        rawset(self, '_hovered', self:containsPoint(mx, my))
    else
        rawset(self, '_hovered', false)
    end

    local variant = self:_resolve_visual_variant()
    local previous = rawget(self, '_last_visual_variant')
    if previous ~= nil and previous ~= variant then
        self:_raise_motion('state-change', {
            defaultTarget = 'surface',
            previousValue = previous,
            nextValue = variant,
        })
    end
    rawset(self, '_last_visual_variant', variant)

    return self
end

return Button
