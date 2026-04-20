local Texture = require('lib.ui.graphics.texture')
local Sprite = require('lib.ui.graphics.sprite')
local Rule = require('lib.ui.utils.rule')
local Constants = require('lib.ui.core.constants')
local Enum = require('lib.ui.utils.enum')

local enum = Enum.enum

local Fit = enum(
    { CONTAIN = 'contain' },
    { COVER = 'cover' },
    { STRETCH = 'stretch' },
    { NONE = 'none' }
)

local Align = enum(
    { START = Constants.ALIGN_START },
    { CENTER = Constants.ALIGN_CENTER },
    { END = Constants.ALIGN_END }
)

local Sampling = enum(
    { NEAREST = 'nearest' },
    { LINEAR = 'linear' }
)

return {
    source = Rule.any_of({
        Rule.instance(Texture, 'Texture'),
        Rule.instance(Sprite, 'Sprite'),
    }),
    fit = Rule.enum(Fit, { default = Fit.CONTAIN }),
    alignX = Rule.enum(Align, { default = Align.CENTER }),
    alignY = Rule.enum(Align, { default = Align.CENTER }),
    sampling = Rule.enum(Sampling, { default = Sampling.LINEAR }),
    decorative = Rule.boolean(false),
    accessibleName = Rule.string({ optional = true }),
}
