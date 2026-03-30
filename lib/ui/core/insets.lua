local Assert = require('lib.ui.core.assert')

local abs = math.abs

local Insets = {}
Insets.__index = Insets

local function is_insets(value)
    return getmetatable(value) == Insets
end

local function new(top, right, bottom, left)
    top = top or 0
    right = right or 0
    bottom = bottom or 0
    left = left or 0

    Assert.number('top', top, 2)
    Assert.number('right', right, 2)
    Assert.number('bottom', bottom, 2)
    Assert.number('left', left, 2)

    return setmetatable({
        top = top,
        right = right,
        bottom = bottom,
        left = left,
    }, Insets)
end

local function normalize_table(value)
    if is_insets(value) then
        return value:clone()
    end

    if value.top ~= nil or value.right ~= nil or
        value.bottom ~= nil or value.left ~= nil then
        return new(
            value.top or 0,
            value.right or 0,
            value.bottom or 0,
            value.left or 0
        )
    end

    if #value == 2 then
        return new(value[1], value[2], value[1], value[2])
    end

    if #value == 4 then
        return new(value[1], value[2], value[3], value[4])
    end

    Assert.fail(
        'insets tables must use top/right/bottom/left or contain 2 or 4 values',
        2
    )
end

function Insets.new(top, right, bottom, left)
    return new(top, right, bottom, left)
end

function Insets.zero()
    return new(0, 0, 0, 0)
end

function Insets.normalize(value)
    if value == nil then
        return Insets.zero()
    end

    if type(value) == 'number' then
        return new(value, value, value, value)
    end

    if type(value) == 'table' then
        return normalize_table(value)
    end

    Assert.fail('insets must be nil, a number, or a table', 2)
end

function Insets.is_insets(value)
    return is_insets(value)
end

function Insets:clone()
    return new(self.top, self.right, self.bottom, self.left)
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

function Insets.__eq(left, right)
    return is_insets(left) and left:equals(right)
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

setmetatable(Insets, {
    __call = function(_, top, right, bottom, left)
        return new(top, right, bottom, left)
    end,
})

return Insets
