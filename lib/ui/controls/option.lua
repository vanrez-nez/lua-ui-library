local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local ControlUtils = require('lib.ui.controls.control_utils')
local Rule = require('lib.ui.utils.rule')

local Option = Drawable:extends('Option')

local OptionSchema = {
    value = Rule.custom(function(_, value, _, level)
        if not Types.is_string(value) or value == '' then
            Assert.fail('Option.value is required', level or 1)
        end
        return value
    end, { required = true }),
    disabled = Rule.boolean(false),
}

Option._schema = ControlUtils.extend_schema(Drawable._schema, OptionSchema)

local function assert_string_or_node(name, value, level)
    if value == nil or Types.is_string(value) or Types.is_table(value) then
        return
    end

    Assert.fail(name .. ' must be a string, node, or nil', level or 1)
end

function Option:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = true,
    })
    Drawable.constructor(self, drawable_opts)
    self.schema:define(OptionSchema)
    rawset(self, 'pointerFocusCoupling', 'before')

    if not Types.is_string(opts.value) or opts.value == '' then
        Assert.fail('Option.value is required', 2)
    end

    assert_string_or_node('Option.label', opts.label, 2)
    assert_string_or_node('Option.description', opts.description, 2)

    rawset(self, '_ui_option_control', true)
    self.value = opts.value
    self.disabled = opts.disabled == true

    local label_slot = Container.new({
        tag = (self.tag and (self.tag .. '.label')) or 'option.label',
        internal = true,
        width = 'fill',
        height = 24,
        interactive = false,
        focusable = false,
    })
    Container._allow_fill_from_parent(label_slot, { width = true })
    local description_slot = Container.new({
        tag = (self.tag and (self.tag .. '.description')) or 'option.description',
        internal = true,
        width = 'fill',
        height = 20,
        interactive = false,
        focusable = false,
    })
    Container._allow_fill_from_parent(description_slot, { width = true })

    Container.addChild(self, label_slot)
    Container.addChild(self, description_slot)

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

    ControlUtils.add_control_listener(self, self, 'ui.activate', function(event)
        if self.disabled == true then
            return
        end

        local select = self:_find_select()
        if select ~= nil then
            select:_activate_option(self)
            event:stopPropagation()
        end
    end)
end

function Option.new(opts)
    return Option(opts)
end

function Option:_find_select()
    local current = rawget(self, 'parent')
    while current ~= nil do
        if rawget(current, '_ui_select_popup_slot') == true then
            return rawget(current, '_ui_select_owner')
        end
        if rawget(current, '_ui_select_control') == true then
            return current
        end
        current = rawget(current, 'parent')
    end
    return nil
end

function Option:_is_selected()
    local select = self:_find_select()
    return select ~= nil and select:_is_option_selected(self.value)
end

function Option:_is_effectively_disabled()
    local select = self:_find_select()
    if select == nil then
        return self.disabled == true
    end
    return select:_is_option_disabled(self)
end

function Option:_resolve_visual_variant()
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

function Option:update(dt)
    Drawable.update(self, dt)

    local disabled = self:_is_effectively_disabled()
    ControlUtils.set_interaction_state(self, not disabled)

    return self
end

return Option
