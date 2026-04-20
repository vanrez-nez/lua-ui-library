local Rule = require('lib.ui.utils.rule')

return {
    value = Rule.any(),
    onValueChange = Rule.func({ optional = true }),
    selectionStart = Rule.number(),
    selectionEnd = Rule.number(),
    onSelectionChange = Rule.func({ optional = true }),
    placeholder = Rule.any(),
    disabled = Rule.boolean(false),
    readOnly = Rule.boolean(false),
    maxLength = Rule.number(),
    inputMode = Rule.any({ default = 'text' }),
    submitBehavior = Rule.any({ default = 'blur' }),
    onSubmit = Rule.func({ optional = true }),
    font = Rule.any(),
    fontSize = Rule.number({ default = 16 }),
}
