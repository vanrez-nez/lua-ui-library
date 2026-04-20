local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Row = require('lib.ui.layout.row')
local Column = require('lib.ui.layout.column')
local ScrollableContainer = require('lib.ui.scroll.scrollable_container')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')
local Schema = require('lib.ui.utils.schema')
local Enums = require('lib.ui.core.enums')
local Constants = require('lib.ui.core.constants')
local Enum = require('lib.ui.utils.enum')
local StyleScope = require('lib.ui.render.style_scope')
local TabsSchema = require('lib.ui.controls.tabs_schema')

local enum_has = Enum.enum_has

local Tabs = Drawable:extends('Tabs')
local TABS_LIST_SCOPE = StyleScope.create('tabs', 'list')
local TABS_INDICATOR_SCOPE = StyleScope.create('tabs', 'indicator')
local TABS_TRIGGER_SCOPE = StyleScope.create('tabs', 'trigger')
local TABS_PANEL_SCOPE = StyleScope.create('tabs', 'panel')

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
    local disabled_map = self._disabled_map
    return disabled_map[tostring(value)] == true
end

local function ordered_enabled_values(self)
    local order = self._trigger_order
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
    local triggers = self._trigger_nodes
    local panels = self._panel_nodes
    return triggers[value] ~= nil and panels[value] ~= nil
end

local function normalize_tab_value(self, current)
    if current ~= nil and is_value_mapped(self, current) and not trigger_is_disabled(self, current) then
        return current
    end

    return find_fallback_value(self)
end

local effective_value, request_value =
    ControlUtils.controlled_value('value', nil, {
        normalize = normalize_tab_value,
    })

Tabs.schema = Schema.extend(Drawable.schema, TabsSchema)

local function find_trigger_value_from_target(self, target)
    local current = target
    while current ~= nil and current ~= self do
        local val = current._tab_trigger_value
        if val ~= nil then
            return val
        end
        current = current.parent
    end
    return nil
end

local function sync_visual_state(self)
    local value = effective_value(self)
    self._effective_tab_value = value

    local triggers = self._trigger_nodes
    local panels = self._panel_nodes

    for key, node in pairs(triggers) do
        local disabled = trigger_is_disabled(self, key)
        local active = (value == key)
        ControlUtils.set_interaction_state(node, not disabled)
        node._tab_active = active
        node._tab_disabled = disabled
        node:setStyleVariant(self:_resolve_trigger_variant(node))
    end

    for key, node in pairs(panels) do
        local active = (value == key)
        node.props:raw_set('visible', active)
        ControlUtils.set_interaction_state(node, active)
        node._tab_active = active
        node:setStyleVariant(self:_resolve_panel_variant(node))
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

    local step = 1
    if direction == Constants.NAVIGATION_DIRECTION_LEFT or direction == Constants.NAVIGATION_DIRECTION_UP then
        step = -1
    end
    local next_idx = idx + step

    if next_idx < 1 or next_idx > #values then
        if self.loopFocus == true then
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
    if orientation == Enums.Orientation.VERTICAL then
        local list = Column.new({
            tag = 'tabs_list',
            internal = true,
            width = Constants.SIZE_MODE_FILL,
            height = Constants.SIZE_MODE_CONTENT,
            gap = 4,
            align = Constants.ALIGN_STRETCH,
            justify = Constants.ALIGN_START,
        })
        Container._allow_fill_from_parent(list, { width = true })
        return list
    end

    local list = Row.new({
        tag = 'tabs_list',
        internal = true,
        width = Constants.SIZE_MODE_CONTENT,
        height = Constants.SIZE_MODE_FILL,
        gap = 4,
        align = Constants.ALIGN_STRETCH,
        justify = Constants.ALIGN_START,
    })
    Container._allow_fill_from_parent(list, { height = true })
    return list
end

