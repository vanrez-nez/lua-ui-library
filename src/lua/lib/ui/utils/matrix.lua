local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Object = require('lib.cls')

local abs = math.abs
local cos = math.cos
local sin = math.sin

local Matrix = Object:extends('Matrix')

--- @param a number
--- @param b number
--- @param c number
--- @param d number
--- @param tx number
--- @param ty number
function Matrix:constructor(a, b, c, d, tx, ty)
    a = a == nil and 1 or a
    b = b or 0
    c = c or 0
    d = d == nil and 1 or d
    tx = tx or 0
    ty = ty or 0

    Assert.number('a', a, 3)
    Assert.number('b', b, 3)
    Assert.number('c', c, 3)
    Assert.number('d', d, 3)
    Assert.number('tx', tx, 3)
    Assert.number('ty', ty, 3)

    self.a = a
    self.b = b
    self.c = c
    self.d = d
    self.tx = tx
    self.ty = ty
end

--- @param a number
--- @param b number
--- @param c number
--- @param d number
--- @param tx number
--- @param ty number
--- @return Matrix
function Matrix.new(a, b, c, d, tx, ty)
    return Matrix(a, b, c, d, tx, ty)
end

--- @return Matrix
function Matrix.identity()
    return Matrix(1, 0, 0, 1, 0, 0)
end

--- @param x number
--- @param y number
--- @param pivot_x number
--- @param pivot_y number
--- @param scale_x number
--- @param scale_y number
--- @param rotation number
--- @param skew_x number
--- @param skew_y number
--- @return Matrix
function Matrix.from_transform(
    x,
    y,
    pivot_x,
    pivot_y,
    scale_x,
    scale_y,
    rotation,
    skew_x,
    skew_y
)
    x = x or 0
    y = y or 0
    pivot_x = pivot_x or 0
    pivot_y = pivot_y or 0
    scale_x = scale_x == nil and 1 or scale_x
    scale_y = scale_y == nil and 1 or scale_y
    rotation = rotation or 0
    skew_x = skew_x or 0
    skew_y = skew_y or 0

    Assert.number('x', x, 2)
    Assert.number('y', y, 2)
    Assert.number('pivot_x', pivot_x, 2)
    Assert.number('pivot_y', pivot_y, 2)
    Assert.number('scale_x', scale_x, 2)
    Assert.number('scale_y', scale_y, 2)
    Assert.number('rotation', rotation, 2)
    Assert.number('skew_x', skew_x, 2)
    Assert.number('skew_y', skew_y, 2)

    local a = cos(rotation + skew_y) * scale_x
    local b = sin(rotation + skew_y) * scale_x
    local c = -sin(rotation - skew_x) * scale_y
    local d = cos(rotation - skew_x) * scale_y
    local tx = x - (pivot_x * a + pivot_y * c)
    local ty = y - (pivot_x * b + pivot_y * d)

    return Matrix(a, b, c, d, tx, ty)
end

--- @param value any
--- @return boolean
function Matrix.is_matrix(value)
    return Types.is_instance(value, Matrix)
end

--- @return Matrix
function Matrix:clone()
    return Matrix(self.a, self.b, self.c, self.d, self.tx, self.ty)
end

--- @param a number
--- @param b number
--- @param c number
--- @param d number
--- @param tx number
--- @param ty number
function Matrix:set(a, b, c, d, tx, ty)
    Assert.number('a', a, 2)
    Assert.number('b', b, 2)
    Assert.number('c', c, 2)
    Assert.number('d', d, 2)
    Assert.number('tx', tx, 2)
    Assert.number('ty', ty, 2)

    self.a = a
    self.b = b
    self.c = c
    self.d = d
    self.tx = tx
    self.ty = ty

    return self
end

--- @param scale_x number
--- @param scale_y number
--- @param rotation number
--- @param skew_x number
--- @param skew_y number
--- @return Matrix
function Matrix:set_linear_from_transform(scale_x, scale_y, rotation, skew_x, skew_y)
    scale_x = scale_x == nil and 1 or scale_x
    scale_y = scale_y == nil and 1 or scale_y
    rotation = rotation or 0
    skew_x = skew_x or 0
    skew_y = skew_y or 0

    Assert.number('scale_x', scale_x, 2)
    Assert.number('scale_y', scale_y, 2)
    Assert.number('rotation', rotation, 2)
    Assert.number('skew_x', skew_x, 2)
    Assert.number('skew_y', skew_y, 2)

    self.a = cos(rotation + skew_y) * scale_x
    self.b = sin(rotation + skew_y) * scale_x
    self.c = -sin(rotation - skew_x) * scale_y
    self.d = cos(rotation - skew_x) * scale_y

    return self
end

--- @param tx number
--- @param ty number
--- @return Matrix
function Matrix:set_translation(tx, ty)
    tx = tx or 0
    ty = ty or 0

    Assert.number('tx', tx, 2)
    Assert.number('ty', ty, 2)

    self.tx = tx
    self.ty = ty

    return self
end

