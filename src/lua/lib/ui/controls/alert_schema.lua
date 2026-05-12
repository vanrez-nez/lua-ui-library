local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local Container = require('lib.ui.core.container')

return {
    title = Rule.any_of({
        Rule.string({ non_empty = true }),
        Rule.instance(Container, 'Container')
    }),
    message = Rule.any_of({
        Rule.string(),
        Rule.instance(Container, 'Container')
    }, { optional = true }),
    actions = Rule.table({ optional = true }),
    variant = Rule.enum(Enums.AlertVariant, { default = Enums.AlertVariant.DEFAULT }),
    initialFocus = Rule.string({ optional = true }),
}
