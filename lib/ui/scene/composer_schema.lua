local Rule = require('lib.ui.utils.rule')

local COMPOSER_SCHEMA = {
    defaultTransition = Rule.any(),
    defaultTransitionDuration = Rule.number({ default = 0 }),
}

local NAVIGATION_SCHEMA = {
    transition = Rule.any(),
    duration = Rule.number(),
    params = Rule.table(),
}

return {
    composer = COMPOSER_SCHEMA,
    navigation = NAVIGATION_SCHEMA,
}