local function sync_indicator_geometry(self)
    local indicator = self.indicator
    local active_value = effective_value(self)
    local trigger = active_value and self._trigger_nodes[active_value] or nil
    local orientation = self.orientation

    if indicator == nil then
        return
    end

    if trigger == nil then
        indicator.visible = false
        indicator:markDirty()
        return
    end

    local trigger_bounds = {
        width = trigger._resolved_width or 0,
        height = trigger._resolved_height or 0,
    }
    local origin_x = (trigger._layout_offset_x or 0) + (trigger.x or 0)
    local origin_y = (trigger._layout_offset_y or 0) + (trigger.y or 0)

    indicator.visible = true
    if orientation == Enums.Orientation.VERTICAL then
        indicator.x = origin_x
        indicator.y = origin_y
        indicator.width = 4
        indicator.height = trigger_bounds.height
    else
        indicator.x = origin_x
        indicator.y = origin_y + trigger_bounds.height - 4
        indicator.width = trigger_bounds.width
        indicator.height = 4
    end
    indicator:markDirty()
end

function Tabs:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = false,
    })
    Drawable.constructor(self, drawable_opts)
    self.value = opts.value
    self.onValueChange = opts.onValueChange
    self.orientation = opts.orientation or Enums.Orientation.HORIZONTAL
    self.activationMode = opts.activationMode or 'manual'
    self.listScrollable = opts.listScrollable == true
    self.loopFocus = opts.loopFocus ~= false
    self.disabledValues = opts.disabledValues

    self._ui_tabs_control = true

    if not enum_has(Enums.Orientation, self.orientation) then
        Assert.fail('Tabs.orientation must be "horizontal" or "vertical"', 2)
    end

    if self.activationMode ~= 'manual' then
        Assert.fail('activationMode other than "manual" is invalid', 2)
    end

    ControlUtils.assert_controlled_pair('value', opts.value, 'onValueChange', opts.onValueChange, 2)

    self._value_controlled = opts.value ~= nil
    self._value_uncontrolled = opts.value
    self._disabled_map = normalize_disabled_values(opts.disabledValues)
    self._trigger_nodes = {}
    self._panel_nodes = {}
    self._trigger_order = {}
    self._last_motion_value = opts.value

    local list_root
    local list_region = build_list_layout(self.orientation)
    local list_surface_height = 44
    if self.orientation == Enums.Orientation.VERTICAL then
        list_surface_height = Constants.SIZE_MODE_FILL
    end

    local list_surface = Drawable.new({
        tag = 'tabs_list_surface',
        internal = true,
        width = Constants.SIZE_MODE_FILL,
        height = list_surface_height,
        interactive = false,
        focusable = false,
        style_scope = TABS_LIST_SCOPE,
    })
    local indicator = Drawable.new({
        tag = 'tabs_indicator',
        internal = true,
        width = 0,
        height = 0,
        interactive = false,
        focusable = false,
        style_scope = TABS_INDICATOR_SCOPE,
    })
    list_surface:addChild(list_region)
    list_surface:addChild(indicator)
    Container._allow_fill_from_parent(list_surface, { width = true, height = true })
    if self.listScrollable then
        list_root = ScrollableContainer.new({
            width = Constants.SIZE_MODE_FILL,
            height = 44,
            scrollXEnabled = self.orientation == Enums.Orientation.HORIZONTAL,
            scrollYEnabled = self.orientation == Enums.Orientation.VERTICAL,
            showScrollbars = false,
            momentum = false,
        })
        Container._allow_fill_from_parent(list_root, { width = true })
        Container.addChild(self, list_root)
        self._list_root = list_root
        list_root.content:addChild(list_surface)
    else
        list_root = list_surface
        if self.orientation == Enums.Orientation.VERTICAL then
            list_root.height = Constants.SIZE_MODE_CONTENT
        else
            list_root.height = 44
        end
        Container.addChild(self, list_root)
    self._list_root = list_root
    self._list_region = list_region
    end

    local panels = Container({
        tag = 'tabs_panels',
        internal = true,
        width = Constants.SIZE_MODE_FILL,
        height = Constants.SIZE_MODE_FILL,
        y = 52,
        interactive = false,
    })
    Container._allow_fill_from_parent(panels, { width = true, height = true })
    Container.addChild(self, panels)
    self._panels_region = panels
    self._list_surface = list_surface
    self._list_region = list_region
    self.list = list_surface
    self.indicator = indicator
    self.panel = panels

    ControlUtils.add_control_listener(self, self, 'ui.activate', function(event)
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

    ControlUtils.add_control_listener(self, self, 'ui.navigate', function(event)
        if event.navigationMode ~= Constants.NAVIGATION_MODE_DIRECTIONAL then return end

        local focus_owner = ControlUtils.stage_focus_owner(self)
        if focus_owner == nil then return end

        local current = find_trigger_value_from_target(self, focus_owner)
        if current == nil then return end

        local orientation = self.orientation
        if orientation == Enums.Orientation.HORIZONTAL and
            event.direction ~= Constants.NAVIGATION_DIRECTION_LEFT and
            event.direction ~= Constants.NAVIGATION_DIRECTION_RIGHT then
            return
        end
        if orientation == Enums.Orientation.VERTICAL and
            event.direction ~= Constants.NAVIGATION_DIRECTION_UP and
            event.direction ~= Constants.NAVIGATION_DIRECTION_DOWN then
            return
        end

        local next_value = next_focus_value(self, current, event.direction)
        if next_value == nil then
            return
        end

        local trigger = self._trigger_nodes[next_value]
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

function Tabs._resolve_trigger_variant(_, trigger)
    if trigger == nil then
        return 'base'
    end

    if trigger._tab_disabled == true then
        return 'disabled'
    end

    if trigger._tab_active == true then
        return 'active'
    end

    if trigger._focused == true then
        return 'focused'
    end

    return 'base'
end

function Tabs._resolve_panel_variant(_, panel)
    if panel ~= nil and panel._tab_active == true then
        return 'active'
    end

    return 'inactive'
end

function Tabs:_register_tab(value, trigger_node, panel_node)
    Assert.string('value', value, 2)
    Assert.table('trigger_node', trigger_node, 2)
    Assert.table('panel_node', panel_node, 2)

    local triggers = self._trigger_nodes
    local panels = self._panel_nodes

    if triggers[value] ~= nil or panels[value] ~= nil then
        Assert.fail('duplicate trigger values within one Tabs root are invalid', 2)
    end

    local trigger = Drawable({
        tag = 'tabs_trigger_' .. value,
        internal = true,
        width = 120,
        height = 40,
        interactive = true,
        focusable = true,
        style_scope = TABS_TRIGGER_SCOPE,
    })
    trigger.pointerFocusCoupling = 'before'
    trigger._tab_trigger_value = value
    trigger:addChild(trigger_node)

    local panel = Drawable({
        tag = 'tabs_panel_' .. value,
        internal = true,
        width = Constants.SIZE_MODE_FILL,
        height = Constants.SIZE_MODE_FILL,
        interactive = true,
        focusable = false,
        style_scope = TABS_PANEL_SCOPE,
    })
    Container._allow_fill_from_parent(panel, { width = true, height = true })
    panel._tab_panel_value = value
    panel:addChild(panel_node)

    self._list_region:addChild(trigger)
    self._panels_region:addChild(panel)

    triggers[value] = trigger
    panels[value] = panel
    local order = self._trigger_order
    order[#order + 1] = value

    if self._value_controlled == false and self._value_uncontrolled == nil then
        self._value_uncontrolled = find_fallback_value(self)
    end

    sync_visual_state(self)
    return self
end

function Tabs:update(dt)
    Drawable.update(self, dt)

    self._disabled_map = normalize_disabled_values(self.disabledValues)

    local value = effective_value(self)
    if self._value_controlled == false and self._value_uncontrolled ~= value then
        self._value_uncontrolled = value
    end

    sync_visual_state(self)
    sync_indicator_geometry(self)

    local previous = self._last_motion_value
    if previous ~= value then
        self:_raise_motion('value', {
            defaultTarget = 'indicator',
            previousValue = previous,
            nextValue = value,
        })
    end
    self._last_motion_value = value
    return self
end

function Tabs:_get_active_value()
    return effective_value(self)
end

return Tabs
