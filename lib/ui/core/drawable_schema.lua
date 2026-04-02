local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Insets = require('lib.ui.core.insets')
local Motion = require('lib.ui.motion')

local ALIGNMENT_VALUES = {
    start = true,
    center = true,
    ['end'] = true,
    stretch = true,
}

local function validate_alignment(key, value, ctx, level)
    if not Types.is_string(value) or not ALIGNMENT_VALUES[value] then
        Assert.fail(
            'Drawable.' .. key .. ' must be "start", "center", "end", or "stretch"',
            level or 1
        )
    end
    return value
end

local DRAWABLE_SCHEMA = {
    padding = { validate = function(key, value) return Insets.normalize(value) end, default = 0 },
    margin = { validate = function(key, value) return Insets.normalize(value) end, default = 0 },
    alignX = { validate = validate_alignment, default = 'start' },
    alignY = { validate = validate_alignment, default = 'start' },
    skin = { type = 'table' },
    shader = { type = 'any' },
    opacity = { type = 'number', default = 1 },
    blendMode = { type = 'string' },
    mask = { type = 'table' },
    motionPreset = { validate = Motion.validate_motion_preset },
    motion = { validate = Motion.validate_motion },
}

return DRAWABLE_SCHEMA
