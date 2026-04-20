local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')

return {
    open = Rule.boolean(),
    onOpenChange = Rule.func({ optional = true }),
    -- Spec: ui-controls 6.15 props/defaults: "button" | "auto-dismiss", default "button".
    closeMethod = Rule.enum({ 'button', 'auto-dismiss' }, { default = 'button' }),
    duration = Rule.number(),
    stackable = Rule.boolean(true),
    edge = Rule.enum(Enums.Edge, { default = Enums.Edge.TOP }),
    align = Rule.enum(Enums.SourceAlign, { default = Enums.SourceAlign.CENTER }),
    safeAreaAware = Rule.boolean(true),
}
