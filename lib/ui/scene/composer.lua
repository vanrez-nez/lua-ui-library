-- composer.lua - Scene manager
-- Owns the Stage, registers scenes by name, navigates with transitions,
-- controls timing, and fires lifecycle events.

local Stage       = require("lib.ui.scene.stage")
local transitions = require("lib.ui.scene.transitions")
local Vec2        = require("lib.ui.core.vec2")

local Composer = {}
Composer.__index = Composer

--- Default easing: smoothstep
local function smoothstep(t)
    return t * t * (3 - 2 * t)
end

function Composer.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Composer)

    self.stage       = Stage.new()
    self.easeFn      = opts.easeFn or smoothstep
    self._registry   = {}   -- name -> module table
    self._instances  = {}   -- name -> scene instance
    self._current    = nil  -- current scene instance
    self._currentName = nil

    -- Transition state
    self._transitioning = false
    self._transTimer    = 0
    self._transDuration = 0
    self._transFn       = nil
    self._outScene      = nil
    self._outName       = nil
    self._inScene       = nil
    self._inName        = nil
    self._outCanvas     = nil
    self._inCanvas      = nil

    return self
end

--- Register a scene module. The module must have a .new(params) function
--- that returns a Scene instance.
function Composer:registerScene(name, moduleTable)
    self._registry[name] = moduleTable
end

--- Navigate to a scene by name.
-- @param name string
-- @param opts table { transition = fn|string, duration = number, params = table }
function Composer:gotoScene(name, opts)
    opts = opts or {}
    local mod = self._registry[name]
    assert(mod, "Scene not registered: " .. tostring(name))

    -- Skip if already on this scene
    if name == self._currentName and not self._transitioning then
        return
    end

    -- If currently transitioning, force-complete it
    if self._transitioning then
        self:_finishTransition()
    end

    -- Get or create the target scene
    local targetScene = self._instances[name]
    if not targetScene then
        targetScene = mod.new(opts.params)
        targetScene.sceneName = name
        -- Size to stage
        targetScene.size = Vec2(self.stage.size.x, self.stage.size.y)
        targetScene.anchor = Vec2(0, 0)
        targetScene.pivot  = Vec2(0, 0)
        targetScene:create(opts.params)
        self._instances[name] = targetScene
    end

    -- Resolve transition function
    local transFn = opts.transition or transitions.fade
    if type(transFn) == "string" then
        transFn = transitions[transFn]
        assert(transFn, "Unknown transition: " .. tostring(opts.transition))
    end

    local duration = opts.duration or 0.5

    local outScene = self._current
    local outName  = self._currentName

    -- Fire lifecycle: inScene onEnter('before')
    targetScene:onEnter("before")

    if outScene then
        outScene:onLeave("before")
    end

    if duration <= 0 or transFn == transitions.none then
        -- Instant transition
        if outScene then
            outScene:onLeave("running")
            outScene:onLeave("after")
            self.stage:removeChild(outScene)
        end
        self.stage:addChild(targetScene)
        targetScene:onEnter("running")
        targetScene:onEnter("after")
        self._current     = targetScene
        self._currentName = name
        self.stage:updateTransform()
        return
    end

    -- Set up animated transition
    self._transitioning = true
    self._transTimer    = 0
    self._transDuration = duration
    self._transFn       = transFn
    self._outScene      = outScene
    self._outName       = outName
    self._inScene       = targetScene
    self._inName        = name

    -- Add in-scene to stage for transform updates
    self.stage:addChild(targetScene)
    self.stage:updateTransform()

    -- Create canvases for compositing
    local w, h = self.stage.size.x, self.stage.size.y
    self._outCanvas = love.graphics.newCanvas(w, h)
    self._inCanvas  = love.graphics.newCanvas(w, h)

    -- Fire running phase
    if outScene then
        outScene:onLeave("running")
    end
    targetScene:onEnter("running")
end

--- Remove a cached scene instance, freeing its resources.
function Composer:removeScene(name)
    local instance = self._instances[name]
    if instance then
        instance:destroy()
        if instance.parent then
            instance.parent:removeChild(instance)
        end
        self._instances[name] = nil
    end
end

function Composer:getCurrentScene()
    return self._current
end

function Composer:getCurrentSceneName()
    return self._currentName
end

--- Update: advance transition timer, update stage.
function Composer:update(dt)
    if self._transitioning then
        self._transTimer = self._transTimer + dt
        if self._transTimer >= self._transDuration then
            self:_finishTransition()
        end
    end

    self.stage:update(dt)
end

--- Draw: if transitioning, composite via canvases; otherwise draw stage directly.
function Composer:draw()
    if self._transitioning then
        self:_drawTransition()
    else
        self.stage:draw()
    end
end

--- Resize handler.
function Composer:resize(w, h)
    self.stage:resize(w, h)

    -- Recreate canvases if mid-transition
    if self._transitioning then
        self._outCanvas = love.graphics.newCanvas(w, h)
        self._inCanvas  = love.graphics.newCanvas(w, h)
    end
end

--- Forward keypressed to current scene.
function Composer:keypressed(key)
    local scene = self._current or self._inScene
    if scene and scene.keypressed then
        scene:keypressed(key)
    end
end

--- Forward mousepressed to current scene.
function Composer:mousepressed(x, y, button)
    local scene = self._current
    if scene and scene.mousepressed then
        scene:mousepressed(x, y, button)
    end
end

--- Forward mousereleased to current scene.
function Composer:mousereleased(x, y, button)
    local scene = self._current
    if scene and scene.mousereleased then
        scene:mousereleased(x, y, button)
    end
end

---------- Internal ----------

function Composer:_drawTransition()
    local w, h = self.stage.size.x, self.stage.size.y
    local progress = math.min(self._transTimer / self._transDuration, 1)
    progress = self.easeFn(progress)

    local outAlpha, inAlpha, outX, outY, inX, inY =
        self._transFn(self._outCanvas, self._inCanvas, progress, w, h)

    -- Render out-scene to its canvas
    if self._outScene then
        love.graphics.setCanvas(self._outCanvas)
        love.graphics.clear(0, 0, 0, 0)
        self._outScene:draw()
        love.graphics.setCanvas()
    end

    -- Render in-scene to its canvas
    love.graphics.setCanvas(self._inCanvas)
    love.graphics.clear(0, 0, 0, 0)
    self._inScene:draw()
    love.graphics.setCanvas()

    -- Composite to screen
    if self._outScene and outAlpha > 0 then
        love.graphics.setColor(1, 1, 1, outAlpha)
        love.graphics.draw(self._outCanvas, outX, outY)
    end

    if inAlpha > 0 then
        love.graphics.setColor(1, 1, 1, inAlpha)
        love.graphics.draw(self._inCanvas, inX, inY)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function Composer:_finishTransition()
    if not self._transitioning then return end

    -- Fire after-phase lifecycle
    if self._outScene then
        self._outScene:onLeave("after")
        self.stage:removeChild(self._outScene)
    end
    self._inScene:onEnter("after")

    self._current     = self._inScene
    self._currentName = self._inName

    -- Clean up transition state
    self._transitioning = false
    self._transTimer    = 0
    self._transDuration = 0
    self._transFn       = nil
    self._outScene      = nil
    self._outName       = nil
    self._inScene       = nil
    self._inName        = nil
    self._outCanvas     = nil
    self._inCanvas      = nil

    self.stage:updateTransform()
end

return Composer
