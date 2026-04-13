local Object = require('lib.cls')
local Types = {}

function Types.is_boolean(value)
    return type(value) == 'boolean'
end

function Types.is_number(value)
    return type(value) == 'number'
end

function Types.is_string(value)
    return type(value) == 'string'
end

function Types.is_table(value)
    return type(value) == 'table'
end

function Types.is_function(value)
    return type(value) == 'function'
end

function Types.is_nil(value)
    return type(value) == 'nil'
end

function Types.is_thread(value)
    return type(value) == 'thread'
end

function Types.is_userdata(value)
    return type(value) == 'userdata'
end

function Types.is_instance(value, class_obj)
    return Object.is(value, class_obj)
end

return Types
