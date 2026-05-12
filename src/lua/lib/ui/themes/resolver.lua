local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local StyleScope = require('lib.ui.render.style_scope')

local Resolver = {}

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

    local scope = context.style_scope
    local property_name = context.property
    local variant = context.variant

    StyleScope.assert('context.style_scope', scope, 2)
    Assert.string('context.property', property_name, 2)

    if context.instanceValue ~= nil then
        return context.instanceValue
    end

    local skin_variant = resolve_override_value(
        context.partSkin,
        scope:get_part(),
        property_name,
        variant
    )

    if skin_variant ~= nil then
        return skin_variant
    end

    local key_with_variant = scope:get_token_key(property_name, variant)
    local base_key = scope:get_token_key(property_name, nil)
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

function Resolver.token_key(scope, property_name, variant)
    StyleScope.assert('scope', scope, 2)
    return scope:get_token_key(property_name, variant)
end

return Resolver
