local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local ControlUtils = require('lib.ui.controls.control_utils')

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

local function get_effective_checked(self)
    if rawget(self, '_checked_controlled') then
        return normalize_state(rawget(self, 'checked')) or 'unchecked'
    end
    return rawget(self, '_checked_uncontrolled') or 'unchecked'
end

local function request_checked(self, next_state)
    local on_change = rawget(self, 'onCheckedChange')
    if rawget(self, '_checked_controlled') then
        ControlUtils.call_if_function(on_change, next_state)
        return
    end

    rawset(self, '_checked_uncontrolled', next_state)
    ControlUtils.call_if_function(on_change, next_state)
end

local function resolve_next_state(self)
    local current = get_effective_checked(self)
    local toggle_order = rawget(self, 'toggleOrder')

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
    rawset(self, 'pointerFocusCoupling', 'before')

    rawset(self, '_ui_checkbox_control', true)
    rawset(self, 'checked', opts.checked)
    rawset(self, 'onCheckedChange', opts.onCheckedChange)
    rawset(self, 'disabled', opts.disabled == true)
    rawset(self, 'label', opts.label)
    rawset(self, 'description', opts.description)
    rawset(self, 'toggleOrder', validate_toggle_order(opts.toggleOrder))

    rawset(self, '_checked_controlled', opts.checked ~= nil)
    rawset(self, '_checked_uncontrolled', normalize_state(opts.checked) or 'unchecked')

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
    rawset(box, '_styling_context', {
        component = 'checkbox',
        part = 'box',
    })
    rawset(indicator, '_styling_context', {
        component = 'checkbox',
        part = 'indicator',
    })
    box:addChild(indicator)
    Container.addChild(self, box)
    rawset(self, 'box', box)
    rawset(self, 'indicator', indicator)

    ControlUtils.assert_controlled_pair('checked', opts.checked, 'onCheckedChange', opts.onCheckedChange, 2)

    self:_add_event_listener('ui.activate', function(event)
        if rawget(self, '_destroyed') then return end
        if rawget(self, 'disabled') == true then return end
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
    if rawget(self, 'disabled') == true then
        return 'disabled'
    end

    local state = get_effective_checked(self)

    if state == 'indeterminate' then
        return 'indeterminate'
    end

    if state == 'checked' then
        return 'checked'
    end

    if rawget(self, '_focused') == true then
        return 'focused'
    end

    return 'base'
end

function Checkbox:update(dt)
    Drawable.update(self, dt)

    local disabled = rawget(self, 'disabled') == true
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

    local box = rawget(self, 'box')
    local indicator = rawget(self, 'indicator')
    local width = rawget(self, '_resolved_width') or 0
    local height = rawget(self, '_resolved_height') or 0
    local box_size = math.min(width, height, 20)
    local indicator_size = math.max(0, box_size - 8)
    local variant = self:_resolve_visual_variant()

    if box ~= nil then
        box.x = (width - box_size) * 0.5
        box.y = (height - box_size) * 0.5
        box.width = box_size
        box.height = box_size
        rawset(box, '_styling_variant', variant)
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
        rawset(indicator, '_styling_variant', variant)
        indicator:markDirty()
    end

    return self
end

return Checkbox
