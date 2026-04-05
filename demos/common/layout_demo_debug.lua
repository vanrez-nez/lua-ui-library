local Debug = {}

function Debug.entry(key, value)
    return {
        key = key,
        value = value,
    }
end

function Debug.group(key, entries)
    return {
        key = key,
        entries = entries,
    }
end

local function format_entries(entries)
    local parts = {}

    for index = 1, #entries do
        local entry = entries[index]
        parts[#parts + 1] = string.format('%s=%s', entry.key, tostring(entry.value))
    end

    return table.concat(parts, ' ')
end

function Debug.dump(screen_name, parts)
    local output = {}

    for index = 1, #parts do
        local part = parts[index]

        if part.entries ~= nil then
            output[#output + 1] = string.format(
                '%s={%s}',
                part.key,
                format_entries(part.entries)
            )
        else
            output[#output + 1] = string.format(
                '%s=%s',
                part.key,
                tostring(part.value)
            )
        end
    end

    print(string.format('[%s] %s', screen_name, table.concat(output, ' ')))
end

return Debug
