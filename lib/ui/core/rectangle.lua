local max = math.max
local min = math.min

local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Insets = require('lib.ui.core.insets')
local Vec2 = require('lib.ui.utils.vec2')
local Object = require('lib.cls')

local Rectangle = Object:extends('Rectangle')

function Rectangle:constructor(x, y, width, height)
    x = x or 0
    y = y or 0
    width = width or 0
    height = height or 0

    Assert.number('x', x, 3)
    Assert.number('y', y, 3)
    Assert.number('width', width, 3)
    Assert.number('height', height, 3)

    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

function Rectangle.new(x, y, width, height)
    return Rectangle(x, y, width, height)
end

function Rectangle.from_edges(left, top, right, bottom)
    Assert.number('left', left, 2)
    Assert.number('top', top, 2)
    Assert.number('right', right, 2)
    Assert.number('bottom', bottom, 2)

    return Rectangle(left, top, right - left, bottom - top)
end

function Rectangle.bounding_box(points)
    if not Types.is_table(points) or #points == 0 then
        Assert.fail('points must be a non-empty array of { x, y } values', 2)
    end

    local first = points[1]

    if not Types.is_table(first) or not Types.is_number(first.x) or
        not Types.is_number(first.y) then
        Assert.fail('points must contain { x, y } values', 2)
    end

    local min_x = first.x
    local min_y = first.y
    local max_x = first.x
    local max_y = first.y

    for index = 2, #points do
        local point = points[index]

        if not Types.is_table(point) or not Types.is_number(point.x) or
            not Types.is_number(point.y) then
            Assert.fail('points must contain { x, y } values', 2)
        end

        min_x = min(min_x, point.x)
        min_y = min(min_y, point.y)
        max_x = max(max_x, point.x)
        max_y = max(max_y, point.y)
    end

    return Rectangle(min_x, min_y, max_x - min_x, max_y - min_y)
end

function Rectangle.is_rectangle(value)
    return Types.is_instance(value, Rectangle)
end

function Rectangle:clone()
    return Rectangle(self.x, self.y, self.width, self.height)
end

function Rectangle.copy_bounds(bounds)
    return {
        x = (bounds and bounds.x) or 0,
        y = (bounds and bounds.y) or 0,
        width = (bounds and bounds.width) or 0,
        height = (bounds and bounds.height) or 0,
    }
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
    if not Rectangle.is_rectangle(other) then
        Assert.fail('other must be a Rectangle', 2)
    end

    if self:is_empty() or other:is_empty() then
        return false
    end

    return other:left() >= self:left() and
        other:right() <= self:right() and
        other:top() >= self:top() and
        other:bottom() <= self:bottom()
end

function Rectangle:intersects(other)
    if not Rectangle.is_rectangle(other) then
        Assert.fail('other must be a Rectangle', 2)
    end

    if self:is_empty() or other:is_empty() then
        return false
    end

    return self:right() > other:left() and
        other:right() > self:left() and
        self:bottom() > other:top() and
        other:bottom() > self:top()
end

function Rectangle:intersection(other)
    if not Rectangle.is_rectangle(other) then
        Assert.fail('other must be a Rectangle', 2)
    end

    local left = max(self:left(), other:left())
    local top = max(self:top(), other:top())
    local right = min(self:right(), other:right())
    local bottom = min(self:bottom(), other:bottom())

    return Rectangle(left, top, max(0, right - left), max(0, bottom - top))
end

function Rectangle:union(other)
    if not Rectangle.is_rectangle(other) then
        Assert.fail('other must be a Rectangle', 2)
    end

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

    return Rectangle(left, top, right - left, bottom - top)
end

function Rectangle:translate(dx, dy)
    dx = dx or 0
    dy = dy or 0

    Assert.number('dx', dx, 2)
    Assert.number('dy', dy, 2)

    return Rectangle(self.x + dx, self.y + dy, self.width, self.height)
end

function Rectangle:inset(value)
    local insets = Insets.normalize(value)

    return Rectangle(
        self.x + insets.left,
        self.y + insets.top,
        max(0, self.width - insets:horizontal()),
        max(0, self.height - insets:vertical())
    )
end

function Rectangle:expand(value)
    local insets = Insets.normalize(value)

    return Rectangle(
        self.x - insets.left,
        self.y - insets.top,
        max(0, self.width + insets:horizontal()),
        max(0, self.height + insets:vertical())
    )
end

function Rectangle:corners()
    return
        Vec2(self.x, self.y),
        Vec2(self:right(), self.y),
        Vec2(self:right(), self:bottom()),
        Vec2(self.x, self:bottom())
end

function Rectangle:unpack()
    return self.x, self.y, self.width, self.height
end

function Rectangle:equals(other, epsilon)
    if not Rectangle.is_rectangle(other) then
        return false
    end

    epsilon = epsilon or 0
    Assert.number('epsilon', epsilon, 2)

    return math.abs(self.x - other.x) <= epsilon and
        math.abs(self.y - other.y) <= epsilon and
        math.abs(self.width - other.width) <= epsilon and
        math.abs(self.height - other.height) <= epsilon
end

function Rectangle:__eq(other)
    return self:equals(other)
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

return Rectangle
