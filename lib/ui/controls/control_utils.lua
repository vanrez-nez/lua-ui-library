local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Container = require('lib.ui.core.container')

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
    local ev = rawget(node, '_effective_values') or {}
    return ev.disabled == true or ev.enabled == false
end

return Utils
