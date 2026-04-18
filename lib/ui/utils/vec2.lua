local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Object = require('lib.cls')

local abs = math.abs
local sqrt = math.sqrt

local Vec2 = Object:extends('Vec2')

--- @param x number
--- @param y number
function Vec2:constructor(x, y)
    x = x or 0
    y = y or 0

    Assert.number('x', x, 3)
    Assert.number('y', y, 3)

    self.x = x
    self.y = y
end

--- @param x number
--- @param y number
--- @return Vec2
function Vec2.new(x, y)
    return Vec2(x, y)
end

--- @param value any
--- @return boolean
function Vec2.is_vec2(value)
    return Types.is_instance(value, Vec2)
end

--- @return Vec2
function Vec2:clone()
    return Vec2(self.x, self.y)
end

--- @param other Vec2
--- @return Vec2
function Vec2:add(other)
    if not Vec2.is_vec2(other) then
        Assert.fail('other must be a Vec2', 2)
    end
    return Vec2(self.x + other.x, self.y + other.y)
end

--- @param other Vec2
--- @return Vec2
function Vec2:subtract(other)
    if not Vec2.is_vec2(other) then
        Assert.fail('other must be a Vec2', 2)
    end
    return Vec2(self.x - other.x, self.y - other.y)
end

--- @param scalar number
--- @return Vec2
function Vec2:scale(scalar)
    Assert.number('scalar', scalar, 2)
    return Vec2(self.x * scalar, self.y * scalar)
end

--- @param other Vec2|number
--- @return Vec2
function Vec2:multiply(other)
    if Types.is_number(other) then
        return self:scale(other)
    end

    if not Vec2.is_vec2(other) then
        Assert.fail('other must be a Vec2', 2)
    end
    return Vec2(self.x * other.x, self.y * other.y)
end

--- @param other Vec2
--- @return number
function Vec2:dot(other)
    if not Vec2.is_vec2(other) then
        Assert.fail('other must be a Vec2', 2)
    end
    return self.x * other.x + self.y * other.y
end

--- @return number
function Vec2:length_squared()
    return self.x * self.x + self.y * self.y
end

--- @return number
function Vec2:length()
    return sqrt(self:length_squared())
end

--- @return Vec2
function Vec2:normalize()
    local length = self:length()

    if length == 0 then
        return Vec2(0, 0)
    end

    return Vec2(self.x / length, self.y / length)
end

--- @param other Vec2
--- @return number
function Vec2:distance_squared(other)
    if not Vec2.is_vec2(other) then
        Assert.fail('other must be a Vec2', 2)
    end

    local dx = self.x - other.x
    local dy = self.y - other.y
    return dx * dx + dy * dy
end

--- @param other Vec2
--- @return number
function Vec2:distance(other)
    return sqrt(self:distance_squared(other))
end

--- @param other Vec2
--- @param t number
--- @return Vec2
function Vec2:lerp(other, t)
    if not Vec2.is_vec2(other) then
        Assert.fail('other must be a Vec2', 2)
    end
    Assert.number('t', t, 2)

    return Vec2(
        self.x + (other.x - self.x) * t,
        self.y + (other.y - self.y) * t
    )
end

--- @param other Vec2
--- @param epsilon number
--- @return boolean
function Vec2:equals(other, epsilon)
    if not Vec2.is_vec2(other) then
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

function Vec2:__add(other)
    return self:add(other)
end

function Vec2:__sub(other)
    return self:subtract(other)
end

function Vec2:__mul(other)
    if Types.is_number(other) then
        return self:scale(other)
    end

    return self:multiply(other)
end

function Vec2:__unm()
    return Vec2(-self.x, -self.y)
end

function Vec2:__eq(other)
    return self:equals(other)
end

function Vec2:__tostring()
    return string.format('Vec2(%.6f, %.6f)', self.x, self.y)
end

return Vec2
