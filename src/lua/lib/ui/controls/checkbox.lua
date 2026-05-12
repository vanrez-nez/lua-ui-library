local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Control = require('lib.ui.controls.control')
local Schema = require('lib.ui.utils.schema')
local StyleScope = require('lib.ui.render.style_scope')
local CheckboxSchema = require('lib.ui.controls.checkbox_schema')

local Checkbox = Control:extends('Checkbox')
local CHECKBOX_BOX_SCOPE = StyleScope.create('checkbox', 'box')
local CHECKBOX_INDICATOR_SCOPE = StyleScope.create('checkbox', 'indicator')

local function normalize_state(value)
    if value == true then return 'checked' end
    if value == false or value == nil then return 'unchecked' end
    if value == 'indeterminate' then return 'indeterminate' end
    if value == 'checked' or value == 'unchecked' then return value end
    return nil
end

local function normalize_checked(_, value)
    return normalize_state(value) or 'unchecked'
end

local get_effective_checked, request_checked =
    Control.controlled_value('checked', 'unchecked', {
        callback = 'onCheckedChange',
        normalize = normalize_checked,
    })

Checkbox.schema = Schema.extend(Control.schema, CheckboxSchema)

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
    Control.constructor(self, opts, {
        interactive = true,
        focusable = true,
    })
    self.checked = opts.checked
    self.onCheckedChange = opts.onCheckedChange
    self.disabled = opts.disabled == true
    self.label = opts.label
    self.description = opts.description
    self.toggleOrder = opts.toggleOrder
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
        style_scope = CHECKBOX_BOX_SCOPE,
    })
    local indicator = Drawable.new({
        tag = (self.tag and (self.tag .. '.indicator')) or 'checkbox.indicator',
        internal = true,
        width = 12,
        height = 12,
        interactive = false,
        focusable = false,
        style_scope = CHECKBOX_INDICATOR_SCOPE,
    })
    box:addChild(indicator)
    Container.addChild(self, box)
    self.box = box
    self.indicator = indicator

    Control.assert_controlled_pair('checked', opts.checked, 'onCheckedChange', opts.onCheckedChange, 2)

    self:addControlListener(self, 'ui.activate', function(event)
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

function Checkbox:resolveStyleVariant()
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

    return self.style_variant
end

function Checkbox:update(dt)
    Drawable.update(self, dt)

    local disabled = self.disabled == true
    self:setInteractionState(not disabled)

    local box = self.box
    local indicator = self.indicator
    local width = self._resolved_width or 0
    local height = self._resolved_height or 0
    local box_size = math.min(width, height, 20)
    local indicator_size = math.max(0, box_size - 8)
    local variant = self:resolveStyleVariant()

    if box ~= nil then
        box.x = (width - box_size) * 0.5
        box.y = (height - box_size) * 0.5
        box.width = box_size
        box.height = box_size
        box:setStyleVariant(variant)
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
        indicator:setStyleVariant(variant)
        indicator:markDirty()
    end

    return self
end

function Checkbox:on_destroy()
    self:removeControlListeners()
    Container.on_destroy(self)
end

return Checkbox
