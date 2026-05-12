local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')
local ControlSchema = require('lib.ui.controls.control_schema')

local enum_has = Enum.enum_has

return {
    -- Spec: ui-controls 6.5 props: string | nil; value must resolve against registered Radio values.
    value = Rule.string({ optional = true }),
    onValueChange = ControlSchema.optional_callback(),
    orientation = Rule.custom(function(_, value, _, level)
        value = value or Enums.Orientation.VERTICAL
        if not enum_has(Enums.Orientation, value) then
            Assert.fail('RadioGroup.orientation must be "horizontal" or "vertical"', level or 1)
        end
        return value
    end, { default = Enums.Orientation.VERTICAL }),
    disabledValues = Rule.table({ optional = true, items = Rule.string() }),
}
