local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')

local Direction = {}

local VALID_VALUES = {
    ltr = true,
    rtl = true,
}

local function invoke_mark_dirty(ctx)
    local method = rawget(ctx, 'markDirty')
    local current = rawget(ctx, '_pclass') or getmetatable(ctx)

    while method == nil and current ~= nil do
        method = rawget(current, 'markDirty')
        current = rawget(current, 'super')
    end

    if method ~= nil then
        method(ctx)
    end
end

function Direction.validate(kind, value, level)
    if not Types.is_string(value) or not VALID_VALUES[value] then
        Assert.fail(kind .. '.direction must be "ltr" or "rtl"', level or 1)
    end

    return value
end

function Direction.schema_rule(kind)
    return Rule.custom(function(_, value, _, level)
            return Direction.validate(kind, value, level)
        end, {
        default = 'ltr',
        set = function(ctx) invoke_mark_dirty(ctx) end,
    })
end

return Direction
