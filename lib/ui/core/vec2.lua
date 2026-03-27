-- vec2.lua - 2D vector value type for UI positioning

local Vec2 = {}
Vec2.__index = Vec2

local function new(x, y)
    return setmetatable({ x = x or 0, y = y or 0 }, Vec2)
end

setmetatable(Vec2, { __call = function(_, x, y) return new(x, y) end })

-- Operators

function Vec2.__add(a, b)
    return new(a.x + b.x, a.y + b.y)
end

function Vec2.__sub(a, b)
    return new(a.x - b.x, a.y - b.y)
end

function Vec2.__mul(a, b)
    if type(a) == "number" then
        return new(a * b.x, a * b.y)
    elseif type(b) == "number" then
        return new(a.x * b, a.y * b)
    else
        return new(a.x * b.x, a.y * b.y)
    end
end

function Vec2.__unm(a)
    return new(-a.x, -a.y)
end

function Vec2.__eq(a, b)
    return a.x == b.x and a.y == b.y
end

function Vec2:__tostring()
    return "Vec2(" .. self.x .. ", " .. self.y .. ")"
end

-- Methods

function Vec2:clone()
    return new(self.x, self.y)
end

function Vec2:lerp(other, t)
    return new(
        self.x + (other.x - self.x) * t,
        self.y + (other.y - self.y) * t
    )
end

function Vec2:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vec2:unpack()
    return self.x, self.y
end

-- Constants

Vec2.ZERO = new(0, 0)
Vec2.ONE  = new(1, 1)
Vec2.HALF = new(0.5, 0.5)

return Vec2
