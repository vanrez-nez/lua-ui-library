local Assert = require('lib.ui.utils.assert')
local Color = require('lib.ui.render.color')
local SpacingSchema = require('lib.ui.core.spacing_schema')

local check_finite_number = SpacingSchema.check_finite_number

local function validate_opacity(key, value, _, level)
    check_finite_number(key, value, level)

    if value < 0 or value > 1 then
        Assert.fail(key .. ' must be in [0, 1], got ' .. value, level or 1)
    end

    return value
end

local function validate_fill_color(_, value, _, _)
    return Color.resolve(value)
end

local function validate_stroke_width(key, value, _, level)
    check_finite_number(key, value, level)

    if value < 0 then
        Assert.fail(key .. ' must be >= 0, got ' .. value, level or 1)
    end

    return value
end

local function validate_positive_finite(key, value, _, level)
    check_finite_number(key, value, level)

    if value <= 0 then
        Assert.fail(key .. ' must be > 0, got ' .. value, level or 1)
    end

    return value
end

local function validate_non_negative_finite(key, value, _, level)
    check_finite_number(key, value, level)

    if value < 0 then
        Assert.fail(key .. ' must be >= 0, got ' .. value, level or 1)
    end

    return value
end

local function validate_enum(key, value, _, level, allowed)
    for index = 1, #allowed do
        if value == allowed[index] then
            return value
        end
    end

    Assert.fail(
        key .. ": '" .. tostring(value) .. "' is not a valid value — accepted: " .. table.concat(allowed, ', '),
        level or 1
    )
end

local function validate_stroke_style(key, value, _, level)
    return validate_enum(key, value, nil, level, { 'smooth', 'rough' })
end

local function validate_stroke_join(key, value, _, level)
    return validate_enum(key, value, nil, level, { 'miter', 'bevel', 'none' })
end

local function validate_stroke_pattern(key, value, _, level)
    return validate_enum(key, value, nil, level, { 'solid', 'dashed' })
end

return {
    fillColor = { validate = validate_fill_color, default = { 1, 1, 1, 1 } },
    fillOpacity = { validate = validate_opacity, default = 1 },
    strokeColor = { validate = validate_fill_color },
    strokeOpacity = { validate = validate_opacity, default = 1 },
    strokeWidth = { validate = validate_stroke_width, default = 0 },
    strokeStyle = { validate = validate_stroke_style, default = 'smooth' },
    strokeJoin = { validate = validate_stroke_join, default = 'miter' },
    strokeMiterLimit = { validate = validate_positive_finite, default = 10 },
    strokePattern = { validate = validate_stroke_pattern, default = 'solid' },
    strokeDashLength = { validate = validate_positive_finite, default = 8 },
    strokeGapLength = { validate = validate_non_negative_finite, default = 4 },
    strokeDashOffset = { validate = check_finite_number, default = 0 },
    opacity = { validate = validate_opacity, default = 1 },
}
