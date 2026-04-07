local Shape = require('lib.ui.core.shape')

local RectShape = Shape:extends('RectShape')

function RectShape:constructor(opts)
    Shape.constructor(self, opts)
end

function RectShape.new(opts)
    return RectShape(opts)
end

return RectShape
