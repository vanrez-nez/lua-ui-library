local Assert = require('lib.ui.utils.assert')
local Drawable = require('lib.ui.core.drawable')
local Schema = require('lib.ui.utils.schema')
local Types = require('lib.ui.utils.types')
local ControlSchema = require('lib.ui.controls.control_schema')

local Control = Drawable:extends('Control')

Control.schema = Schema.extend(Drawable.schema, ControlSchema.rules)

function Control:constructor(opts, defaults)
    opts = opts or {}
    local effective_opts = {}

    for key, value in pairs(opts) do
        effective_opts[key] = value
    end

    if defaults ~= nil then
        for key, value in pairs(defaults) do
            if effective_opts[key] == nil then
                effective_opts[key] = value
            end
        end
    end

    Drawable.constructor(self, effective_opts)
    self._ui_control_instance = true
end

function Control.new(opts)
    return Control(opts)
end

function Control.assert_controlled_pair(value_name, value, callback_name, callback, level)
    if value ~= nil and not Types.is_function(callback) then
        Assert.fail(
            tostring(value_name) .. ' without ' .. tostring(callback_name) ..
                ' when ' .. tostring(value_name) .. ' is intended to be mutable',
            level or 2
        )
    end
end

function Control.call_if_function(fn, ...)
    if Types.is_function(fn) then
        return fn(...)
    end
    return nil
end

function Control.controlled_value(prop_name, default_value, config)
    config = config or {}
    local callback_name = config.callback or 'onValueChange'
    local controlled_key = config.controlled_key or ('_' .. prop_name .. '_controlled')
    local internal_key = config.internal_key or ('_' .. prop_name .. '_uncontrolled')
    local normalize = config.normalize

    local function fallback(self)
        if Types.is_function(default_value) then
            return default_value(self)
        end
        return default_value
    end

    local function coerce(self, value)
        if value == nil then
            value = fallback(self)
        end
        if normalize ~= nil then
            return normalize(self, value)
        end
        return value
    end

    local function get_effective(self)
        local current
        if self[controlled_key] then
            current = self[prop_name]
        else
            current = self[internal_key]
            if current == nil then
                current = rawget(self, internal_key)
            end
        end
        return coerce(self, current)
    end

    local function request(self, next_value)
        next_value = coerce(self, next_value)
        if self[controlled_key] then
            Control.call_if_function(self[callback_name], next_value)
            return next_value
        end

        self[internal_key] = next_value
        local mark_dirty = self.markDirty
        if Types.is_function(mark_dirty) then
            mark_dirty(self)
        end
        Control.call_if_function(self[callback_name], next_value)
        return next_value
    end

    return get_effective, request
end

function Control:findStage()
    local current = self
    while current ~= nil do
        if current._ui_stage_instance == true then
            return current
        end
        current = current.parent
    end
    return self[self._overlay_mounted_stage_key or '_mounted_stage']
end

function Control:stageFocusOwner()
    local stage = self:findStage()
    if stage == nil then
        return nil
    end
    return stage._focus_owner
end

function Control:requestFocus(node)
    local stage = self:findStage()
    if stage == nil and node ~= nil and node ~= self then
        local current = node
        while current ~= nil do
            if current._ui_stage_instance == true then
                stage = current
                break
            end
            current = current.parent
        end
    end

    if stage == nil then
        return nil
    end

    local request = stage._request_focus_internal
    if Types.is_function(request) then
        request(stage, node or self)
    end
    return stage
end

function Control:clearFocus()
    local stage = self:findStage()
    if stage == nil then
        return nil
    end

    local request = stage._request_focus_internal
    if Types.is_function(request) then
        request(stage, nil)
    end
    return stage
end

function Control:addControlListener(target, event_type, listener, phase)
    Assert.table('target', target, 2)
    if not Types.is_function(listener) then
        Assert.fail('listener must be a function', 2)
    end

    target:_add_event_listener(event_type, listener, phase)

    local registrations = self._control_listener_registrations
    if registrations == nil then
        registrations = {}
        self._control_listener_registrations = registrations
    end

    registrations[#registrations + 1] = {
        target = target,
        event_type = event_type,
        listener = listener,
        phase = phase,
    }

    return listener
end

function Control:removeControlListeners()
    local registrations = self._control_listener_registrations or {}
    for index = #registrations, 1, -1 do
        local registration = registrations[index]
        local target = registration.target
        if target ~= nil then
            target:_remove_event_listener(
                registration.event_type,
                registration.listener,
                registration.phase
            )
        end
        registrations[index] = nil
    end
end

function Control.set_interaction_state(node, enabled)
    enabled = enabled == true
    rawset(node, 'enabled', enabled)
    rawset(node, 'interactive', enabled)
    rawset(node, 'focusable', enabled)
end

function Control:setInteractionState(enabled)
    Control.set_interaction_state(self, enabled)
end

function Control.coerce_to_node(value, fallback_tag)
    if value == nil then
        return nil
    end

    if Types.is_string(value) then
        if love == nil or love.graphics == nil or
            not Types.is_function(love.graphics.newFont) then
            local Column = require('lib.ui.layout.column')
            local placeholder = Column.new({
                tag = fallback_tag,
                internal = true,
                width = 0,
                height = 0,
                interactive = false,
                focusable = false,
            })

            placeholder.text = value
            return placeholder
        end

        local Text = require('lib.ui.controls.text')
        return Text.new({
            tag = fallback_tag,
            internal = true,
            text = value,
            width = 0,
            wrap = true,
        })
    end

    if Types.is_table(value) and value._ui_container_instance == true then
        return value
    end

    Assert.fail('slot content must be a string, node, or nil', 2)
end

function Control:_get_overlay_root()
    return self[self._overlay_root_key or '_overlay_root']
end

function Control:_overlay_focus_contract() -- luacheck: ignore self
    return nil
end

function Control:_attach_overlay(stage)
    local overlay_root = self:_get_overlay_root()
    if overlay_root == nil or stage == nil then
        return self
    end

    if overlay_root.parent ~= stage.overlayLayer then
        stage.overlayLayer:addChild(overlay_root)
    end

    local contract = self:_overlay_focus_contract(stage)
    if contract ~= nil then
        stage:_set_focus_contract_internal(overlay_root, contract)
    end

    self[self._overlay_mounted_stage_key or '_mounted_stage'] = stage

    local on_opened = self._handle_overlay_opened_internal
    if Types.is_function(on_opened) then
        on_opened(self, stage)
    end

    return self
end

function Control:_detach_overlay()
    local mounted_stage = self[self._overlay_mounted_stage_key or '_mounted_stage']
    local overlay_root = self:_get_overlay_root()

    local before_detach = self._before_overlay_detach
    if Types.is_function(before_detach) then
        before_detach(self, mounted_stage, overlay_root)
    elseif mounted_stage ~= nil and overlay_root ~= nil then
        mounted_stage:_set_focus_contract_internal(overlay_root, nil)
    end

    if overlay_root ~= nil and overlay_root.parent ~= nil then
        overlay_root.parent:removeChild(overlay_root)
    end

    self[self._overlay_mounted_stage_key or '_mounted_stage'] = nil
    return self
end

return Control
