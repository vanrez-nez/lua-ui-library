local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local ControlSchema = require('lib.ui.controls.control_schema')

return {
    open = Rule.boolean({ optional = true }),
    onOpenChange = ControlSchema.optional_callback(),
    -- Spec: ui-controls 6.15 props/defaults: "button" | "auto-dismiss", default "button".
    closeMethod = Rule.enum({ 'button', 'auto-dismiss' }, { default = 'button' }),
    duration = Rule.number({ optional = true }),
    stackable = Rule.boolean(true),
    edge = Rule.enum(Enums.Edge, { default = Enums.Edge.TOP }),
    align = Rule.enum(Enums.SourceAlign, { default = Enums.SourceAlign.CENTER }),
    safeAreaAware = Rule.boolean(true),
    content = Rule.table({ optional = true }),
}
