local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')

local Schema = {}

function Schema.validate(schema, key, value, ctx_obj, level, ctx_name)
    level = (level or 1) + 1
    local rule = schema[key]
    local full_key = (ctx_name and (ctx_name .. '.' .. key)) or key
    
    if Types.is_nil(rule) then
        Assert.fail('Unsupported prop "' .. tostring(key) .. '"', level)
    end

    if Types.is_nil(value) and not rule.required then
        return value
    end

    if Types.is_nil(value) and rule.required then
        Assert.fail('Prop "' .. tostring(key) .. '" is required', level)
    end

    if Types.is_boolean(rule) then
        return value
    end

    if rule.type == 'string' then
        Assert.string(full_key, value, level)
    elseif rule.type == 'boolean' then
        Assert.boolean(full_key, value, level)
    elseif rule.type == 'number' then
        Assert.number(full_key, value, level)
    elseif rule.type == 'table' then
        Assert.table(full_key, value, level)
    elseif rule.type == 'userdata' then
        Assert.userdata(full_key, value, level)
    elseif rule.type == 'any' then
        -- No validation needed
    elseif Types.is_function(rule.validate) then
        return rule.validate(full_key, value, ctx_obj, level, full_opts)
    else
        Assert.fail('Unknown schema rule type for "' .. tostring(full_key) .. '"', level)
    end
    
    return value
end

function Schema.validate_all(schema, opts, ctx_obj, level, ctx_name)
    level = (level or 1) + 1
    local validated = {}
    for key, value in pairs(opts) do
        validated[key] = Schema.validate(schema, key, value, ctx_obj, level, ctx_name, opts)
    end
    return validated
end

function Schema.merge(base, overrides)
    local result = {}
    if Types.is_table(base) then
        for k, v in pairs(base) do result[k] = v end
    end
    if Types.is_table(overrides) then
        for k, v in pairs(overrides) do result[k] = v end
    end
    return result
end

function Schema.extract_defaults(schema, ctx_obj, ctx_name)
    Assert.table('schema', schema, 2)
    local defaults = {}
    for k, rule in pairs(schema) do
        if not Types.is_nil(rule) and not Types.is_boolean(rule) and not Types.is_nil(rule.default) then
            local val = rule.default
            if type(rule) == 'table' and Types.is_function(rule.validate) then
                -- Run validator for defaults to ensure correct type (e.g. Insets)
                local full_key = (ctx_name and (ctx_name .. '.' .. k)) or k
                val = rule.validate(full_key, val, ctx_obj, 2)
            end
            defaults[k] = val
        end
    end
    return defaults
end

-- Custom common validators

function Schema.validate_size(key, value, allow_content, level)
    if value == 'content' then
        if not allow_content then
            Assert.fail(tostring(key) .. '="content" is only supported by layout nodes with an intrinsic measurement rule', level + 1)
        end
        return value
    end

    if value == 'fill' or Types.is_number(value) then
        return value
    end

    if MathUtils.is_percentage_string(value) then
        return value
    end

    Assert.fail(
        key .. ' must be a number, "content", "fill", or a percentage string',
        level or 1
    )
end

return Schema
