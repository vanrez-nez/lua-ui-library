local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local Types = require('lib.ui.utils.types')
local Container = require('lib.ui.core.container')

local ControlSchema = {}

ControlSchema.rules = {}

function ControlSchema.required_string_value(control_name)
    return Rule.custom(function(name, value, level)
        if not Types.is_string(value) or value == '' then
            Assert.fail(tostring(control_name or name) .. '.value is required', level or 1)
        end
    end)
end

function ControlSchema.associated_content()
    return Rule.any_of({
        Rule.string(),
        Rule.instance(Container, 'Container')
    }, { optional = true })
end

function ControlSchema.positive_number(label, opts)
    opts = opts or {}
    return Rule.custom(function(_, value, level)
        if value == nil then
            return
        end

        Assert.number(label, value, level or 1)
        if value <= 0 then
            Assert.fail(tostring(label) .. ' must be > 0', level or 1)
        end
    end, opts)
end

function ControlSchema.non_negative_number(label, opts)
    opts = opts or {}
    return Rule.custom(function(_, value, level)
        if value == nil then
            return
        end

        Assert.number(label, value, level or 1)
        if value < 0 then
            Assert.fail(tostring(label) .. ' must be >= 0', level or 1)
        end
    end, opts)
end

function ControlSchema.optional_callback()
    return Rule.custom(function(name, value, level)
        if value ~= nil and not Types.is_function(value) then
            Assert.fail(tostring(name) .. ' must be a function', level or 1)
        end
    end, { optional = true })
end

return ControlSchema
