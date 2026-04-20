local Rule = require('lib.ui.utils.rule')

return {
    value = Rule.any(),
    onValueChange = Rule.any(),
    selectionStart = Rule.number(),
    selectionEnd = Rule.number(),
    onSelectionChange = Rule.any(),
    placeholder = Rule.any(),
    disabled = Rule.boolean(false),
    readOnly = Rule.boolean(false),
    maxLength = Rule.number(),
    inputMode = Rule.any({ default = 'text' }),
    submitBehavior = Rule.any({ default = 'blur' }),
    onSubmit = Rule.any(),
    font = Rule.any(),
    fontSize = Rule.number({ default = 16 }),
}
