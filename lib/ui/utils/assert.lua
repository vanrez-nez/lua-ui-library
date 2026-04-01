local Types = require('lib.ui.utils.types')
local Assert = {}

function Assert.fail(message, level)
    error(message, (level or 1) + 1)
end

function Assert.boolean(name, value, level)
    if not Types.is_boolean(value) then
        error(name .. ' must be a boolean', (level or 1) + 1)
    end
end

function Assert.number(name, value, level)
    if not Types.is_number(value) then
        error(name .. ' must be a number', (level or 1) + 1)
    end
end

function Assert.string(name, value, level)
    if not Types.is_string(value) then
        error(name .. ' must be a string', (level or 1) + 1)
    end
end

function Assert.table(name, value, level)
    if not Types.is_table(value) then
        error(name .. ' must be a table', (level or 1) + 1)
    end
end

function Assert.userdata(name, value, level)
    if not Types.is_userdata(value) then
        error(name .. ' must be a userdata', (level or 1) + 1)
    end
end

function Assert.is_instance(name, value, class_obj, class_name, level)
    if not Types.is_instance(value, class_obj) then
        error(name .. ' must be an instance of ' .. class_name, (level or 1) + 1)
    end
end

function Assert.not_destroyed(name, value, level)
    if not Types.not_destroyed(value) then
        error(name .. ' must not be destroyed', (level or 1) + 1)
    end
end

return Assert
