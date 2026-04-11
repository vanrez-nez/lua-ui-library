local Insets = require('lib.ui.core.insets')
local Rule = require('lib.ui.utils.rule')

local STAGE_SCHEMA = {
    width = Rule.number({ default = 0 }),
    height = Rule.number({ default = 0 }),
    safeAreaInsets = Rule.normalize(function(value)
        return Insets.normalize(value)
    end, {
        set = function(self) self:_handle_safe_area_change_internal() end,
        default = 0,
    }),
}

return STAGE_SCHEMA
