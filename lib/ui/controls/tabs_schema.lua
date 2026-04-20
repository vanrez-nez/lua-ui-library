local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')

local enum_has = Enum.enum_has

return {
    -- Spec: ui-controls 6.17 props: string | nil; value maps to one trigger/panel pair.
    value = Rule.string({ optional = true }),
    onValueChange = Rule.func({ optional = true }),
    orientation = Rule.custom(function(_, value, _, level)
        value = value or Enums.Orientation.HORIZONTAL
        if not enum_has(Enums.Orientation, value) then
            Assert.fail('Tabs.orientation must be "horizontal" or "vertical"', level or 1)
        end
        return value
    end, { default = Enums.Orientation.HORIZONTAL }),
    -- Spec: ui-controls 6.17 props/errors: "manual" only in this revision.
    activationMode = Rule.enum({ 'manual' }, { default = 'manual' }),
    listScrollable = Rule.boolean(false),
    loopFocus = Rule.boolean(true),
    -- Spec: ui-controls 6.17 props: table | nil of disabled tab values.
    disabledValues = Rule.table({ optional = true, items = Rule.string() }),
}
