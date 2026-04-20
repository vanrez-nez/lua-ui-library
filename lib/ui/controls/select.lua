local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Text = require('lib.ui.controls.text')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local ControlUtils = require('lib.ui.controls.control_utils')
local Rule = require('lib.ui.utils.rule')
local Schema = require('lib.ui.utils.schema')
local Constants = require('lib.ui.core.constants')
local StyleScope = require('lib.ui.render.style_scope')

local Select = Drawable:extends('Select')
local SELECT_TRIGGER_SCOPE = StyleScope.create('select', 'trigger')
local SELECT_POPUP_SCOPE = StyleScope.create('select', 'popup')

local function collect_options(node, out)
    if node._ui_option_control == true then
        out[#out + 1] = node
        return out
    end

    local children = node._children
    for index = 1, #children do
        collect_options(children[index], out)
    end

    return out
end

local function normalize_disabled_values(values)
    local map = {}
    if values == nil then
        return map
    end

    Assert.table('Select.disabledValues', values, 3)
    for index = 1, #values do
        map[tostring(values[index])] = true
    end
    return map
end

local function validate_value_shape(opts)
    local mode = opts.selectionMode or 'single'
    local value = opts.value

    if mode ~= 'single' and mode ~= 'multiple' then
        Assert.fail('Select.selectionMode must be "single" or "multiple"', 2)
    end

    if mode == 'single' and value ~= nil and not Types.is_string(value) then
        Assert.fail('Select.value must be a string or nil in single mode', 2)
    end

    if mode == 'multiple' and value ~= nil and not Types.is_table(value) then
        Assert.fail('Select.value must be a table or nil in multiple mode', 2)
    end
end

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

    ControlUtils.call_if_function(self.onOpenChange, next_value)
end

local raw_selected_value, request_value_change =
    ControlUtils.controlled_value('value', nil)

Select._control_schema = {
    value = Rule.any(),
    onValueChange = Rule.any(),
    open = Rule.boolean(),
    onOpenChange = Rule.any(),
    selectionMode = Rule.custom(function(_, value, _, level)
        value = value or 'single'
        if value ~= 'single' and value ~= 'multiple' then
            Assert.fail('Select.selectionMode must be "single" or "multiple"', level or 1)
        end
        return value
    end, { default = 'single' }),
    placeholder = Rule.any({ default = 'None selected' }),
    modal = Rule.boolean(false),
    disabled = Rule.boolean(false),
    disabledValues = Rule.custom(function(_, value)
        normalize_disabled_values(value)
        return value
    end),
}

Select.schema = Schema.extend(Drawable.schema, Select._control_schema)
Select._overlay_root_key = '_popup_root'
Select:implements(ControlUtils.overlay_mixin)

local function sync_option_registry(self)
    local options = collect_options(self._popup_slot, {})
    if #options == 0 then
        Assert.fail('zero registered options within one Select root are invalid', 3)
    end

    local by_value = {}
    for index = 1, #options do
        local option = options[index]
        local value = option.value
        if by_value[value] ~= nil then
            Assert.fail('duplicate option values within one Select root are invalid', 3)
        end
        by_value[value] = option
    end

    self._option_order = options
    self._option_by_value = by_value
end

local function option_is_enabled(self, option)
    if option == nil then
        return false
    end
    return option.disabled ~= true and not self._disabled_value_map[tostring(option.value)]
end

local function effective_selected_order(self)
    local mode = self.selectionMode
    local current = raw_selected_value(self)
    local ordered = {}
    local selected = {}

    if mode == 'single' then
        if current ~= nil then
            selected[current] = true
        end
    elseif Types.is_table(current) then
        for index = 1, #current do
            selected[current[index]] = true
        end
    end

    local options = self._option_order
    for index = 1, #options do
        local value = options[index].value
        if selected[value] == true and option_is_enabled(self, options[index]) then
            ordered[#ordered + 1] = value
        end
    end

    return ordered
end

local function commit_effective_value(self)
    local ordered = effective_selected_order(self)
    if self.selectionMode == 'single' then
        if self._value_controlled == false then
            self._value_uncontrolled = ordered[1]
        end
        return ordered[1]
    end

    if self._value_controlled == false then
        self._value_uncontrolled = (#ordered > 0) and ordered or nil
    end

    return (#ordered > 0) and ordered or nil
end

local function summary_text(self)
    local ordered = effective_selected_order(self)
    if #ordered == 0 then
        return self.placeholder or 'None selected'
    end

    if self.selectionMode == 'single' then
        local option = self._option_by_value[ordered[1]]
        local label_slot = option and option.label or nil
        local label = label_slot and label_slot.text or nil
        return label or ordered[1]
    end

    return tostring(#ordered) .. ' selected'
end

local function sync_summary(self)
    local summary = self._summary_text
    if summary ~= nil then
        summary:setText(summary_text(self))
    end
end

local function position_popup(self, stage)
    local trigger = self.trigger
    local popup = self.popup
    local trigger_bounds = trigger:getWorldBounds()
    local viewport = stage:getViewport()

    popup.width = math.max(trigger_bounds.width, popup._resolved_width or 0)
    popup.x = math.max(viewport.x, math.min(trigger_bounds.x, viewport.width - popup.width))
    popup.y = math.min(viewport.height - popup.height, trigger_bounds.y + trigger_bounds.height)
    popup:markDirty()
end

local function next_enabled_option(self, direction)
    local current_focus = ControlUtils.stage_focus_owner(self)
    local options = self._option_order
    local current_index = 0

    for index = 1, #options do
        if options[index] == current_focus then
            current_index = index
            break
        end
    end

    local step = 1
    if direction == Constants.NAVIGATION_DIRECTION_LEFT or direction == Constants.NAVIGATION_DIRECTION_UP then
        step = -1
    end
    local next_index = current_index
    repeat
        next_index = next_index + step
        if next_index < 1 or next_index > #options then
            return nil
        end
    until option_is_enabled(self, options[next_index])

    return options[next_index]
end

function Select:constructor(opts)
    opts = opts or {}
    validate_value_shape(opts)

    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = false,
    })
    Drawable.constructor(self, drawable_opts)
    self.value = opts.value
    self.onValueChange = opts.onValueChange
    self.open = opts.open
    self.onOpenChange = opts.onOpenChange
    self.selectionMode = opts.selectionMode or 'single'
    self.placeholder = opts.placeholder or 'None selected'
    self.modal = opts.modal == true
    self.disabled = opts.disabled == true
    self.disabledValues = opts.disabledValues
    ControlUtils.validate_control_schema(self, opts, Select._control_schema, 2)

    self._ui_select_control = true

    ControlUtils.assert_controlled_pair('value', opts.value, 'onValueChange', opts.onValueChange, 2)
    ControlUtils.assert_controlled_pair('open', opts.open, 'onOpenChange', opts.onOpenChange, 2)

    self._value_controlled = opts.value ~= nil
    self._value_uncontrolled = opts.value
    self._open_controlled = opts.open ~= nil
    self._open_uncontrolled = opts.open == true
    self._disabled_value_map = normalize_disabled_values(opts.disabledValues)
    self._option_order = {}
    self._option_by_value = {}
    self._mounted_stage = nil
    self._last_open_state = effective_open(self)

    local trigger = Drawable.new({
        tag = (self.tag and (self.tag .. '.trigger')) or 'select.trigger',
        internal = true,
        width = 'fill',
        height = 40,
        interactive = true,
        focusable = true,
        style_scope = SELECT_TRIGGER_SCOPE,
    })
    Container._allow_fill_from_parent(trigger, { width = true })
    trigger.pointerFocusCoupling = 'before'

    local summary = Text.new({
        tag = (self.tag and (self.tag .. '.summary')) or 'select.summary',
        internal = true,
        text = self.placeholder,
        width = 'fill',
        fontSize = 16,
    })
    Container._allow_fill_from_parent(summary, { width = true })
    trigger:addChild(summary)
    Container.addChild(self, trigger)

    local popup_root = Container.new({
        tag = (self.tag and (self.tag .. '.popup_root')) or 'select.popup_root',
        internal = true,
        width = 0,
        height = 0,
        interactive = false,
        focusable = false,
    })
    local popup = Drawable.new({
        tag = (self.tag and (self.tag .. '.popup')) or 'select.popup',
        internal = true,
        width = 180,
        height = 132,
        interactive = true,
        focusable = false,
        style_scope = SELECT_POPUP_SCOPE,
    })
    local popup_slot = Container.new({
        tag = (self.tag and (self.tag .. '.popup_slot')) or 'select.popup_slot',
        internal = true,
        width = 'fill',
        height = 'fill',
        interactive = false,
        focusable = false,
    })
    Container._allow_fill_from_parent(popup_slot, { width = true, height = true })
    Container._allow_child_fill(popup_slot, { width = true, height = true })
    popup_slot._ui_select_popup_slot = true
    popup_slot._ui_select_owner = self

    popup_root:addChild(popup)
    popup:addChild(popup_slot)

    self.root = self
    self.trigger = trigger
    self.summary = summary
    self.placeholderRegion = summary
    self.popup = popup
    self._popup_root = popup_root
    self._popup_slot = popup_slot
    self._summary_text = summary

    ControlUtils.add_control_listener(self, self, 'ui.activate', function(event)
        if self.disabled then
            return
        end

        local current = event.target
        while current ~= nil do
            if current == trigger then
                request_open_change(self, not effective_open(self))
                event:stopPropagation()
                return
            end
            current = current.parent
        end
    end)

    ControlUtils.add_control_listener(self, popup_root, 'ui.navigate', function(event)
        if not effective_open(self) or event.navigationMode ~= Constants.NAVIGATION_MODE_DIRECTIONAL then
            return
        end

        local next_option = next_enabled_option(self, event.direction)
        if next_option ~= nil then
            ControlUtils.request_focus(next_option)
            event:preventDefault()
            event:stopPropagation()
        end
    end)

    ControlUtils.add_control_listener(self, popup_root, 'ui.dismiss', function(event)
        if effective_open(self) then
            request_open_change(self, false)
            event:stopPropagation()
        end
    end)
end

function Select.new(opts)
    return Select(opts)
end

function Select:addChild(child)
    if child._ui_option_control ~= true then
        Assert.fail('Select accepts only Option descendants through addChild in this revision', 2)
    end
    return self._popup_slot:addChild(child)
end

function Select:removeChild(child)
    return self._popup_slot:removeChild(child)
end

function Select:_is_option_disabled(option)
    return not option_is_enabled(self, option)
end

function Select:_is_option_selected(value)
    local ordered = effective_selected_order(self)
    for index = 1, #ordered do
        if ordered[index] == value then
            return true
        end
    end
    return false
end

function Select:_activate_option(option)
    if self.disabled or not option_is_enabled(self, option) then
        return
    end

    local value = option.value
    local mode = self.selectionMode
    local ordered = effective_selected_order(self)

    if mode == 'single' then
        if ordered[1] == value then
            return
        end
        request_value_change(self, value)
        request_open_change(self, false)
        ControlUtils.request_focus(self.trigger)
        return
    end

    local selected = {}
    for index = 1, #ordered do
        selected[ordered[index]] = true
    end

    if selected[value] then
        selected[value] = nil
    else
        selected[value] = true
    end

    local next_values = {}
    local options = self._option_order
    for index = 1, #options do
        local option_value = options[index].value
        if selected[option_value] == true then
            next_values[#next_values + 1] = option_value
        end
    end

    request_value_change(self, (#next_values > 0) and next_values or nil)
end

function Select:update(dt)
    Drawable.update(self, dt)

    self._disabled_value_map = normalize_disabled_values(self.disabledValues)
    sync_option_registry(self)
    commit_effective_value(self)
    sync_summary(self)

    local wants_open = effective_open(self)
    local stage = ControlUtils.find_stage(self)
    local was_open = self._last_open_state

    if wants_open and stage ~= nil then
        self:_attach_overlay(stage)
        position_popup(self, stage)
        if not was_open then
            self:_raise_motion('open', { defaultTarget = 'popup' })
            local first = next_enabled_option(self, 'down') or self._option_order[1]
            if first ~= nil then
                ControlUtils.request_focus(first)
            end
        end
    else
        if self._mounted_stage ~= nil then
            self:_detach_overlay()
        end
        if was_open and not wants_open then
            self:_raise_motion('close', { defaultTarget = 'popup' })
        end
    end

    self._last_open_state = wants_open
    self.trigger:setStyleVariant(wants_open and 'open' or nil)
    self.popup:setStyleVariant(wants_open and 'open' or nil)
    return self
end

function Select:_overlay_focus_contract()
    if self.modal == true then
        return {
            scope = true,
            trap = true,
        }
    end

    return {
        scope = true,
    }
end

function Select:on_destroy()
    ControlUtils.remove_control_listeners(self)
    self:_detach_overlay()
    self._popup_root:destroy()
    Container.on_destroy(self)
end

return Select
