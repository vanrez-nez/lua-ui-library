local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local Direction = {}

local VALID_VALUES = {
    ltr = true,
    rtl = true,
}

function Direction.validate(kind, value, level)
    if not Types.is_string(value) or not VALID_VALUES[value] then
        Assert.fail(kind .. '.direction must be "ltr" or "rtl"', level or 1)
    end

    return value
end

function Direction.schema_rule(kind)
    return {
        validate = function(_, value, _, level)
            return Direction.validate(kind, value, level)
        end,
        default = 'ltr',
        set = function(ctx) ctx:markDirty() end,
    }
end

return Direction
