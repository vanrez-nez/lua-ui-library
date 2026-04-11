local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Container = require('lib.ui.core.container')
local Proxy = require('lib.ui.utils.proxy')
local Rule = require('lib.ui.utils.rule')
local Common = require('lib.ui.utils.common')

local Utils = {}

local BASE_KEYS = {
    tag = true,
    visible = true,
    interactive = true,
    enabled = true,
    focusable = true,
    clipChildren = true,
    zIndex = true,
    anchorX = true,
    anchorY = true,
    pivotX = true,
    pivotY = true,
    x = true,
    y = true,
    width = true,
    height = true,
    minWidth = true,
    minHeight = true,
    maxWidth = true,
    maxHeight = true,
    scaleX = true,
    scaleY = true,
    rotation = true,
    skewX = true,
    skewY = true,
    breakpoints = true,
    padding = true,
    alignX = true,
    alignY = true,
    responsive = true,
    skin = true,
    shader = true,
    opacity = true,
    blendMode = true,
    mask = true,
    motionPreset = true,
    motion = true,
}

function Utils.base_opts(opts, defaults)
    opts = opts or {}
    local out = {}

    if defaults ~= nil then
        for key, value in pairs(defaults) do
            out[key] = value
        end
    end

    for key, value in pairs(opts) do
        if BASE_KEYS[key] then
            out[key] = value
        end
    end

    return out
end

function Utils.assert_controlled_pair(value_name, value, callback_name, callback, level)
    if value ~= nil and not Types.is_function(callback) then
        Assert.fail(
            tostring(value_name) .. ' without ' .. tostring(callback_name) ..
                ' when ' .. tostring(value_name) .. ' is intended to be mutable',
            level or 2
        )
    end
end

function Utils.find_stage(node)
    local current = node
    while current ~= nil do
        if rawget(current, '_ui_stage_instance') == true then
            return current
        end
        current = rawget(current, 'parent')
    end
    return nil
end

function Utils.stage_focus_owner(node)
    local stage = Utils.find_stage(node)
    if stage == nil then
        return nil
    end
    return rawget(stage, '_focus_owner')
end

function Utils.request_focus(node)
    local stage = Utils.find_stage(node)
    if stage == nil then
        return nil
    end

    local req = rawget(stage, '_request_focus_internal') or stage._request_focus_internal
    if Types.is_function(req) then
        req(stage, node)
    end
    return stage
end

function Utils.clear_focus(node)
    local stage = Utils.find_stage(node)
    if stage == nil then
        return nil
    end

    local req = rawget(stage, '_request_focus_internal') or stage._request_focus_internal
    if Types.is_function(req) then
        req(stage, nil)
    end
    return stage
end

function Utils.call_if_function(fn, ...)
    if Types.is_function(fn) then
        return fn(...)
    end
    return nil
end

function Utils.is_disabled(node)
    return node.disabled == true or node.enabled == false
end

function Utils.extend_schema(base, overrides)
    return Common.merge_tables(Common.copy_table(base or {}), overrides or {})
end

function Utils.validate_control_schema(instance, opts, schema, level)
    opts = opts or {}
    for key, rule in pairs(schema or {}) do
        Rule.validate(rule, key, opts[key], instance, level or 2, opts)
    end
end

function Utils.controlled_value(prop_name, default_value, config)
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
        if rawget(self, controlled_key) then
            current = self[prop_name]
        else
            current = rawget(self, internal_key)
            if current == nil then
                current = Proxy.raw_get(self, internal_key)
            end
        end
        return coerce(self, current)
    end

    local function request(self, next_value)
        next_value = coerce(self, next_value)
        if rawget(self, controlled_key) then
            Utils.call_if_function(self[callback_name], next_value)
            return next_value
        end

        rawset(self, internal_key, next_value)
        local props = rawget(self, 'props')
        if props ~= nil and Types.is_function(props.raw_set) then
            props:raw_set(internal_key, next_value)
        end
        local mark_dirty = rawget(self, 'markDirty') or self.markDirty
        if Types.is_function(mark_dirty) and rawget(self, '_destroyed') ~= true then
            mark_dirty(self)
        end
        Utils.call_if_function(self[callback_name], next_value)
        return next_value
    end

    return get_effective, request
end

function Utils._destroyed_guard(owner, fn)
    if not Types.is_function(fn) then
        Assert.fail('listener must be a function', 2)
    end

    return function(...)
        if rawget(owner, '_destroyed') then
            return nil
        end
        return fn(...)
    end
end

function Utils.add_control_listener(owner, target, event_type, listener, phase)
    Assert.table('target', target, 2)
    local guarded = Utils._destroyed_guard(owner, listener)
    target:_add_event_listener(event_type, guarded, phase)

    local registrations = rawget(owner, '_control_listener_registrations')
    if registrations == nil then
        registrations = {}
        rawset(owner, '_control_listener_registrations', registrations)
    end

    registrations[#registrations + 1] = {
        target = target,
        event_type = event_type,
        listener = guarded,
        phase = phase,
    }

    return guarded
end

function Utils.remove_control_listeners(owner)
    local registrations = rawget(owner, '_control_listener_registrations') or {}
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

function Utils.set_interaction_state(node, enabled)
    enabled = enabled == true
    Proxy.raw_set(node, 'enabled', enabled)
    Proxy.raw_set(node, 'interactive', enabled)
    Proxy.raw_set(node, 'focusable', enabled)
end

Utils.overlay_mixin = {
    _overlay_root_key = '_overlay_root',
    _overlay_mounted_stage_key = '_mounted_stage',
}

function Utils.overlay_mixin:_get_overlay_root()
    return rawget(self, rawget(self, '_overlay_root_key') or self._overlay_root_key or '_overlay_root')
end

function Utils.overlay_mixin:_overlay_focus_contract()
    return nil
end

function Utils.overlay_mixin:_attach_overlay(stage)
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

    rawset(self, rawget(self, '_overlay_mounted_stage_key') or self._overlay_mounted_stage_key or '_mounted_stage', stage)

    local on_opened = rawget(self, '_handle_overlay_opened_internal') or
        self._handle_overlay_opened_internal
    if Types.is_function(on_opened) then
        on_opened(self, stage)
    end

    return self
end

function Utils.overlay_mixin:_detach_overlay()
    local mounted_stage = rawget(self, rawget(self, '_overlay_mounted_stage_key') or self._overlay_mounted_stage_key or '_mounted_stage')
    local overlay_root = self:_get_overlay_root()

    local before_detach = rawget(self, '_before_overlay_detach') or self._before_overlay_detach
    if Types.is_function(before_detach) then
        before_detach(self, mounted_stage, overlay_root)
    elseif mounted_stage ~= nil and overlay_root ~= nil then
        mounted_stage:_set_focus_contract_internal(overlay_root, nil)
    end

    if overlay_root ~= nil and overlay_root.parent ~= nil then
        overlay_root.parent:removeChild(overlay_root)
    end

    rawset(self, rawget(self, '_overlay_mounted_stage_key') or self._overlay_mounted_stage_key or '_mounted_stage', nil)
    return self
end

return Utils
