local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local ControlUtils = require('lib.ui.controls.control_utils')
local Rule = require('lib.ui.utils.rule')

local RadioGroup = Drawable:extends('RadioGroup')

local function collect_radios(node, out)
    if rawget(node, '_destroyed') then
        return out
    end

    if rawget(node, '_ui_radio_control') == true then
        out[#out + 1] = node
        return out
    end

    local children = rawget(node, '_children') or {}
    for index = 1, #children do
        collect_radios(children[index], out)
    end

    return out
end

local function normalize_disabled_values(values)
    local map = {}
    if values == nil then
        return map
    end

    Assert.table('RadioGroup.disabledValues', values, 3)
    for index = 1, #values do
        map[tostring(values[index])] = true
    end
    return map
end

local function order_and_validate(self)
    local radios = collect_radios(self, {})
    if #radios == 0 then
        Assert.fail('zero registered radios within one RadioGroup root are invalid', 3)
    end

    local by_value = {}
    for index = 1, #radios do
        local radio = radios[index]
        local value = radio.value
        if by_value[value] ~= nil then
            Assert.fail('duplicate radio values within one RadioGroup root are invalid', 3)
        end
        by_value[value] = radio
    end

    rawset(self, '_radio_order', radios)
    rawset(self, '_radio_by_value', by_value)
end

local function is_disabled_value(self, value)
    local map = rawget(self, '_disabled_value_map') or {}
    return map[tostring(value)] == true
end

local function is_radio_enabled(self, radio)
    return radio.disabled ~= true and not is_disabled_value(self, radio.value)
end

local function first_enabled_value(self)
    local radios = rawget(self, '_radio_order') or {}
    for index = 1, #radios do
        if is_radio_enabled(self, radios[index]) then
            return radios[index].value
        end
    end
    return nil
end

local function normalize_value(self, current)
    local by_value = rawget(self, '_radio_by_value') or {}
    local radio = by_value[current]
    if radio ~= nil and is_radio_enabled(self, radio) then
        return current
    end
    return first_enabled_value(self)
end

local effective_value, request_value =
    ControlUtils.controlled_value('value', nil, {
        normalize = normalize_value,
    })

RadioGroup._control_schema = {
    value = Rule.any(),
    onValueChange = Rule.any(),
    orientation = Rule.custom(function(_, value, _, level)
        value = value or 'vertical'
        if value ~= 'horizontal' and value ~= 'vertical' then
            Assert.fail('RadioGroup.orientation must be "horizontal" or "vertical"', level or 1)
        end
        return value
    end, { default = 'vertical' }),
    disabledValues = Rule.custom(function(_, value)
        normalize_disabled_values(value)
        return value
    end),
}

RadioGroup._schema = ControlUtils.extend_schema(Drawable._schema, RadioGroup._control_schema)

local function focused_radio(self)
    local focus_owner = ControlUtils.stage_focus_owner(self)
    local current = focus_owner
    while current ~= nil and current ~= self do
        if rawget(current, '_ui_radio_control') == true then
            return current
        end
        current = rawget(current, 'parent')
    end
    return nil
end

function RadioGroup:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = false,
    })
    Drawable.constructor(self, drawable_opts)
    self.schema:define(RadioGroup._control_schema)
    self.value = opts.value
    self.onValueChange = opts.onValueChange
    self.orientation = opts.orientation or 'vertical'
    self.disabledValues = opts.disabledValues
    ControlUtils.validate_control_schema(self, opts, RadioGroup._control_schema, 2)

    rawset(self, '_ui_radio_group_control', true)

    if self.orientation ~= 'horizontal' and self.orientation ~= 'vertical' then
        Assert.fail('RadioGroup.orientation must be "horizontal" or "vertical"', 2)
    end

    ControlUtils.assert_controlled_pair('value', opts.value, 'onValueChange', opts.onValueChange, 2)

    rawset(self, '_value_controlled', opts.value ~= nil)
    rawset(self, '_value_uncontrolled', opts.value)
    rawset(self, '_disabled_value_map', normalize_disabled_values(opts.disabledValues))
    rawset(self, '_radio_order', {})
    rawset(self, '_radio_by_value', {})

    ControlUtils.add_control_listener(self, self, 'ui.navigate', function(event)
        if event.navigationMode ~= 'directional' then
            return
        end

        if self.orientation == 'horizontal' and event.direction ~= 'left' and event.direction ~= 'right' then
            return
        end

        if self.orientation == 'vertical' and event.direction ~= 'up' and event.direction ~= 'down' then
            return
        end

        local radios = rawget(self, '_radio_order') or {}
        local current = focused_radio(self)
        local current_index = 0
        if current ~= nil then
            for index = 1, #radios do
                if radios[index] == current then
                    current_index = index
                    break
                end
            end
        end

        local step = (event.direction == 'left' or event.direction == 'up') and -1 or 1
        local next_index = current_index
        repeat
            next_index = next_index + step
            if next_index < 1 or next_index > #radios then
                return
            end
        until is_radio_enabled(self, radios[next_index])

        ControlUtils.request_focus(radios[next_index])
        event:preventDefault()
        event:stopPropagation()
    end)
end

function RadioGroup.new(opts)
    return RadioGroup(opts)
end

function RadioGroup:_is_radio_disabled(radio)
    return not is_radio_enabled(self, radio)
end

function RadioGroup:_is_value_selected(value)
    return effective_value(self) == value
end

function RadioGroup:_activate_radio(radio)
    if radio == nil or not is_radio_enabled(self, radio) then
        return
    end

    local value = radio.value
    if effective_value(self) == value then
        return
    end

    ControlUtils.request_focus(radio)
    request_value(self, value)
end

function RadioGroup:update(dt)
    Drawable.update(self, dt)

    rawset(self, '_disabled_value_map', normalize_disabled_values(self.disabledValues))
    order_and_validate(self)

    local resolved = effective_value(self)
    if rawget(self, '_value_controlled') == false then
        rawset(self, '_value_uncontrolled', resolved)
    elseif self.value ~= resolved and resolved ~= nil then
        ControlUtils.call_if_function(self.onValueChange, resolved)
    end

    return self
end

function RadioGroup:destroy()
    if rawget(self, '_destroyed') then
        return
    end
    rawset(self, '_destroyed', true)
    ControlUtils.remove_control_listeners(self)
    rawset(self, '_destroyed', false)
    Container.destroy(self)
end

return RadioGroup
