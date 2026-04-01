local Assert = require('lib.ui.utils.assert')

local COMPOSER_SCHEMA = {
    defaultTransition = { type = 'any' },
    defaultTransitionDuration = { type = 'number', default = 0 },
}

local NAVIGATION_SCHEMA = {
    transition = { type = 'any' },
    duration = { type = 'number' },
    params = { type = 'table' },
}

return {
    composer = COMPOSER_SCHEMA,
    navigation = NAVIGATION_SCHEMA,
}
