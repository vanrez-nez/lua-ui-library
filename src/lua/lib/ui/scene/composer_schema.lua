local Rule = require('lib.ui.utils.rule')

local function any_rule(opts)
    return Rule.custom(function()
    end, opts)
end

local COMPOSER_SCHEMA = {
    -- Spec: foundation 6.4.3 stabilizes the concept only; concrete transition values are internal.
    defaultTransition = any_rule({ optional = true }),
    defaultTransitionDuration = Rule.number({ default = 0 }),
}

local NAVIGATION_SCHEMA = {
    -- Spec: foundation 6.4.3 stabilizes the concept only; concrete transition values are internal.
    transition = any_rule({ optional = true }),
    duration = Rule.number(),
    params = Rule.table(),
}

return {
    composer = COMPOSER_SCHEMA,
    navigation = NAVIGATION_SCHEMA,
}
