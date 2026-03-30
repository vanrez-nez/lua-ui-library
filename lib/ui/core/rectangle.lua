local max = math.max
local min = math.min

local Assert = require('lib.ui.core.assert')
local Insets = require('lib.ui.core.insets')
local Vec2 = require('lib.ui.core.vec2')

local Rectangle = {}
Rectangle.__index = Rectangle

local function is_rectangle(value)
    return getmetatable(value) == Rectangle
end

local function assert_rectangle(name, value)
    if not is_rectangle(value) then
        Assert.fail(name .. ' must be a Rectangle', 2)
    end
end

local function new(x, y, width, height)
    x = x or 0
    y = y or 0
    width = width or 0
    height = height or 0

    Assert.number('x', x, 2)
    Assert.number('y', y, 2)
    Assert.number('width', width, 2)
    Assert.number('height', height, 2)

    return setmetatable({
        x = x,
        y = y,
        width = width,
        height = height,
    }, Rectangle)
end

function Rectangle.new(x, y, width, height)
    return new(x, y, width, height)
end

function Rectangle.from_edges(left, top, right, bottom)
    Assert.number('left', left, 2)
    Assert.number('top', top, 2)
    Assert.number('right', right, 2)
    Assert.number('bottom', bottom, 2)

    return new(left, top, right - left, bottom - top)
end

function Rectangle.bounding_box(points)
    if type(points) ~= 'table' or #points == 0 then
        Assert.fail('points must be a non-empty array of { x, y } values', 2)
    end

    local first = points[1]

    if type(first) ~= 'table' or type(first.x) ~= 'number' or
        type(first.y) ~= 'number' then
        Assert.fail('points must contain { x, y } values', 2)
    end

    local min_x = first.x
    local min_y = first.y
    local max_x = first.x
    local max_y = first.y

    for index = 2, #points do
        local point = points[index]

        if type(point) ~= 'table' or type(point.x) ~= 'number' or
            type(point.y) ~= 'number' then
            Assert.fail('points must contain { x, y } values', 2)
        end

        min_x = min(min_x, point.x)
        min_y = min(min_y, point.y)
        max_x = max(max_x, point.x)
        max_y = max(max_y, point.y)
    end

    return new(min_x, min_y, max_x - min_x, max_y - min_y)
end

function Rectangle.is_rectangle(value)
    return is_rectangle(value)
end

function Rectangle:clone()
    return new(self.x, self.y, self.width, self.height)
end

function Rectangle:left()
    return self.x
end

function Rectangle:right()
    return self.x + self.width
end

function Rectangle:top()
    return self.y
end

function Rectangle:bottom()
    return self.y + self.height
end

function Rectangle:is_empty()
    return self.width <= 0 or self.height <= 0
end

function Rectangle:contains_point(x, y)
    if self:is_empty() then
        return false
    end

    Assert.number('x', x, 2)
    Assert.number('y', y, 2)

    return x >= self.x and x <= self:right() and
        y >= self.y and y <= self:bottom()
end

function Rectangle:contains_rectangle(other)
    assert_rectangle('other', other)

    if self:is_empty() or other:is_empty() then
        return false
    end

    return other:left() >= self:left() and
        other:right() <= self:right() and
        other:top() >= self:top() and
        other:bottom() <= self:bottom()
end

function Rectangle:intersects(other)
    assert_rectangle('other', other)

    if self:is_empty() or other:is_empty() then
        return false
    end

    return self:right() > other:left() and
        other:right() > self:left() and
        self:bottom() > other:top() and
        other:bottom() > self:top()
end

function Rectangle:intersection(other)
    assert_rectangle('other', other)

    local left = max(self:left(), other:left())
    local top = max(self:top(), other:top())
    local right = min(self:right(), other:right())
    local bottom = min(self:bottom(), other:bottom())

    return new(left, top, max(0, right - left), max(0, bottom - top))
end

function Rectangle:union(other)
    assert_rectangle('other', other)

    if self:is_empty() then
        return other:clone()
    end

    if other:is_empty() then
        return self:clone()
    end

    local left = min(self:left(), other:left())
    local top = min(self:top(), other:top())
    local right = max(self:right(), other:right())
    local bottom = max(self:bottom(), other:bottom())

    return new(left, top, right - left, bottom - top)
end

function Rectangle:translate(dx, dy)
    dx = dx or 0
    dy = dy or 0

    Assert.number('dx', dx, 2)
    Assert.number('dy', dy, 2)

    return new(self.x + dx, self.y + dy, self.width, self.height)
end

function Rectangle:inset(value)
    local insets = Insets.normalize(value)

    return new(
        self.x + insets.left,
        self.y + insets.top,
        max(0, self.width - insets:horizontal()),
        max(0, self.height - insets:vertical())
    )
end

function Rectangle:expand(value)
    local insets = Insets.normalize(value)

    return new(
        self.x - insets.left,
        self.y - insets.top,
        max(0, self.width + insets:horizontal()),
        max(0, self.height + insets:vertical())
    )
end

function Rectangle:corners()
    return
        Vec2.new(self.x, self.y),
        Vec2.new(self:right(), self.y),
        Vec2.new(self:right(), self:bottom()),
        Vec2.new(self.x, self:bottom())
end

function Rectangle:unpack()
    return self.x, self.y, self.width, self.height
end

function Rectangle:equals(other, epsilon)
    if not is_rectangle(other) then
        return false
    end

    epsilon = epsilon or 0
    Assert.number('epsilon', epsilon, 2)

    return math.abs(self.x - other.x) <= epsilon and
        math.abs(self.y - other.y) <= epsilon and
        math.abs(self.width - other.width) <= epsilon and
        math.abs(self.height - other.height) <= epsilon
end

function Rectangle.__eq(left, right)
    return is_rectangle(left) and left:equals(right)
end

function Rectangle:__tostring()
    return string.format(
        'Rectangle(x=%.6f, y=%.6f, width=%.6f, height=%.6f)',
        self.x,
        self.y,
        self.width,
        self.height
    )
end

setmetatable(Rectangle, {
    __call = function(_, x, y, width, height)
        return new(x, y, width, height)
    end,
})

return Rectangle
