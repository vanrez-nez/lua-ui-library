local Rule = require('lib.ui.utils.rule')
local ControlSchema = require('lib.ui.controls.control_schema')

return {
    -- Spec: ui-controls 6.11 props: string | nil; uncontrolled default is empty string.
    value = Rule.string({ optional = true }),
    onValueChange = ControlSchema.optional_callback(),
    selectionStart = Rule.number({ optional = true }),
    selectionEnd = Rule.number({ optional = true }),
    onSelectionChange = ControlSchema.optional_callback(),
    -- Spec: ui-controls 6.11 props: string | nil.
    placeholder = Rule.string({ optional = true }),
    disabled = Rule.boolean(false),
    readOnly = Rule.boolean(false),
    maxLength = Rule.number({ optional = true }),
    -- Spec: ui-controls 6.11 props: "text" | "numeric" | "email" | "url" | "search".
    inputMode = Rule.enum({ 'text', 'numeric', 'email', 'url', 'search' }, { default = 'text' }),
    -- Spec: ui-controls 6.11 props: "blur" | "submit" | "none".
    submitBehavior = Rule.enum({ 'blur', 'submit', 'none' }, { default = 'blur' }),
    onSubmit = ControlSchema.optional_callback(),
    -- Spec: foundation token class includes font; TextInput does not yet define concrete public value shape.
    font = Rule.custom(function() end, { optional = true }),
    fontSize = Rule.number({ default = 16 }),
}
