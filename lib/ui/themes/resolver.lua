local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local Resolver = {}

local function token_key(component, part, property_name, variant)
    local key = table.concat({ component, part, property_name }, '.')

    if variant ~= nil and variant ~= 'base' then
        key = key .. '.' .. tostring(variant)
    end

    return key
end

local function resolve_override_value(source, part, property_name, variant)
    if not Types.is_table(source) then
        return nil
    end

    local part_table = source[part]

    if not Types.is_table(part_table) then
        return nil
    end

    local property_value = part_table[property_name]

    if not Types.is_table(property_value) then
        return property_value
    end

    if variant ~= nil and property_value[variant] ~= nil then
        return property_value[variant]
    end

    return property_value.base
end

function Resolver.resolve(context)
    Assert.table('context', context, 2)

    local component = context.component
    local part = context.part
    local property_name = context.property
    local variant = context.variant

    Assert.string('context.component', component, 2)
    Assert.string('context.part', part, 2)
    Assert.string('context.property', property_name, 2)

    if context.instanceValue ~= nil then
        return context.instanceValue
    end

    local instance_variant = resolve_override_value(
        context.instanceOverrides,
        part,
        property_name,
        variant
    )

    if instance_variant ~= nil then
        return instance_variant
    end

    local skin_variant = resolve_override_value(
        context.partSkin,
        part,
        property_name,
        variant
    )

    if skin_variant ~= nil then
        return skin_variant
    end

    local key_with_variant = token_key(component, part, property_name, variant)
    local base_key = token_key(component, part, property_name, nil)
    local theme = context.theme
    local defaults = context.defaults or {}

    if Types.is_table(theme) and Types.is_table(theme.tokens) then
        if theme.tokens[key_with_variant] ~= nil then
            return theme.tokens[key_with_variant]
        end

        if theme.tokens[base_key] ~= nil then
            return theme.tokens[base_key]
        end
    end

    if defaults[key_with_variant] ~= nil then
        return defaults[key_with_variant]
    end

    if defaults[base_key] ~= nil then
        return defaults[base_key]
    end

    error('missing token "' .. key_with_variant .. '"', 2)
end

function Resolver.token_key(component, part, property_name, variant)
    return token_key(component, part, property_name, variant)
end

return Resolver
