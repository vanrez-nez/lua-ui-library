-- rectangle.lua - axis-aligned rectangle

local Rectangle = {}
Rectangle.__index = Rectangle

function Rectangle.new(x, y, width, height)
    return setmetatable({
        x      = x      or 0,
        y      = y      or 0,
        width  = width  or 0,
        height = height or 0,
    }, Rectangle)
end

function Rectangle:set(x, y, width, height)
    self.x, self.y = x, y
    self.width, self.height = width, height
    return self
end

function Rectangle:clone()
    return Rectangle.new(self.x, self.y, self.width, self.height)
end

function Rectangle:copyFrom(other)
    self.x, self.y = other.x, other.y
    self.width, self.height = other.width, other.height
    return self
end

-- Edge accessors

function Rectangle:left()   return self.x end
function Rectangle:right()  return self.x + self.width end
function Rectangle:top()    return self.y end
function Rectangle:bottom() return self.y + self.height end

-- Queries

function Rectangle:isEmpty()
    return self.width <= 0 or self.height <= 0
end

function Rectangle:contains(px, py)
    return px >= self.x and px <= self.x + self.width
       and py >= self.y and py <= self.y + self.height
end

-- Mutation

function Rectangle:enlarge(rect)
    local x1 = math.min(self.x, rect.x)
    local y1 = math.min(self.y, rect.y)
    local x2 = math.max(self.x + self.width, rect.x + rect.width)
    local y2 = math.max(self.y + self.height, rect.y + rect.height)
    self.x, self.y = x1, y1
    self.width  = x2 - x1
    self.height = y2 - y1
    return self
end

function Rectangle:fit(rect)
    local x1 = math.max(self.x, rect.x)
    local y1 = math.max(self.y, rect.y)
    local x2 = math.min(self.x + self.width, rect.x + rect.width)
    local y2 = math.min(self.y + self.height, rect.y + rect.height)
    self.x, self.y = x1, y1
    self.width  = math.max(0, x2 - x1)
    self.height = math.max(0, y2 - y1)
    return self
end

function Rectangle:pad(px, py)
    py = py or px
    self.x = self.x - px
    self.y = self.y - py
    self.width  = self.width  + px * 2
    self.height = self.height + py * 2
    return self
end

function Rectangle:scale(sx, sy)
    sy = sy or sx
    self.x = self.x * sx
    self.y = self.y * sy
    self.width  = self.width  * sx
    self.height = self.height * sy
    return self
end

function Rectangle:__tostring()
    return string.format("Rectangle(%.1f, %.1f, %.1f, %.1f)",
        self.x, self.y, self.width, self.height)
end

-- Constants

Rectangle.EMPTY = Rectangle.new()

return Rectangle
