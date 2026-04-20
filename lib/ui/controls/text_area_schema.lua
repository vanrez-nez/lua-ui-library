local Rule = require('lib.ui.utils.rule')

return {
    wrap = Rule.boolean(true),
    rows = Rule.number(),
    scrollXEnabled = Rule.boolean(false),
    scrollYEnabled = Rule.boolean(true),
    momentum = Rule.boolean(false),
}
