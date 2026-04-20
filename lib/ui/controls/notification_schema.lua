local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')

return {
    open = Rule.boolean(),
    onOpenChange = Rule.func({ optional = true }),
    closeMethod = Rule.any({ default = 'button' }),
    duration = Rule.number(),
    stackable = Rule.boolean(true),
    edge = Rule.enum(Enums.Edge, { default = Enums.Edge.TOP }),
    align = Rule.enum(Enums.SourceAlign, { default = Enums.SourceAlign.CENTER }),
    safeAreaAware = Rule.boolean(true),
}
