local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')

local enum_has = Enum.enum_has

local function normalize_disabled_values(values)
    local map = {}
    if values == nil then
        return map
    end

    Assert.table('RadioGroup.disabledValues', values, 3)
    for index = 1, #values do
        map[tostring(values[index])] = true
    end
    return map
end

return {
    value = Rule.any(),
    onValueChange = Rule.func({ optional = true }),
    orientation = Rule.custom(function(_, value, _, level)
        value = value or Enums.Orientation.VERTICAL
        if not enum_has(Enums.Orientation, value) then
            Assert.fail('RadioGroup.orientation must be "horizontal" or "vertical"', level or 1)
        end
        return value
    end, { default = Enums.Orientation.VERTICAL }),
    disabledValues = Rule.custom(function(_, value)
        normalize_disabled_values(value)
        return value
    end),
}
