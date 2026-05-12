local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Object = require('lib.cls')
local SideQuad = require('lib.ui.core.side_quad')

local abs = math.abs

local Insets = Object:extends('Insets')

function Insets:constructor(top, right, bottom, left)
    top = top or 0
    right = right or 0
    bottom = bottom or 0
    left = left or 0

    Assert.number('top', top, 3)
    Assert.number('right', right, 3)
    Assert.number('bottom', bottom, 3)
    Assert.number('left', left, 3)

    self.top = top
    self.right = right
    self.bottom = bottom
    self.left = left
end

local function is_insets(value)
    return Types.is_instance(value, Insets)
end

function Insets.new(top, right, bottom, left)
    return Insets(top, right, bottom, left)
end

function Insets.zero()
    return Insets(0, 0, 0, 0)
end

function Insets.normalize(value)
    if is_insets(value) then
        return value:clone()
    end

    return SideQuad.normalize(value, {
        label = 'insets',
        factory = function(top, right, bottom, left)
            return Insets(top, right, bottom, left)
        end,
    }, 2)
end

function Insets.is_insets(value)
    return is_insets(value)
end

function Insets:clone()
    return Insets(self.top, self.right, self.bottom, self.left)
end

function Insets:horizontal()
    return self.left + self.right
end

function Insets:vertical()
    return self.top + self.bottom
end

function Insets:equals(other, epsilon)
    if not is_insets(other) then
        return false
    end

    epsilon = epsilon or 0
    Assert.number('epsilon', epsilon, 2)

    return abs(self.top - other.top) <= epsilon and
        abs(self.right - other.right) <= epsilon and
        abs(self.bottom - other.bottom) <= epsilon and
        abs(self.left - other.left) <= epsilon
end

function Insets:unpack()
    return self.top, self.right, self.bottom, self.left
end

function Insets:__eq(other)
    if not is_insets(other) then return false end
    return self:equals(other)
end

function Insets:__tostring()
    return string.format(
        'Insets(top=%.6f, right=%.6f, bottom=%.6f, left=%.6f)',
        self.top,
        self.right,
        self.bottom,
        self.left
    )
end

return Insets
