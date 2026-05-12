--- StyleScope — immutable token namespace address for a drawable part.
--
-- A StyleScope binds a drawable to one component/part token namespace.
-- Token-key composition is centralized here so controls do not concatenate
-- token path segments directly.
--
-- Usage:
--   local scope = StyleScope.create('button', 'surface')
--   scope:get_token_key('backgroundColor')             --> button.surface.backgroundColor
--   scope:get_token_key('backgroundColor', 'hovered')  --> button.surface.backgroundColor.hovered

local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local StyleScope = {}
StyleScope.__index = StyleScope

-- Table reference key — unique by address, impossible to collide with
-- any string or external table key.
local ACCESSOR = {}
local SMETA = {}

local function assert_segment(name, value, level)
    Assert.string(name, value, level or 1)

    if value == '' then
        Assert.fail(name .. ' must not be empty', level or 1)
    end

    if value:find('.', 1, true) ~= nil then
        Assert.fail(name .. ' must not contain "."', level or 1)
    end
end

SMETA.__index = function(_, key)
    local method = StyleScope[key]
    if method ~= nil then
        return method
    end

    return nil
end

SMETA.__newindex = function(_, key)
    Assert.fail('StyleScope is immutable; cannot assign "' .. tostring(key) .. '"', 2)
end

SMETA.__eq = function(left, right)
    return left:equals(right)
end

SMETA.__tostring = function(self)
    local data = rawget(self, ACCESSOR)
    if data == nil then
        return 'StyleScope(?)'
    end
    return 'StyleScope(' .. data.component .. '.' .. data.part .. ')'
end

function StyleScope.create(component, part)
    assert_segment('component', component, 3)
    assert_segment('part', part, 3)

    local scope = {}
    rawset(scope, ACCESSOR, {
        component = component,
        part = part
    })

    return setmetatable(scope, SMETA)
end

function StyleScope.is_style_scope(value)
    return Types.is_table(value) and getmetatable(value) == SMETA
        and rawget(value, ACCESSOR) ~= nil
end

function StyleScope.assert(name, value, level)
    if not StyleScope.is_style_scope(value) then
        Assert.fail(name .. ' must be a StyleScope', level or 1)
    end
end

function StyleScope:equals(other)
    local left_data = rawget(self, ACCESSOR)
    local right_data = Types.is_table(other) and rawget(other, ACCESSOR) or nil

    return left_data ~= nil and right_data ~= nil
        and left_data.component == right_data.component
        and left_data.part == right_data.part
end

function StyleScope:get_component()
    return rawget(self, ACCESSOR).component
end

function StyleScope:get_part()
    return rawget(self, ACCESSOR).part
end

function StyleScope:get_token_key(property_name, variant)
    Assert.string('property', property_name, 2)

    if property_name == '' then
        Assert.fail('property must not be empty', 2)
    end

    if property_name:find('.', 1, true) ~= nil then
        Assert.fail('property must not contain "."', 2)
    end

    local data = rawget(self, ACCESSOR)
    local key = data.component .. '.' .. data.part .. '.' .. property_name

    if variant ~= nil and variant ~= 'base' then
        key = key .. '.' .. tostring(variant)
    end

    return key
end

return StyleScope
