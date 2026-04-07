local Assert = require('lib.ui.utils.assert')
local Color = require('lib.ui.render.color')

local function validate_fill_color(_, value, _, _)
    return Color.resolve(value)
end

local function validate_fill_opacity(key, value, _, level)
    Assert.number(key, value, level)

    if value < 0 or value > 1 then
        Assert.fail(key .. ' must be in [0, 1], got ' .. value, level or 1)
    end

    return value
end

return {
    fillColor = { validate = validate_fill_color, default = { 1, 1, 1, 1 } },
    fillOpacity = { validate = validate_fill_opacity, default = 1 },
}
