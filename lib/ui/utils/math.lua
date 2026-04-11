local Types = require('lib.ui.utils.types')
local max = math.max
local tonumber = tonumber

local MathUtils = {}

function MathUtils.is_percentage_string(value)
    if not Types.is_string(value) then
        return false
    end

    return value:match('^[+-]?%d*%.?%d+%%$') ~= nil
end

function MathUtils.default(value, fallback)
    if value == nil then
        return fallback
    end

    return value
end

function MathUtils.clamp(value, min_value, max_value)
    if min_value ~= nil and max_value ~= nil and min_value > max_value then
        return min_value
    end

    if min_value ~= nil and value < min_value then
        value = min_value
    end

    if max_value ~= nil and value > max_value then
        value = max_value
    end

    return value
end

function MathUtils.clamp_number(value, min_value, max_value)
    if min_value ~= nil and value < min_value then
        value = min_value
    end

    if max_value ~= nil and value > max_value then
        value = max_value
    end

    return max(0, value)
end

function MathUtils.positive_mod(value, modulus)
    if modulus == nil or modulus <= 0 then
        return 0
    end

    local result = value % modulus
    if result < 0 then
        result = result + modulus
    end

    return result
end

function MathUtils.parse_percentage(value)
    if not MathUtils.is_percentage_string(value) then
        return nil
    end

    return tonumber(value:sub(1, -2)) / 100
end

function MathUtils.resolve_axis_size(configured, parent_size)
    if Types.is_number(configured) then
        return configured
    end

    local percentage = MathUtils.parse_percentage(configured)

    if percentage ~= nil then
        return (parent_size or 0) * percentage
    end

    return 0
end

return MathUtils
