local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')

return {
    value = Rule.number(),
    min = Rule.number({ default = 0 }),
    max = Rule.number({ default = 1 }),
    indeterminate = Rule.boolean(false),
    orientation = Rule.enum(Enums.Orientation, { default = Enums.Orientation.HORIZONTAL }),
}
