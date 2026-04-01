local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Row = require('lib.ui.layout.row')
local Column = require('lib.ui.layout.column')
local ScrollableContainer = require('lib.ui.scroll.scrollable_container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local ControlUtils = require('lib.ui.controls.control_utils')

local Tabs = Drawable:extends('Tabs')

local function normalize_disabled_values(values)
    if values == nil then
        return {}
    end

    Assert.table('disabledValues', values, 3)
    local map = {}
    for i = 1, #values do
        map[tostring(values[i])] = true
    end
    return map
end

local function trigger_is_disabled(self, value)
    local disabled_map = rawget(self, '_disabled_map') or {}
    return disabled_map[tostring(value)] == true
end

local function ordered_enabled_values(self)
    local order = rawget(self, '_trigger_order') or {}
    local out = {}
    for i = 1, #order do
        local v = order[i]
        if not trigger_is_disabled(self, v) then
            out[#out + 1] = v
        end
    end
    return out
end

local function find_fallback_value(self)
    local values = ordered_enabled_values(self)
    if #values == 0 then
        return nil
    end
    return values[1]
end

local function is_value_mapped(self, value)
    if value == nil then return false end
    local triggers = rawget(self, '_trigger_nodes') or {}
    local panels = rawget(self, '_panel_nodes') or {}
    return triggers[value] ~= nil and panels[value] ~= nil
end

local function effective_value(self)
    local controlled = rawget(self, '_value_controlled') == true
    local current = controlled and rawget(self, 'value') or rawget(self, '_value_uncontrolled')

    if current ~= nil and is_value_mapped(self, current) and not trigger_is_disabled(self, current) then
        return current
    end

    return find_fallback_value(self)
end

local function request_value(self, value)
    if rawget(self, '_value_controlled') then
        ControlUtils.call_if_function(rawget(self, 'onValueChange'), value)
        return
    end

    rawset(self, '_value_uncontrolled', value)
    ControlUtils.call_if_function(rawget(self, 'onValueChange'), value)
end

local function find_trigger_value_from_target(self, target)
    local current = target
    while current ~= nil and current ~= self do
        local val = rawget(current, '_tab_trigger_value')
        if val ~= nil then
            return val
        end
        current = rawget(current, 'parent')
    end
    return nil
end

local function sync_visual_state(self)
    local value = effective_value(self)
    rawset(self, '_effective_tab_value', value)

    local triggers = rawget(self, '_trigger_nodes') or {}
    local panels = rawget(self, '_panel_nodes') or {}

    for key, node in pairs(triggers) do
        local disabled = trigger_is_disabled(self, key)
        local active = (value == key)
        local pv = rawget(node, '_public_values')
        local ev = rawget(node, '_effective_values')
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
        rawset(node, '_tab_active', active)
        rawset(node, '_tab_disabled', disabled)
    end

    for key, node in pairs(panels) do
        local active = (value == key)
        local pv = rawget(node, '_public_values')
        local ev = rawget(node, '_effective_values')
        if pv then
            pv.visible = active
            pv.interactive = active
            pv.focusable = active
        end
        if ev then
            ev.visible = active
            ev.interactive = active
            ev.focusable = active
        end
        rawset(node, '_tab_active', active)
    end
end

local function next_focus_value(self, current, direction)
    local values = ordered_enabled_values(self)
    if #values == 0 then
        return nil
    end

    local idx = nil
    for i = 1, #values do
        if values[i] == current then
            idx = i
            break
        end
    end

    if idx == nil then
        return values[1]
    end

    local step = (direction == 'left' or direction == 'up') and -1 or 1
    local next_idx = idx + step

    if next_idx < 1 or next_idx > #values then
        if rawget(self, 'loopFocus') == true then
            if next_idx < 1 then
                next_idx = #values
            else
                next_idx = 1
            end
        else
            return current
        end
    end

    return values[next_idx]
end

local function build_list_layout(orientation)
    if orientation == 'vertical' then
        return Column.new({
            tag = 'tabs_list',
            width = 'fill',
            height = 'content',
            gap = 4,
            align = 'stretch',
            justify = 'start',
        })
    end

    return Row.new({
        tag = 'tabs_list',
        width = 'content',
        height = 'fill',
        gap = 4,
        align = 'stretch',
        justify = 'start',
    })
end

function Tabs:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = false,
    })
    Drawable.constructor(self, drawable_opts)

    rawset(self, '_ui_tabs_control', true)

    rawset(self, 'value', opts.value)
    rawset(self, 'onValueChange', opts.onValueChange)
    rawset(self, 'orientation', opts.orientation or 'horizontal')
    rawset(self, 'activationMode', opts.activationMode or 'manual')
    rawset(self, 'listScrollable', opts.listScrollable == true)
    rawset(self, 'loopFocus', opts.loopFocus ~= false)
    rawset(self, 'disabledValues', opts.disabledValues)

    if self.orientation ~= 'horizontal' and self.orientation ~= 'vertical' then
        Assert.fail('Tabs.orientation must be "horizontal" or "vertical"', 2)
    end

    if self.activationMode ~= 'manual' then
        Assert.fail('activationMode other than "manual" is invalid', 2)
    end

    ControlUtils.assert_controlled_pair('value', opts.value, 'onValueChange', opts.onValueChange, 2)

    rawset(self, '_value_controlled', opts.value ~= nil)
    rawset(self, '_value_uncontrolled', opts.value)
    rawset(self, '_disabled_map', normalize_disabled_values(opts.disabledValues))
    rawset(self, '_trigger_nodes', {})
    rawset(self, '_panel_nodes', {})
    rawset(self, '_trigger_order', {})

    local list_root
    local list_region = build_list_layout(self.orientation)
    if self.listScrollable then
        list_root = ScrollableContainer.new({
            width = 'fill',
            height = 44,
            scrollXEnabled = self.orientation == 'horizontal',
            scrollYEnabled = self.orientation == 'vertical',
            showScrollbars = false,
            momentum = false,
        })
        Container.addChild(self, list_root)
        rawset(self, '_list_root', list_root)
        list_root.content:addChild(list_region)
        rawset(self, '_list_region', list_region)
    else
        list_root = list_region
        if self.orientation == 'vertical' then
            list_root.height = 'content'
        else
            list_root.height = 44
        end
        Container.addChild(self, list_root)
        rawset(self, '_list_root', list_root)
        rawset(self, '_list_region', list_region)
    end

    local panels = Container({ tag = 'tabs_panels', width = 'fill', height = 'fill', y = 52, interactive = false })
    Container.addChild(self, panels)
    rawset(self, '_panels_region', panels)

    self:_add_event_listener('ui.activate', function(event)
        if rawget(self, '_destroyed') then return end

        local val = find_trigger_value_from_target(self, event.target)
        if val == nil then
            return
        end

        if trigger_is_disabled(self, val) then
            return
        end

        request_value(self, val)
        sync_visual_state(self)
        event:stopPropagation()
    end)

    self:_add_event_listener('ui.navigate', function(event)
        if rawget(self, '_destroyed') then return end
        if event.navigationMode ~= 'directional' then return end

        local focus_owner = ControlUtils.stage_focus_owner(self)
        if focus_owner == nil then return end

        local current = find_trigger_value_from_target(self, focus_owner)
        if current == nil then return end

        local orientation = rawget(self, 'orientation')
        if orientation == 'horizontal' and event.direction ~= 'left' and event.direction ~= 'right' then
            return
        end
        if orientation == 'vertical' and event.direction ~= 'up' and event.direction ~= 'down' then
            return
        end

        local next_value = next_focus_value(self, current, event.direction)
        if next_value == nil then
            return
        end

        local trigger = (rawget(self, '_trigger_nodes') or {})[next_value]
        if trigger ~= nil then
            ControlUtils.request_focus(trigger)
            event:preventDefault()
            event:stopPropagation()
        end
    end)
