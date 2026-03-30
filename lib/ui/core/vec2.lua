local Assert = require('lib.ui.core.assert')

local abs = math.abs
local sqrt = math.sqrt

local Vec2 = {}
Vec2.__index = Vec2

local function is_vec2(value)
    return getmetatable(value) == Vec2
end

local function assert_vec2(name, value)
    if not is_vec2(value) then
        Assert.fail(name .. ' must be a Vec2', 2)
    end
end

local function new(x, y)
    x = x or 0
    y = y or 0

    Assert.number('x', x, 2)
    Assert.number('y', y, 2)

    return setmetatable({
        x = x,
        y = y,
    }, Vec2)
end

function Vec2.new(x, y)
    return new(x, y)
end

function Vec2.is_vec2(value)
    return is_vec2(value)
end

function Vec2:clone()
    return new(self.x, self.y)
end

function Vec2:add(other)
    assert_vec2('other', other)
    return new(self.x + other.x, self.y + other.y)
end

function Vec2:subtract(other)
    assert_vec2('other', other)
    return new(self.x - other.x, self.y - other.y)
end

function Vec2:scale(scalar)
    Assert.number('scalar', scalar, 2)
    return new(self.x * scalar, self.y * scalar)
end

function Vec2:multiply(other)
    if type(other) == 'number' then
        return self:scale(other)
    end

    assert_vec2('other', other)
    return new(self.x * other.x, self.y * other.y)
end

function Vec2:dot(other)
    assert_vec2('other', other)
    return self.x * other.x + self.y * other.y
end

function Vec2:length_squared()
    return self.x * self.x + self.y * self.y
end

function Vec2:length()
    return sqrt(self:length_squared())
end

function Vec2:normalize()
    local length = self:length()

    if length == 0 then
        return new(0, 0)
    end

    return new(self.x / length, self.y / length)
end

function Vec2:distance_squared(other)
    assert_vec2('other', other)

    local dx = self.x - other.x
    local dy = self.y - other.y
    return dx * dx + dy * dy
end

function Vec2:distance(other)
    return sqrt(self:distance_squared(other))
end

function Vec2:lerp(other, t)
    assert_vec2('other', other)
    Assert.number('t', t, 2)

    return new(
        self.x + (other.x - self.x) * t,
        self.y + (other.y - self.y) * t
    )
end

function Vec2:equals(other, epsilon)
    if not is_vec2(other) then
        return false
    end

    epsilon = epsilon or 0
    Assert.number('epsilon', epsilon, 2)

    return abs(self.x - other.x) <= epsilon and
        abs(self.y - other.y) <= epsilon
end

function Vec2:unpack()
    return self.x, self.y
end

function Vec2.__add(left, right)
    return left:add(right)
end

function Vec2.__sub(left, right)
    return left:subtract(right)
end

function Vec2.__mul(left, right)
    if type(left) == 'number' and is_vec2(right) then
        return right:scale(left)
    end

    if is_vec2(left) then
        return left:multiply(right)
    end

    Assert.fail(
        'Vec2 multiplication expects a Vec2 and a number or another Vec2',
        2
    )
end

function Vec2.__unm(value)
    assert_vec2('value', value)
    return new(-value.x, -value.y)
end

function Vec2.__eq(left, right)
    return is_vec2(left) and left:equals(right)
end

function Vec2:__tostring()
    return string.format('Vec2(%.6f, %.6f)', self.x, self.y)
end

setmetatable(Vec2, {
    __call = function(_, x, y)
        return new(x, y)
    end,
})

return Vec2
