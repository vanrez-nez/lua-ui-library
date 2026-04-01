local Utils = {}

function Utils.copy_array(values)
    if values == nil then
        return nil
    end
    local copy = {}
    for index = 1, #values do
        copy[index] = values[index]
    end
    return copy
end

function Utils.copy_table(values)
    if values == nil then
        return nil
    end
    local copy = {}
    for key, value in pairs(values) do
        copy[key] = value
    end
    return copy
end

function Utils.merge_tables(target, source)
    if source == nil then
        return target
    end
    for k, v in pairs(source) do
        target[k] = v
    end
    return target
end

return Utils
