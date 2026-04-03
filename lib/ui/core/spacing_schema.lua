local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Insets = require('lib.ui.core.insets')
local SideQuad = require('lib.ui.core.side_quad')

local SpacingSchema = {}

function SpacingSchema.check_finite_number(key, value, level)
    if not Types.is_number(value) then
        Assert.fail(key .. ' must be a number', level or 1)
    end

    if value ~= value or value == math.huge or value == -math.huge then
        Assert.fail(key .. ' must be finite, got ' .. tostring(value), level or 1)
    end

    return value
end

function SpacingSchema.check_non_negative_finite(key, value, level)
    SpacingSchema.check_finite_number(key, value, level)

    if value < 0 then
        Assert.fail(key .. ' must be >= 0, got ' .. tostring(value), level or 1)
    end

    return value
end

local function build_insets(top, right, bottom, left)
    return Insets.new(top, right, bottom, left)
end

function SpacingSchema.normalize_padding(label, value, level)
    return SideQuad.normalize(value, {
        label = label,
        validate_member = SpacingSchema.check_non_negative_finite,
        factory = build_insets,
    }, level or 1)
end

function SpacingSchema.normalize_margin(label, value, level)
    return SideQuad.normalize(value, {
        label = label,
        validate_member = SpacingSchema.check_finite_number,
        factory = build_insets,
    }, level or 1)
end

return SpacingSchema
