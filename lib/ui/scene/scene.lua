-- scene.lua - Scene class with lifecycle hooks
-- Extends Container (not Drawable) to serve as a full-screen container for scene contents.

local Container = require("lib.ui.core.container")
local Vec2      = require("lib.ui.core.vec2")

local Scene = setmetatable({}, { __index = Container })
Scene.__index = Scene

function Scene.new(opts)
    opts = opts or {}
    local self = Container.new(opts)
    self = setmetatable(self, Scene)
    self.sceneName = opts.sceneName or "unnamed"
    return self
end

--- Override to build scene contents. Called once when first navigated to.
function Scene:create(params)
    -- override in subclass
end

--- Remove all children and break references for GC.
function Scene:destroy()
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        child.parent = nil
        self.children[i] = nil
    end
end

--- Lifecycle hook called during scene enter.
-- @param phase 'before' | 'running' | 'after'
function Scene:onEnter(phase)
    -- override in subclass
end

--- Lifecycle hook called during scene leave.
-- @param phase 'before' | 'running' | 'after'
function Scene:onLeave(phase)
    -- override in subclass
end

--- Update all children recursively.
function Scene:update(dt)
    for _, child in ipairs(self.children) do
        if child.visible and child.update then
            child:update(dt)
        end
    end
end

--- Draw all visible children recursively.
function Scene:draw()
    for _, child in ipairs(self.children) do
        if child.visible and child.draw then
            child:pushTransform()
            child:draw()
            child:popTransform()
        end
    end
end

--- Propagate mousepressed to children in reverse order (topmost first).
function Scene:mousepressed(mx, my, btn)
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child.visible and child.mousepressed then
            if child:mousepressed(mx, my, btn) then return true end
        end
    end
    return false
end

--- Propagate mousereleased to children in reverse order (topmost first).
function Scene:mousereleased(mx, my, btn)
    for i = #self.children, 1, -1 do
        local child = self.children[i]
        if child.visible and child.mousereleased then
            if child:mousereleased(mx, my, btn) then return true end
        end
    end
    return false
end

--- Walk the tree and count all nodes (including self).
function Scene:objectCount()
    local count = 0
    local function walk(node)
        count = count + 1
        for _, child in ipairs(node.children) do
            walk(child)
        end
    end
    walk(self)
    return count
end

return Scene
