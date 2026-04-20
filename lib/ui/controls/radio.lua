local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local ControlUtils = require('lib.ui.controls.control_utils')
local Rule = require('lib.ui.utils.rule')
local Schema = require('lib.ui.utils.schema')
local StyleScope = require('lib.ui.render.style_scope')

local Radio = Drawable:extends('Radio')
local RADIO_INDICATOR_SCOPE = StyleScope.create('radio', 'indicator')

local RadioSchema = {
    value = Rule.custom(function(_, value, _, level)
        if not Types.is_string(value) or value == '' then
            Assert.fail('Radio.value is required', level or 1)
        end
        return value
    end, { required = true }),
    disabled = Rule.boolean(false),
}

Radio.schema = Schema.extend(Drawable.schema, RadioSchema)

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
    self.pointerFocusCoupling = 'before'

    if not Types.is_string(opts.value) or opts.value == '' then
        Assert.fail('Radio.value is required', 2)
    end

    assert_string_or_node('Radio.label', opts.label, 2)
    assert_string_or_node('Radio.description', opts.description, 2)

    self._ui_radio_control = true
    self.value = opts.value
    self.disabled = opts.disabled == true

    local indicator = Drawable.new({
        tag = (self.tag and (self.tag .. '.indicator')) or 'radio.indicator',
        internal = true,
        width = 20,
        height = 20,
        interactive = false,
        focusable = false,
        style_scope = RADIO_INDICATOR_SCOPE,
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

    self.indicator = indicator
    self.label = label_slot
    self.description = description_slot

    if Types.is_table(opts.label) then
        label_slot:addChild(opts.label)
    else
        label_slot.text = opts.label
    end

    if Types.is_table(opts.description) then
        description_slot:addChild(opts.description)
    else
        description_slot.text = opts.description
    end

    ControlUtils.add_control_listener(self, self, 'ui.activate', function(event)
        if self.disabled then
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
    local current = self.parent
    while current ~= nil do
        if current._ui_radio_group_control == true then
            return current
        end
        current = current.parent
    end
    return nil
end

function Radio:_is_selected()
    local group = self:_find_group()
    return group ~= nil and group:_is_value_selected(self.value)
end

function Radio:_is_effectively_disabled()
    local group = self:_find_group()
    if group == nil then
        return self.disabled == true
    end
    return group:_is_radio_disabled(self)
end

function Radio:resolveStyleVariant()
    if self:_is_effectively_disabled() then
        return 'disabled'
    end

    if self:_is_selected() then
        return 'selected'
    end

    if self._focused == true then
        return 'focused'
    end

    return self.style_variant
end

function Radio:update(dt)
    Drawable.update(self, dt)

    local disabled = self:_is_effectively_disabled()
    ControlUtils.set_interaction_state(self, not disabled)

    local indicator = self.indicator
    if indicator ~= nil then
        indicator:setStyleVariant(self:resolveStyleVariant())
    end

    return self
end

function Radio:on_destroy()
    ControlUtils.remove_control_listeners(self)
    Container.on_destroy(self)
end

return Radio
