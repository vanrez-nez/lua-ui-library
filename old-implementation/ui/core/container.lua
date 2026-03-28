-- container.lua - scene graph node with matrix-based transforms

local Vec2   = require("lib.ui.core.vec2")
local Matrix = require("lib.ui.core.matrix")

local Container = {}
Container.__index = Container

function Container.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Container)

    self.tag      = opts.tag or nil
    self.parent   = nil
    self.children = {}

    self.anchor   = opts.anchor   or Vec2(0.5, 0.5)
    self.pivot    = opts.pivot    or Vec2(0.5, 0.5)
    self.pos      = opts.pos      or Vec2(0, 0)
    self.size     = opts.size     or Vec2(0, 0)
    self.scale    = opts.scale    or Vec2(1, 1)
    self.rotation = opts.rotation or 0
    self.skew     = opts.skew     or Vec2(0, 0)
    self.target   = opts.target   or nil
    self.visible  = opts.visible == nil and true or opts.visible

    self.localTransform = Matrix.new()
    self.worldTransform = Matrix.new()

    self._worldPos  = Vec2(0, 0)
    self._worldSize = Vec2(0, 0)
    self._dirty     = true
    self._loveTransform = nil  -- lazy-init LÖVE Transform cache

    return self
end

-- Hierarchy

function Container:addChild(child)
    if child.parent then
        child.parent:removeChild(child)
    end
    child.parent = self
    self.children[#self.children + 1] = child
    self:markDirty()
    return child
end

function Container:removeChild(child)
    for i, c in ipairs(self.children) do
        if c == child then
            table.remove(self.children, i)
            child.parent = nil
            self:markDirty()
            return
        end
    end
end

function Container:getChildByTag(tag)
    for _, c in ipairs(self.children) do
        if c.tag == tag then return c end
    end
    return nil
end

function Container:findByTag(tag)
    for _, c in ipairs(self.children) do
        if c.tag == tag then return c end
        local found = c:findByTag(tag)
        if found then return found end
    end
    return nil
end

-- Dirty propagation

function Container:markDirty()
    self._dirty = true
    for _, c in ipairs(self.children) do
        c:markDirty()
    end
end

function Container:setPos(x, y)
    self.pos = Vec2(x, y)
    self:markDirty()
end

function Container:setSize(w, h)
    self.size = Vec2(w, h)
    self:markDirty()
end

function Container:setAnchor(x, y)
    self.anchor = Vec2(x, y)
    self:markDirty()
end

function Container:setPivot(x, y)
    self.pivot = Vec2(x, y)
    self:markDirty()
end

function Container:setScale(x, y)
    self.scale = Vec2(x, y)
    self:markDirty()
end

function Container:setRotation(r)
    self.rotation = r
    self:markDirty()
end

function Container:setSkew(kx, ky)
    self.skew = Vec2(kx, ky)
    self:markDirty()
end

-- Transform pipeline

function Container:updateLocalTransform()
    local px = self.pivot.x * self.size.x
    local py = self.pivot.y * self.size.y
    self.localTransform:setTransform(
        self.pos.x, self.pos.y,
        px, py,
        self.scale.x, self.scale.y,
        self.rotation,
        self.skew.x, self.skew.y
    )
    self._dirty = false
end

function Container:updateTransform()
    if self._dirty then
        self:updateLocalTransform()
    end

    if self.parent then
        -- Anchor offset in parent's local space
        local ax = self.anchor.x * self.parent.size.x
        local ay = self.anchor.y * self.parent.size.y

        -- worldTransform = parent.worldTransform * T(anchor) * localTransform
        self.worldTransform:copyFrom(self.parent.worldTransform)
        self.worldTransform:translate(ax, ay)
        self.worldTransform:append(self.localTransform)
    else
        -- Root: world = local
        self.worldTransform:copyFrom(self.localTransform)
    end

    -- Derive AABB for backward compat
    self:_updateBounds()

    -- Update cached LÖVE Transform
    if self._loveTransform then
        self._loveTransform:setMatrix(
            "row",
            self.worldTransform.a,  self.worldTransform.c,  0, self.worldTransform.tx,
            self.worldTransform.b,  self.worldTransform.d,  0, self.worldTransform.ty,
            0, 0, 1, 0,
            0, 0, 0, 1
        )
    end

    -- Sync target
    if self.target then
        self:applyTo(self.target)
    end

    -- Recurse visible children
    for _, child in ipairs(self.children) do
        if child.visible then
            child:updateTransform()
        end
    end
end

function Container:_updateBounds()
    local w, h = self.size.x, self.size.y
    local m = self.worldTransform
    local x0, y0 = m:apply(0, 0)
    local x1, y1 = m:apply(w, 0)
    local x2, y2 = m:apply(w, h)
    local x3, y3 = m:apply(0, h)
    local minX = math.min(x0, x1, x2, x3)
    local minY = math.min(y0, y1, y2, y3)
    self._worldPos  = Vec2(minX, minY)
    self._worldSize = Vec2(math.max(x0, x1, x2, x3) - minX, math.max(y0, y1, y2, y3) - minY)
end

-- Coordinate helpers

function Container:localToWorld(lx, ly)
    return self.worldTransform:apply(lx, ly)
end

function Container:worldToLocal(wx, wy)
    return self.worldTransform:applyInverse(wx, wy)
end

function Container:containsPoint(wx, wy)
    local lx, ly = self.worldTransform:applyInverse(wx, wy)
    return lx >= 0 and lx <= self.size.x and ly >= 0 and ly <= self.size.y
end

function Container:getRect()
    return self._worldPos.x, self._worldPos.y, self._worldSize.x, self._worldSize.y
end

function Container:applyTo(target)
    target.x = self._worldPos.x
    target.y = self._worldPos.y
    target.w = self._worldSize.x
    target.h = self._worldSize.y
end

-- Drawing helpers

function Container:pushTransform()
    if not self._loveTransform then
        self._loveTransform = love.math.newTransform()
        self._loveTransform:setMatrix(
            "row",
            self.worldTransform.a,  self.worldTransform.c,  0, self.worldTransform.tx,
            self.worldTransform.b,  self.worldTransform.d,  0, self.worldTransform.ty,
            0, 0, 1, 0,
            0, 0, 0, 1
        )
    end
    love.graphics.push()
    love.graphics.applyTransform(self._loveTransform)
end

function Container:popTransform()
    love.graphics.pop()
end

-- Root convenience

function Container:resize(w, h)
    self.size = Vec2(w, h)
    self:markDirty()
    self:updateTransform()
end

return Container
