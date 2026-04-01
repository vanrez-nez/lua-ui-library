local Assert = require('lib.ui.utils.assert')
local Insets = require('lib.ui.core.insets')

local STAGE_SCHEMA = {
    width = { type = 'number', default = 0 },
    height = { type = 'number', default = 0 },
    safeAreaInsets = { 
        validate = function(key, value) return Insets.normalize(value) end, 
        set = function(self) self:_handle_safe_area_change_internal() end,
        default = 0 
    },
}

return STAGE_SCHEMA
