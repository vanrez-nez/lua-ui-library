local Rule = require('lib.ui.utils.rule')
local ControlSchema = require('lib.ui.controls.control_schema')

return {
    pressed = Rule.boolean({ optional = true }),
    onPressedChange = ControlSchema.optional_callback(),
    onActivate = ControlSchema.optional_callback(),
    disabled = Rule.boolean(false),
    content = ControlSchema.associated_content(),
}
