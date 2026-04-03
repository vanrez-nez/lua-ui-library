local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local ControlUtils = require('lib.ui.controls.control_utils')

local Radio = Drawable:extends('Radio')

local function assert_string_or_node(name, value, level)
    if value == nil or Types.is_string(value) or Types.is_table(value) then
        return
    end

    Assert.fail(name .. ' must be a string, node, or nil', level or 1)
end

function Radio:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = true,
    })
    Drawable.constructor(self, drawable_opts)
    rawset(self, 'pointerFocusCoupling', 'before')

    if not Types.is_string(opts.value) or opts.value == '' then
        Assert.fail('Radio.value is required', 2)
    end

    assert_string_or_node('Radio.label', opts.label, 2)
    assert_string_or_node('Radio.description', opts.description, 2)

    rawset(self, '_ui_radio_control', true)
    rawset(self, 'value', opts.value)
    rawset(self, 'disabled', opts.disabled == true)

    local indicator = Container.new({
        tag = (self.tag and (self.tag .. '.indicator')) or 'radio.indicator',
        internal = true,
        width = 20,
        height = 20,
        interactive = false,
        focusable = false,
    })
    local label_slot = Container.new({
        tag = (self.tag and (self.tag .. '.label')) or 'radio.label',
        internal = true,
        width = 'fill',
        height = 24,
        interactive = false,
        focusable = false,
    })
    Container._allow_fill_from_parent(label_slot, { width = true })
    local description_slot = Container.new({
        tag = (self.tag and (self.tag .. '.description')) or 'radio.description',
        internal = true,
        width = 'fill',
        height = 20,
        interactive = false,
        focusable = false,
    })
    Container._allow_fill_from_parent(description_slot, { width = true })

    Container.addChild(self, indicator)
    Container.addChild(self, label_slot)
    Container.addChild(self, description_slot)

    rawset(self, 'indicator', indicator)
    rawset(self, 'label', label_slot)
    rawset(self, 'description', description_slot)

    if Types.is_table(opts.label) then
        label_slot:addChild(opts.label)
    else
        rawset(label_slot, 'text', opts.label)
    end

    if Types.is_table(opts.description) then
        description_slot:addChild(opts.description)
    else
        rawset(description_slot, 'text', opts.description)
    end

    self:_add_event_listener('ui.activate', function(event)
        if self.disabled or rawget(self, '_destroyed') then
            return
        end

        local group = self:_find_group()
        if group ~= nil then
            group:_activate_radio(self)
            event:stopPropagation()
        end
    end)
end

function Radio.new(opts)
    return Radio(opts)
end

function Radio:_find_group()
    local current = rawget(self, 'parent')
    while current ~= nil do
        if rawget(current, '_ui_radio_group_control') == true then
            return current
        end
        current = rawget(current, 'parent')
    end
    return nil
end

function Radio:_is_selected()
    local group = self:_find_group()
    return group ~= nil and group:_is_value_selected(rawget(self, 'value'))
end

function Radio:_is_effectively_disabled()
    local group = self:_find_group()
    if group == nil then
        return rawget(self, 'disabled') == true
    end
    return group:_is_radio_disabled(self)
end

function Radio:_resolve_visual_variant()
    if self:_is_effectively_disabled() then
        return 'disabled'
    end

    if self:_is_selected() then
        return 'selected'
    end

    if rawget(self, '_focused') == true then
        return 'focused'
    end

    return 'base'
end

function Radio:update(dt)
    Drawable.update(self, dt)

    local disabled = self:_is_effectively_disabled()
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

    return self
end

return Radio
