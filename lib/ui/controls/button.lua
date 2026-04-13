local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local ControlUtils = require('lib.ui.controls.control_utils')
local Rule = require('lib.ui.utils.rule')

local Button = Drawable:extends('Button')

local ButtonSchema = {
    pressed = Rule.boolean(),
    onPressedChange = Rule.any(),
    onActivate = Rule.any(),
    disabled = Rule.boolean(false),
}

Button._schema = ControlUtils.extend_schema(Drawable._schema, ButtonSchema)

local function effective_disabled(self)
    return self.disabled == true
end

local function set_pressed(self, value)
    value = value == true

    local controlled = self._pressed_controlled == true
    if controlled then
        local on_change = self.onPressedChange
        ControlUtils.call_if_function(on_change, value)
        return
    end

    self._pressed_uncontrolled = value
end

local function get_pressed(self)
    if self._pressed_controlled then
        return self.pressed == true
    end
    return self._pressed_uncontrolled == true
end

function Button:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = true,
    })
    Drawable.constructor(self, drawable_opts)
    self.schema:define(ButtonSchema)
    self.pressed = opts.pressed
    self.onPressedChange = opts.onPressedChange
    self.onActivate = opts.onActivate
    self.disabled = opts.disabled == true
    self.pointerFocusCoupling = 'before'

    self._ui_button_control = true

    self._pressed_controlled = opts.pressed ~= nil
    self._pressed_uncontrolled = false
    self._hovered = false
    self._pressing_pointer = false

    ControlUtils.assert_controlled_pair('pressed', opts.pressed, 'onPressedChange', opts.onPressedChange, 2)

    local content = Container({
        tag = 'button_content',
        internal = true,
        width = 'fill',
        height = 'fill',
        interactive = false,
    })
    Container._allow_fill_from_parent(content, { width = true, height = true })
    Container._allow_child_fill(content, { width = true, height = true })
    Container.addChild(self, content)
    self._content_slot = content

    if opts.content ~= nil then
        self:_set_content_internal(opts.content)
    end

    self.surface = self
    self.border = self
    self._styling_context = {
        component = 'button',
        part = 'surface',
    }
    self._last_visual_variant = self:_resolve_visual_variant()

    ControlUtils.add_control_listener(self, self, 'ui.activate', function(event)
        if effective_disabled(self) then return end

        if event.defaultPrevented then
            return
        end

        set_pressed(self, false)
        ControlUtils.call_if_function(self.onActivate, self, event)
    end)

    ControlUtils.add_control_listener(self, self, 'ui.drag', function(event)
        if effective_disabled(self) then return end

        if event.dragPhase == 'start' then
            self._pressing_pointer = true
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
            self._pressing_pointer = false
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
    local slot = self._content_slot
    local children = slot._children
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
    if self.disabled == true then
        return 'disabled'
    end

    if get_pressed(self) then
        return 'pressed'
    end

    if self._hovered == true then
        return 'hovered'
    end

    if self._focused == true then
        return 'focused'
    end

    return 'base'
end

function Button:update(dt)
    Drawable.update(self, dt)

    local disabled = effective_disabled(self)
    ControlUtils.set_interaction_state(self, not disabled)

    if disabled then
        self._hovered = false
        self._pressing_pointer = false
        if not self._pressed_controlled then
            self._pressed_uncontrolled = false
        end
        return self
    end

    if love ~= nil and love.mouse ~= nil and Types.is_function(love.mouse.getPosition) then
        local mx, my = love.mouse.getPosition()
        self._hovered = self:containsPoint(mx, my)
    else
        self._hovered = false
    end

    local variant = self:_resolve_visual_variant()
    local previous = self._last_visual_variant
    if previous ~= nil and previous ~= variant then
        self:_raise_motion('state-change', {
            defaultTarget = 'surface',
            previousValue = previous,
            nextValue = variant,
        })
    end
    self._last_visual_variant = variant

    return self
end

function Button:on_destroy()
    ControlUtils.remove_control_listeners(self)
    Container.on_destroy(self)
end

return Button
