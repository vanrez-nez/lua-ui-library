local Rule = require('lib.ui.utils.rule')

return {
    -- Spec: ui-controls 6.11 props: string | nil; uncontrolled default is empty string.
    value = Rule.string({ optional = true }),
    onValueChange = Rule.func({ optional = true }),
    selectionStart = Rule.number(),
    selectionEnd = Rule.number(),
    onSelectionChange = Rule.func({ optional = true }),
    -- Spec: ui-controls 6.11 props: string | nil.
    placeholder = Rule.string({ optional = true }),
    disabled = Rule.boolean(false),
    readOnly = Rule.boolean(false),
    maxLength = Rule.number(),
    -- Spec: ui-controls 6.11 props: "text" | "numeric" | "email" | "url" | "search".
    inputMode = Rule.enum({ 'text', 'numeric', 'email', 'url', 'search' }, { default = 'text' }),
    -- Spec: ui-controls 6.11 props: "blur" | "submit" | "none".
    submitBehavior = Rule.enum({ 'blur', 'submit', 'none' }, { default = 'blur' }),
    onSubmit = Rule.func({ optional = true }),
    -- Spec: foundation token class includes font; TextInput does not yet define concrete public value shape.
    font = Rule.any(),
    fontSize = Rule.number({ default = 16 }),
}
