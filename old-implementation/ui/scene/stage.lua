-- stage.lua - Root container sized to the window
-- Hosts current scene(s) and delegates update/draw.

local Container = require("lib.ui.core.container")
local Vec2      = require("lib.ui.core.vec2")

local Stage = setmetatable({}, { __index = Container })
Stage.__index = Stage

function Stage.new()
    local w, h = love.graphics.getDimensions()
    local self = Container.new({
        size   = Vec2(w, h),
        anchor = Vec2(0, 0),
        pivot  = Vec2(0, 0),
    })
    return setmetatable(self, Stage)
end

--- Resize self and propagate to all hosted scenes.
function Stage:resize(w, h)
    self.size = Vec2(w, h)
    self:markDirty()
    for _, child in ipairs(self.children) do
        if child.size then
            child.size = Vec2(w, h)
            child:markDirty()
        end
    end
    self:updateTransform()
end

--- Update transforms then recurse children.
function Stage:update(dt)
    self:updateTransform()
    for _, child in ipairs(self.children) do
        if child.visible and child.update then
            child:update(dt)
        end
    end
end

--- Draw visible children.
function Stage:draw()
    for _, child in ipairs(self.children) do
        if child.visible and child.draw then
            child:draw()
        end
    end
end

return Stage
