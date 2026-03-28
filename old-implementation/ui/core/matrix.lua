-- matrix.lua - 2D affine transform matrix
-- Layout:  | a  c  tx |
--          | b  d  ty |
--          | 0  0  1  |

local Matrix = {}
Matrix.__index = Matrix

function Matrix.new(a, b, c, d, tx, ty)
    return setmetatable({
        a  = a  or 1,
        b  = b  or 0,
        c  = c  or 0,
        d  = d  or 1,
        tx = tx or 0,
        ty = ty or 0,
    }, Matrix)
end

function Matrix:identity()
    self.a, self.b, self.c, self.d = 1, 0, 0, 1
    self.tx, self.ty = 0, 0
    return self
end

function Matrix:isIdentity()
    return self.a == 1 and self.b == 0 and self.c == 0
       and self.d == 1 and self.tx == 0 and self.ty == 0
end

-- Setting values

function Matrix:set(a, b, c, d, tx, ty)
    self.a, self.b, self.c, self.d = a, b, c, d
    self.tx, self.ty = tx, ty
    return self
end

function Matrix:setTransform(x, y, pivotX, pivotY, scaleX, scaleY, rotation, skewX, skewY)
    self.a = math.cos(rotation + skewY) * scaleX
    self.b = math.sin(rotation + skewY) * scaleX
    self.c = -math.sin(rotation - skewX) * scaleY
    self.d = math.cos(rotation - skewX) * scaleY
    self.tx = x - (pivotX * self.a + pivotY * self.c)
    self.ty = y - (pivotX * self.b + pivotY * self.d)
    return self
end

-- Point transforms

function Matrix:apply(x, y)
    return self.a * x + self.c * y + self.tx,
           self.b * x + self.d * y + self.ty
end

function Matrix:applyInverse(x, y)
    local id = 1 / (self.a * self.d - self.b * self.c)
    local nx = self.d * id * (x - self.tx) - self.c * id * (y - self.ty)
    local ny = self.a * id * (y - self.ty) - self.b * id * (x - self.tx)
    return nx, ny
end

-- Matrix composition

function Matrix:append(other)
    local a1, b1, c1, d1 = self.a, self.b, self.c, self.d
    local tx1, ty1 = self.tx, self.ty

    self.a  = a1 * other.a + c1 * other.b
    self.b  = b1 * other.a + d1 * other.b
    self.c  = a1 * other.c + c1 * other.d
    self.d  = b1 * other.c + d1 * other.d
    self.tx = a1 * other.tx + c1 * other.ty + tx1
    self.ty = b1 * other.tx + d1 * other.ty + ty1
    return self
end

function Matrix:prepend(other)
    local a1, b1, c1, d1 = self.a, self.b, self.c, self.d
    local tx1, ty1 = self.tx, self.ty

    self.a  = other.a * a1 + other.c * b1
    self.b  = other.b * a1 + other.d * b1
    self.c  = other.a * c1 + other.c * d1
    self.d  = other.b * c1 + other.d * d1
    self.tx = other.a * tx1 + other.c * ty1 + other.tx
    self.ty = other.b * tx1 + other.d * ty1 + other.ty
    return self
end

function Matrix:appendFrom(a, b)
    self.a  = a.a * b.a + a.c * b.b
    self.b  = a.b * b.a + a.d * b.b
    self.c  = a.a * b.c + a.c * b.d
    self.d  = a.b * b.c + a.d * b.d
    self.tx = a.a * b.tx + a.c * b.ty + a.tx
    self.ty = a.b * b.tx + a.d * b.ty + a.ty
    return self
end

-- Mutation transforms

function Matrix:translate(tx, ty)
    self.tx = self.tx + self.a * tx + self.c * ty
    self.ty = self.ty + self.b * tx + self.d * ty
    return self
end

function Matrix:scale(sx, sy)
    self.a  = self.a * sx
    self.b  = self.b * sx
    self.c  = self.c * sy
    self.d  = self.d * sy
    self.tx = self.tx * sx
    self.ty = self.ty * sy
    return self
end

function Matrix:rotate(angle)
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    local a1, b1, c1, d1 = self.a, self.b, self.c, self.d
    local tx1, ty1 = self.tx, self.ty

    self.a  = a1 * cos - b1 * sin
    self.b  = a1 * sin + b1 * cos
    self.c  = c1 * cos - d1 * sin
    self.d  = c1 * sin + d1 * cos
    self.tx = tx1 * cos - ty1 * sin
    self.ty = tx1 * sin + ty1 * cos
    return self
end

-- Inverse & decomposition

function Matrix:invert()
    local a1, b1, c1, d1 = self.a, self.b, self.c, self.d
    local tx1, ty1 = self.tx, self.ty
    local det = a1 * d1 - b1 * c1

    self.a  =  d1 / det
    self.b  = -b1 / det
    self.c  = -c1 / det
    self.d  =  a1 / det
    self.tx = (c1 * ty1 - d1 * tx1) / det
    self.ty = (b1 * tx1 - a1 * ty1) / det
    return self
end

function Matrix:decompose(target)
    target = target or {}

    local a, b, c, d = self.a, self.b, self.c, self.d

    local skewX = -math.atan2(-c, d)
    local skewY = math.atan2(b, a)

    local delta = math.abs(skewX + skewY)

    if delta < 0.00001 then
        target.rotation = skewY
        target.skewX = 0
        target.skewY = 0
    else
        target.rotation = 0
        target.skewX = skewX
        target.skewY = skewY
    end

    target.scaleX = math.sqrt(a * a + b * b)
    target.scaleY = math.sqrt(c * c + d * d)

    target.x = self.tx
    target.y = self.ty

    target.pivotX = 0
    target.pivotY = 0

    return target
end

-- Copy & comparison

function Matrix:clone()
    return Matrix.new(self.a, self.b, self.c, self.d, self.tx, self.ty)
end

function Matrix:copyFrom(other)
    self.a, self.b, self.c, self.d = other.a, other.b, other.c, other.d
    self.tx, self.ty = other.tx, other.ty
    return self
end

function Matrix:copyTo(other)
    other.a, other.b, other.c, other.d = self.a, self.b, self.c, self.d
    other.tx, other.ty = self.tx, self.ty
    return other
end

function Matrix:equals(other)
    return self.a == other.a and self.b == other.b
       and self.c == other.c and self.d == other.d
       and self.tx == other.tx and self.ty == other.ty
end

-- LOVE2D interop

function Matrix:toLoveTransform()
    local t = love.math.newTransform()
    t:setMatrix(
        "row",
        self.a,  self.c,  0, self.tx,
        self.b,  self.d,  0, self.ty,
        0,       0,       1, 0,
        0,       0,       0, 1
    )
    return t
end

function Matrix:__tostring()
    return string.format("Matrix(a=%.3f b=%.3f c=%.3f d=%.3f tx=%.3f ty=%.3f)",
        self.a, self.b, self.c, self.d, self.tx, self.ty)
end

-- Constants

Matrix.IDENTITY = Matrix.new()

return Matrix
