local Env = {}

function Env.parse_boolean(name, fallback)
    local raw_value = os.getenv(name)
    if raw_value == nil then
        return fallback
    end

    raw_value = tostring(raw_value):lower()
    if raw_value == '1' or raw_value == 'true' or raw_value == 'yes' or raw_value == 'on' then
        return true
    end

    if raw_value == '0' or raw_value == 'false' or raw_value == 'no' or raw_value == 'off' then
        return false
    end

    return fallback
end

function Env.parse_positive_integer(name, fallback)
    local value = tonumber(os.getenv(name) or '')

    if value == nil then
        return fallback
    end

    value = math.floor(value)
    if value <= 0 then
        return fallback
    end

    return value
end

function Env.parse_enum(name, allowed_values, fallback)
    local value = tostring(os.getenv(name) or ''):lower()

    if allowed_values[value] == true then
        return value
    end

    return fallback
end

return Env
