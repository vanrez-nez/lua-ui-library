local Rule = require('lib.ui.utils.rule')

return {
    pressed = Rule.boolean(),
    onPressedChange = Rule.func({ optional = true }),
    onActivate = Rule.func({ optional = true }),
    disabled = Rule.boolean(false),
}
