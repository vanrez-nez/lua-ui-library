local Rule = require('lib.ui.utils.rule')
local CustomRules = require('lib.ui.schema.custom_rules')

local STAGE_SCHEMA = {
    width = Rule.number({ default = 0 }),
    height = Rule.number({ default = 0 }),
    safeAreaInsets = CustomRules.padding({ default = 0 }),
}

return STAGE_SCHEMA
