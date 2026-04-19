local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')
local Rule = require('lib.ui.utils.rule')

local Checkbox = Drawable:extends('Checkbox')

local VALID_STATES = {
    checked = true,
    unchecked = true,
    indeterminate = true,
}

local function normalize_state(value)
    if value == true then return 'checked' end
    if value == false or value == nil then return 'unchecked' end
    if value == 'indeterminate' then return 'indeterminate' end
    if value == 'checked' or value == 'unchecked' then return value end
    return nil
end

local function validate_toggle_order(toggle_order)
    if toggle_order == nil then
        return nil
    end

    Assert.table('toggleOrder', toggle_order, 3)

    local has_checked = false
    local has_unchecked = false

    for i = 1, #toggle_order do
        local entry = toggle_order[i]
        if not VALID_STATES[entry] then
            Assert.fail('invalid toggleOrder entry: ' .. tostring(entry), 3)
        end
        if entry == 'checked' then has_checked = true end
        if entry == 'unchecked' then has_unchecked = true end
    end

    if not has_checked or not has_unchecked then
        Assert.fail('toggleOrder must contain both "checked" and "unchecked"', 3)
    end

    return toggle_order
end

local function normalize_checked(_, value)
    return normalize_state(value) or 'unchecked'
end

local get_effective_checked, request_checked =
    ControlUtils.controlled_value('checked', 'unchecked', {
        callback = 'onCheckedChange',
        normalize = normalize_checked,
    })

Checkbox._control_schema = {
    checked = Rule.any(),
    onCheckedChange = Rule.any(),
    disabled = Rule.boolean(false),
    label = Rule.any(),
    description = Rule.any(),
    toggleOrder = Rule.custom(function(_, value, _, level)
        return validate_toggle_order(value)
    end),
}

Checkbox._schema = ControlUtils.extend_schema(Drawable._schema, Checkbox._control_schema)

local function resolve_next_state(self)
    local current = get_effective_checked(self)
    local toggle_order = self.toggleOrder

    if toggle_order == nil then
        if current == 'indeterminate' then
            return 'checked'
        end
        if current == 'checked' then
            return 'unchecked'
        end
        return 'checked'
    end

    for i = 1, #toggle_order do
        if toggle_order[i] == current then
            return toggle_order[(i % #toggle_order) + 1]
        end
    end

    return toggle_order[1]
end

function Checkbox:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = true,
    })
    Drawable.constructor(self, drawable_opts)
    self.schema:define(Checkbox._control_schema)
    self.checked = opts.checked
    self.onCheckedChange = opts.onCheckedChange
    self.disabled = opts.disabled == true
    self.label = opts.label
    self.description = opts.description
    self.toggleOrder = opts.toggleOrder
    ControlUtils.validate_control_schema(self, opts, Checkbox._control_schema, 2)
    self.pointerFocusCoupling = 'before'

    self._ui_checkbox_control = true

    self._checked_controlled = opts.checked ~= nil
    self._checked_uncontrolled = normalize_state(opts.checked) or 'unchecked'

    local box = Drawable.new({
        tag = (self.tag and (self.tag .. '.box')) or 'checkbox.box',
        internal = true,
        width = 20,
        height = 20,
        interactive = false,
        focusable = false,
    })
    local indicator = Drawable.new({
        tag = (self.tag and (self.tag .. '.indicator')) or 'checkbox.indicator',
        internal = true,
        width = 12,
        height = 12,
        interactive = false,
        focusable = false,
    })
    box._styling_context = {
        component = 'checkbox',
        part = 'box',
    }
    indicator._styling_context = {
        component = 'checkbox',
        part = 'indicator',
    }
    box:addChild(indicator)
    Container.addChild(self, box)
    self.box = box
    self.indicator = indicator

    ControlUtils.assert_controlled_pair('checked', opts.checked, 'onCheckedChange', opts.onCheckedChange, 2)

    ControlUtils.add_control_listener(self, self, 'ui.activate', function(event)
        if self.disabled == true then return end
        if event.defaultPrevented then return end

        request_checked(self, resolve_next_state(self))
    end)
end

function Checkbox.new(opts)
    return Checkbox(opts)
end

function Checkbox:_get_checked_state()
    return get_effective_checked(self)
end

function Checkbox:_resolve_visual_variant()
    if self.disabled == true then
        return 'disabled'
    end

    local state = get_effective_checked(self)

    if state == 'indeterminate' then
        return 'indeterminate'
    end

    if state == 'checked' then
        return 'checked'
    end

    if self._focused == true then
        return 'focused'
    end

    return 'base'
end

function Checkbox:update(dt)
    Drawable.update(self, dt)

    local disabled = self.disabled == true
    ControlUtils.set_interaction_state(self, not disabled)

    local box = self.box
    local indicator = self.indicator
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local box_size = math.min(width, height, 20)
    local indicator_size = math.max(0, box_size - 8)
    local variant = self:_resolve_visual_variant()

    if box ~= nil then
        box.x = (width - box_size) * 0.5
        box.y = (height - box_size) * 0.5
        box.width = box_size
        box.height = box_size
        box._styling_variant = variant
        box:markDirty()
    end

    if indicator ~= nil then
        local state = get_effective_checked(self)
        local show_indicator = state ~= 'unchecked'
        indicator.width = indicator_size
        indicator.height = indicator_size
        indicator.x = (box_size - indicator_size) * 0.5
        indicator.y = (box_size - indicator_size) * 0.5
        indicator.visible = show_indicator
        indicator._styling_variant = variant
        indicator:markDirty()
    end

    return self
end

function Checkbox:on_destroy()
    ControlUtils.remove_control_listeners(self)
    Container.on_destroy(self)
end

return Checkbox