end

function Tabs.new(opts)
    return Tabs(opts)
end

function Tabs:_register_tab(value, trigger_node, panel_node)
    Assert.string('value', value, 2)
    Assert.table('trigger_node', trigger_node, 2)
    Assert.table('panel_node', panel_node, 2)

    local triggers = rawget(self, '_trigger_nodes')
    local panels = rawget(self, '_panel_nodes')

    if triggers[value] ~= nil or panels[value] ~= nil then
        Assert.fail('duplicate trigger values within one Tabs root are invalid', 2)
    end

    local trigger = Drawable({
        tag = 'tabs_trigger_' .. value,
        width = 120,
        height = 40,
        interactive = true,
        focusable = true,
    })
    rawset(trigger, 'pointerFocusCoupling', 'before')
    rawset(trigger, '_tab_trigger_value', value)
    trigger:addChild(trigger_node)

    local panel = Container({
        tag = 'tabs_panel_' .. value,
        width = 'fill',
        height = 'fill',
        interactive = true,
        focusable = false,
    })
    rawset(panel, '_tab_panel_value', value)
    panel:addChild(panel_node)

    rawget(self, '_list_region'):addChild(trigger)
    rawget(self, '_panels_region'):addChild(panel)

    triggers[value] = trigger
    panels[value] = panel
    local order = rawget(self, '_trigger_order')
    order[#order + 1] = value

    if rawget(self, '_value_controlled') == false and rawget(self, '_value_uncontrolled') == nil then
        rawset(self, '_value_uncontrolled', find_fallback_value(self))
    end

    sync_visual_state(self)
    return self
end

function Tabs:update(dt)
    Drawable.update(self, dt)

    rawset(self, '_disabled_map', normalize_disabled_values(rawget(self, 'disabledValues')))

    local value = effective_value(self)
    if rawget(self, '_value_controlled') == false and rawget(self, '_value_uncontrolled') ~= value then
        rawset(self, '_value_uncontrolled', value)
    end

    sync_visual_state(self)
    return self
end

function Tabs:_get_active_value()
    return effective_value(self)
end

return Tabs
