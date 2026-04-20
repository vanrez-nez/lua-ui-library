local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')

local enum_has = Enum.enum_has

return {
    value = Rule.any(),
    onValueChange = Rule.any(),
    orientation = Rule.custom(function(_, value, _, level)
        value = value or Enums.Orientation.HORIZONTAL
        if not enum_has(Enums.Orientation, value) then
            Assert.fail('Tabs.orientation must be "horizontal" or "vertical"', level or 1)
        end
        return value
    end, { default = Enums.Orientation.HORIZONTAL }),
    activationMode = Rule.any({ default = 'manual' }),
    listScrollable = Rule.boolean(false),
    loopFocus = Rule.boolean(true),
    disabledValues = Rule.any(),
}
