local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')

local Direction = {}
local enum_has = Enum.enum_has

function Direction.validate(kind, value, level)
    if not Types.is_string(value) or not enum_has(Enums.Direction, value) then
        Assert.fail(kind .. '.direction must be "ltr" or "rtl"', level or 1)
    end

    return value
end

function Direction.schema_rule(kind)
    return Rule.custom(function(_, value, _, level)
            return Direction.validate(kind, value, level)
        end, { default = Enums.Direction.LTR })
end

return Direction
