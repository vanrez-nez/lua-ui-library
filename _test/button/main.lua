-- Button Component Test
-- Run with: love test/button (from project root)

package.path = "?.lua;?/init.lua;" .. package.path

local Composer = require("lib.ui.scene.composer")
local Scene    = require("lib.ui.scene.scene")
local Button   = require("lib.ui.components.button")
local Vec2     = require("lib.ui.core.vec2")

local composer
local statusText = "Click a button!"
local clickCount = 0

local function makeScene()
    local mod = {}
    function mod.new()
        return Scene.new({ sceneName = "buttons" })
    end
    return mod
end

function love.load()
    love.graphics.setBackgroundColor(0.12, 0.12, 0.15)

    composer = Composer.new()
    composer:registerScene("buttons", makeScene())
    composer:gotoScene("buttons", { duration = 0 })

    local scene = composer:getCurrentScene()
    local W = love.graphics.getWidth()

    -- 1) Click-counter button
    local counter = Button.new({
        label   = "Click me: 0",
        size    = Vec2(200, 50),
        pos     = Vec2(0, 0),
        anchor  = Vec2(0, 0),
        pivot   = Vec2(0, 0),
        onClick = function(self)
            clickCount = clickCount + 1
            self.label = "Click me: " .. clickCount
            statusText = "Counter: " .. clickCount
        end,
    })
    counter:setPos(30, 40)
    scene:addChild(counter)

    -- 2) Blue color scheme
    local blueBtn = Button.new({
        label      = "Blue Theme",
        size       = Vec2(200, 50),
        anchor     = Vec2(0, 0),
        pivot      = Vec2(0, 0),
        color      = { 0.15, 0.25, 0.50 },
        hoverColor = { 0.20, 0.35, 0.65 },
        pressColor = { 0.10, 0.15, 0.35 },
        borderColor = { 0.3, 0.5, 0.9, 1 },
        onClick    = function() statusText = "Blue clicked" end,
    })
    blueBtn:setPos(30, 110)
    scene:addChild(blueBtn)

    -- 3) Green color scheme
    local greenBtn = Button.new({
        label      = "Green Theme",
        size       = Vec2(200, 50),
        anchor     = Vec2(0, 0),
        pivot      = Vec2(0, 0),
        color      = { 0.15, 0.40, 0.20 },
        hoverColor = { 0.20, 0.55, 0.30 },
        pressColor = { 0.10, 0.25, 0.12 },
        borderColor = { 0.3, 0.8, 0.4, 1 },
        onClick    = function() statusText = "Green clicked" end,
    })
    greenBtn:setPos(30, 180)
    scene:addChild(greenBtn)

    -- 4) Disabled button
    local disabledBtn = Button.new({
        label   = "Disabled",
        size    = Vec2(200, 50),
        anchor  = Vec2(0, 0),
        pivot   = Vec2(0, 0),
        enabled = false,
        onClick = function() statusText = "This should never fire" end,
    })
    disabledBtn:setPos(30, 250)
    scene:addChild(disabledBtn)

    -- 5) Tight padding
    local tightBtn = Button.new({
        label   = "Tight Padding",
        size    = Vec2(200, 50),
        anchor  = Vec2(0, 0),
        pivot   = Vec2(0, 0),
        padding = { 2, 4, 2, 4 },
        onClick = function() statusText = "Tight padding clicked" end,
    })
    tightBtn:setPos(300, 40)
    scene:addChild(tightBtn)

    -- 6) Spacious padding
    local spaciousBtn = Button.new({
        label   = "Spacious Padding",
        size    = Vec2(250, 70),
        anchor  = Vec2(0, 0),
        pivot   = Vec2(0, 0),
        padding = { 20, 40, 20, 40 },
        onClick = function() statusText = "Spacious padding clicked" end,
    })
    spaciousBtn:setPos(300, 110)
    scene:addChild(spaciousBtn)

    -- 7) Left-aligned label
    local leftBtn = Button.new({
        label  = "Left Align",
        size   = Vec2(200, 50),
        anchor = Vec2(0, 0),
        pivot  = Vec2(0, 0),
        alignH = "left",
        alignV = "center",
        onClick = function() statusText = "Left-align clicked" end,
    })
    leftBtn:setPos(300, 200)
    scene:addChild(leftBtn)

    -- 8) Center-aligned label (default)
    local centerBtn = Button.new({
        label  = "Center Align",
        size   = Vec2(200, 50),
        anchor = Vec2(0, 0),
        pivot  = Vec2(0, 0),
        onClick = function() statusText = "Center-align clicked" end,
    })
    centerBtn:setPos(300, 270)
    scene:addChild(centerBtn)

    -- 9) Right-aligned label
    local rightBtn = Button.new({
        label  = "Right Align",
        size   = Vec2(200, 50),
        anchor = Vec2(0, 0),
        pivot  = Vec2(0, 0),
        alignH = "right",
        alignV = "center",
        onClick = function() statusText = "Right-align clicked" end,
    })
    rightBtn:setPos(300, 340)
    scene:addChild(rightBtn)

    -- Initial transform
    composer:resize(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.update(dt)
    composer:update(dt)
end

function love.draw()
    composer:draw()

    -- Status bar at bottom
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 40, love.graphics.getWidth(), 40)
    love.graphics.setColor(1, 1, 0.6, 1)
    love.graphics.print("Status: " .. statusText, 12, love.graphics.getHeight() - 28)
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print("[esc] quit", love.graphics.getWidth() - 100, love.graphics.getHeight() - 28)
    love.graphics.setColor(1, 1, 1, 1)
end

function love.resize(w, h)
    composer:resize(w, h)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, button)
    composer:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    composer:mousereleased(x, y, button)
end
