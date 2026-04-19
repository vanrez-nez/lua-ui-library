local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local Container = require('lib.ui.core.container')

local title_rule = Rule.any_of({
    Rule.string({ non_empty = true }),
    Rule.instance(Container, 'Container')
})

local optional_string_or_content_node_rule = Rule.any_of({
    Rule.string(),
    Rule.instance(Container, 'Container')
}, { optional = true })

return {
    title = title_rule,
    message = optional_string_or_content_node_rule,
    actions = Rule.table({ optional = true }),
    variant = Rule.enum(Enums.AlertVariant, { default = Enums.AlertVariant.DEFAULT }),
    initialFocus = Rule.string({ optional = true }),
}
