local Rule = require('lib.ui.utils.rule')
local ControlSchema = require('lib.ui.controls.control_schema')

return {
    value = ControlSchema.required_string_value('Radio'),
    disabled = Rule.boolean(false),
    label = ControlSchema.associated_content(),
    description = ControlSchema.associated_content(),
}
