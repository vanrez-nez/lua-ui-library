local Rule = require('lib.ui.utils.rule')

local COMPOSER_SCHEMA = {
    -- Spec: foundation 6.4.3 stabilizes the concept only; concrete transition values are internal.
    defaultTransition = Rule.any(),
    defaultTransitionDuration = Rule.number({ default = 0 }),
}

local NAVIGATION_SCHEMA = {
    -- Spec: foundation 6.4.3 stabilizes the concept only; concrete transition values are internal.
    transition = Rule.any(),
    duration = Rule.number(),
    params = Rule.table(),
}

return {
    composer = COMPOSER_SCHEMA,
    navigation = NAVIGATION_SCHEMA,
}
