-- Text Component Test
-- Run with: love test/text (from project root)

package.path = "?.lua;?/init.lua;" .. package.path

local Composer = require("lib.ui.scene.composer")
local Scene    = require("lib.ui.scene.scene")
local Text     = require("lib.ui.components.text")
local Button   = require("lib.ui.components.button")
local Vec2     = require("lib.ui.core.vec2")

local composer
local statusText = "Text component test"
local fontPath = "assets/fonts/DynaPuff-Regular.ttf"

local function makeScene()
    local mod = {}
    function mod.new()
        return Scene.new({ sceneName = "text_test" })
    end
    return mod
end

function love.load()
    love.graphics.setBackgroundColor(0.12, 0.12, 0.15)

    composer = Composer.new()
    composer:registerScene("text_test", makeScene())
    composer:gotoScene("text_test", { duration = 0 })

    local scene = composer:getCurrentScene()
    local y = 20

    -- Heading
    local heading = Text.new({
        text     = "Heading Text",
        textType = "heading",
        fontPath = fontPath,
        pos      = Vec2(20, y),
        anchor   = Vec2(0, 0),
        pivot    = Vec2(0, 0),
    })
    scene:addChild(heading)
    y = y + heading.size.y + 10

    -- Body
    local body = Text.new({
        text     = "Body text - the quick brown fox jumps over the lazy dog.",
        textType = "body",
        fontPath = fontPath,
        pos      = Vec2(20, y),
        anchor   = Vec2(0, 0),
        pivot    = Vec2(0, 0),
    })
    scene:addChild(body)
    y = y + body.size.y + 10

    -- Caption
    local caption = Text.new({
        text     = "Caption text - smaller and dimmer",
        textType = "caption",
        fontPath = fontPath,
        pos      = Vec2(20, y),
        anchor   = Vec2(0, 0),
        pivot    = Vec2(0, 0),
    })
    scene:addChild(caption)
    y = y + caption.size.y + 20

    -- Custom color
    local colorText = Text.new({
        text     = "Custom color text (gold)",
        fontPath = fontPath,
        fontSize = 20,
        color    = { 1, 0.84, 0, 1 },
        pos      = Vec2(20, y),
        anchor   = Vec2(0, 0),
        pivot    = Vec2(0, 0),
    })
    scene:addChild(colorText)
    y = y + colorText.size.y + 20

    -- Word-wrapped paragraph
    local wrapped = Text.new({
        text     = "This is a word-wrapped paragraph using maxWidth = 300. The text should wrap nicely within the specified width, demonstrating how the Text component handles longer content with automatic line breaking.",
        textType = "body",
        fontPath = fontPath,
        maxWidth = 300,
        pos      = Vec2(20, y),
        anchor   = Vec2(0, 0),
        pivot    = Vec2(0, 0),
    })
    scene:addChild(wrapped)

    -- DynaPuff at multiple sizes (right column)
    local sizes = { 10, 16, 24, 36 }
    local sy = 20
    for _, sz in ipairs(sizes) do
        local t = Text.new({
            text     = "DynaPuff " .. sz .. "px",
            fontPath = fontPath,
            fontSize = sz,
            pos      = Vec2(450, sy),
            anchor   = Vec2(0, 0),
            pivot    = Vec2(0, 0),
        })
        scene:addChild(t)
        sy = sy + t.size.y + 10
    end

    -- Button with DynaPuff font (verifies refactored Button)
    -- Resolve font path from project root (LÖVE source dir is test/text/)
    local sourceDir = love.filesystem.getSource()
    local resolvedFont = sourceDir .. "/../../" .. fontPath
    local fh = io.open(resolvedFont, "rb")
    local fontBytes = fh:read("*a")
    fh:close()
    local dynaFont = love.graphics.newFont(love.filesystem.newFileData(fontBytes, fontPath), 18)
    local btn = Button.new({
        label   = "DynaPuff Button",
        font    = dynaFont,
        size    = Vec2(220, 50),
        pos     = Vec2(450, sy + 10),
        anchor  = Vec2(0, 0),
        pivot   = Vec2(0, 0),
        onClick = function(self)
            self.label = "Clicked!"
            statusText = "Button clicked!"
        end,
    })
    scene:addChild(btn)

    composer:resize(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.update(dt)
    composer:update(dt)
end

function love.draw()
    composer:draw()

    -- Status bar
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