--- @param x number
--- @param y number
--- @param pivot_x number
--- @param pivot_y number
--- @param x number
--- @param y number
--- @param pivot_x number
--- @param pivot_y number
--- @return Matrix
function Matrix:set_transform_translation(x, y, pivot_x, pivot_y)
    x = x or 0
    y = y or 0
    pivot_x = pivot_x or 0
    pivot_y = pivot_y or 0

    Assert.number('x', x, 2)
    Assert.number('y', y, 2)
    Assert.number('pivot_x', pivot_x, 2)
    Assert.number('pivot_y', pivot_y, 2)

    self.tx = x - (pivot_x * self.a + pivot_y * self.c)
    self.ty = y - (pivot_x * self.b + pivot_y * self.d)

    return self
end

--- @param x number
--- @param y number
--- @param pivot_x number
--- @param pivot_y number
--- @param scale_x number
--- @param scale_y number
--- @param rotation number
--- @param skew_x number
--- @param skew_y number
--- @return Matrix
function Matrix:set_from_transform(
    x,
    y,
    pivot_x,
    pivot_y,
    scale_x,
    scale_y,
    rotation,
    skew_x,
    skew_y
)
    x = x or 0
    y = y or 0
    pivot_x = pivot_x or 0
    pivot_y = pivot_y or 0
    scale_x = scale_x == nil and 1 or scale_x
    scale_y = scale_y == nil and 1 or scale_y
    rotation = rotation or 0
    skew_x = skew_x or 0
    skew_y = skew_y or 0

    Assert.number('x', x, 2)
    Assert.number('y', y, 2)
    Assert.number('pivot_x', pivot_x, 2)
    Assert.number('pivot_y', pivot_y, 2)
    Assert.number('scale_x', scale_x, 2)
    Assert.number('scale_y', scale_y, 2)
    Assert.number('rotation', rotation, 2)
    Assert.number('skew_x', skew_x, 2)
    Assert.number('skew_y', skew_y, 2)

    return self
        :set_linear_from_transform(scale_x, scale_y, rotation, skew_x, skew_y)
        :set_transform_translation(x, y, pivot_x, pivot_y)
end

--- @param epsilon number
--- @return boolean
function Matrix:is_identity(epsilon)
    epsilon = epsilon or 0
    Assert.number('epsilon', epsilon, 2)

    return abs(self.a - 1) <= epsilon and
        abs(self.b) <= epsilon and
        abs(self.c) <= epsilon and
        abs(self.d - 1) <= epsilon and
        abs(self.tx) <= epsilon and
        abs(self.ty) <= epsilon
end

--- @return number
function Matrix:determinant()
    return self.a * self.d - self.b * self.c
end

--- @param epsilon number
--- @return boolean
function Matrix:is_invertible(epsilon)
    epsilon = epsilon or 1e-12
    Assert.number('epsilon', epsilon, 2)
    return abs(self:determinant()) > epsilon
end

--- @param other Matrix
--- @return Matrix
function Matrix:multiply(other)
    if not Matrix.is_matrix(other) then
        Assert.fail('other must be a Matrix', 2)
    end

    return Matrix(
        self.a * other.a + self.c * other.b,
        self.b * other.a + self.d * other.b,
        self.a * other.c + self.c * other.d,
        self.b * other.c + self.d * other.d,
        self.a * other.tx + self.c * other.ty + self.tx,
        self.b * other.tx + self.d * other.ty + self.ty
    )
end

--- @param epsilon number
--- @return Matrix|nil, string
function Matrix:inverse(epsilon)
    epsilon = epsilon or 1e-12
    Assert.number('epsilon', epsilon, 2)

    local determinant = self:determinant()

    if abs(determinant) <= epsilon then
        return nil, 'matrix is not invertible'
    end

    return Matrix(
        self.d / determinant,
        -self.b / determinant,
        -self.c / determinant,
        self.a / determinant,
        (self.c * self.ty - self.d * self.tx) / determinant,
        (self.b * self.tx - self.a * self.ty) / determinant
    )
end

--- @param x number
--- @param y number
--- @return number, number
function Matrix:transform_point(x, y)
    Assert.number('x', x, 2)
    Assert.number('y', y, 2)

    return self.a * x + self.c * y + self.tx,
        self.b * x + self.d * y + self.ty
end

--- @param other Matrix
--- @param epsilon number
--- @return boolean
function Matrix:equals(other, epsilon)
    if not Matrix.is_matrix(other) then
        return false
    end

    epsilon = epsilon or 0
    Assert.number('epsilon', epsilon, 2)

    return abs(self.a - other.a) <= epsilon and
        abs(self.b - other.b) <= epsilon and
        abs(self.c - other.c) <= epsilon and
        abs(self.d - other.d) <= epsilon and
        abs(self.tx - other.tx) <= epsilon and
        abs(self.ty - other.ty) <= epsilon
end

function Matrix:unpack()
    return self.a, self.b, self.c, self.d, self.tx, self.ty
end

function Matrix:__mul(other)
    if Matrix.is_matrix(self) and Matrix.is_matrix(other) then
        return self:multiply(other)
    end

    Assert.fail('Matrix multiplication expects two Matrix values', 2)
end

function Matrix:__eq(other)
    return self:equals(other)
end

function Matrix:__tostring()
    return string.format(
        'Matrix(a=%.6f, b=%.6f, c=%.6f, d=%.6f, tx=%.6f, ty=%.6f)',
        self.a,
        self.b,
        self.c,
        self.d,
        self.tx,
        self.ty
    )
end

return Matrix
