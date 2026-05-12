local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')
local ControlSchema = require('lib.ui.controls.control_schema')

local enum = Enum.enum

local TriggerMode = enum(
    { HOVER = 'hover' },
    { FOCUS = 'focus' },
    { HOVER_FOCUS = 'hover-focus' },
    { MANUAL = 'manual' }
)

return {
    open = Rule.boolean({ optional = true }),
    onOpenChange = ControlSchema.optional_callback(),
    placement = Rule.enum(Enums.Edge, { default = Enums.Edge.TOP }),
    align = Rule.enum(Enums.SourceAlign, { default = Enums.SourceAlign.CENTER }),
    offset = Rule.number({ default = 8 }),
    triggerMode = Rule.enum(TriggerMode, { default = TriggerMode.HOVER_FOCUS }),
    safeAreaAware = Rule.boolean(true),
    trigger = Rule.table({ optional = true }),
    content = Rule.table({ optional = true }),
}
