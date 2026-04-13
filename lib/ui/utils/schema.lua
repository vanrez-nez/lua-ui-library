local Assert = require('lib.ui.utils.assert')
local Proxy = require('lib.ui.utils.proxy')
local Rule = require('lib.ui.utils.rule')

local Schema = {}
Schema.__index = Schema
Schema.VALIDATION_TIER = 'heavy'

local function validate_bound_rule_type(key, rule, value)
    if rule.type == 'string' then
        Assert.string(key, value, 3)
    elseif rule.type == 'boolean' then
        Assert.boolean(key, value, 3)
    elseif rule.type == 'number' then
        Assert.number(key, value, 3)
    elseif rule.type == 'table' then
        Assert.table(key, value, 3)
    elseif rule.type == 'userdata' then
        Assert.userdata(key, value, 3)
    elseif rule.type ~= nil and rule.type ~= 'any' then
        Assert.fail('Unknown schema rule type for "' .. tostring(key) .. '"', 3)
    end

    return value
end

local function get_bound_rule(target, key)
    local rules = target._schema_bound_rules
    if rules ~= nil then
        return rules[key]
    end
    return nil
end

local function validate_schema_write(k, v, t)
    local rule = get_bound_rule(t, k)
    local context_name = tostring(rawget(t, '_pclass') or getmetatable(t) or t)
    local full_key = context_name .. '.' .. tostring(k)

    if not Rule.tier_passes(rule.tier) then
        return v
    end

    if v == nil and not rule.required then
        return v
    end

    if v == nil and rule.required then
        error(('property "%s" is required'):format(k), 3)
    end

    if rule.validate then
        v = rule.validate(full_key, v, t, 3) or v
    else
        v = validate_bound_rule_type(full_key, rule, v)
    end

    return v
end

local function run_schema_set(v, k, t)
    local rule = get_bound_rule(t, k)
    rule.set(t, v)
end

function Schema:define(prop_defs)
    local instance = self._instance
    local bound_rules = instance._schema_bound_rules or {}

    rawset(instance, '_schema_bound_rules', bound_rules)
    self._prop_defs = prop_defs

    for key, rule in pairs(prop_defs) do
        Assert.table('schema rule "' .. tostring(key) .. '"', rule, 2)

        bound_rules[key] = rule
        Proxy.declare(instance, key)

        Proxy.on_pre_write(instance, key, validate_schema_write)

        if rule.set then
            Proxy.on_write(instance, key, run_schema_set)
        end

        if rule.default ~= nil then
            instance[key] = rule.default
        end
    end
end

function Schema:get_rule(key)
    return self._prop_defs and self._prop_defs[key] or nil
end

return setmetatable(Schema, {
    __call = function(cls, instance)
        return setmetatable({ _instance = instance }, cls)
    end,
})
