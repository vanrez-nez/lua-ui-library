local Assert = {}

function Assert.fail(message, level)
    error(message, (level or 1) + 1)
end

function Assert.boolean(name, value, level)
    if type(value) ~= 'boolean' then
        error(name .. ' must be a boolean', (level or 1) + 1)
    end
end

function Assert.number(name, value, level)
    if type(value) ~= 'number' then
        error(name .. ' must be a number', (level or 1) + 1)
    end
end

function Assert.string(name, value, level)
    if type(value) ~= 'string' then
        error(name .. ' must be a string', (level or 1) + 1)
    end
end

function Assert.table(name, value, level)
    if type(value) ~= 'table' then
        error(name .. ' must be a table', (level or 1) + 1)
    end
end

return Assert
