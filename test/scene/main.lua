-- Scene Management Demo
-- Run with: love test/scene (from project root)

package.path = "?.lua;?/init.lua;" .. package.path

local Composer    = require("lib.ui.scene.composer")
local transitions = require("lib.ui.scene.transitions")

local composer

local sceneNames = { "menu", "game", "settings" }
local sceneIndex = 1

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)

    composer = Composer.new()

    -- Register scenes
    composer:registerScene("menu",     require("test.scene.scenes.menu"))
    composer:registerScene("game",     require("test.scene.scenes.game"))
    composer:registerScene("settings", require("test.scene.scenes.settings"))

    -- Start with menu
    composer:gotoScene("menu", { transition = "fade", duration = 0 })
end

function love.update(dt)
    composer:update(dt)
end

function love.draw()
    composer:draw()

    -- Memory metrics overlay
    drawMetrics()
end

function love.resize(w, h)
    composer:resize(w, h)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    end

    -- Number keys: go to scene directly (fade)
    if key == "1" then
        gotoByIndex(1, "fade")
    elseif key == "2" then
        gotoByIndex(2, "fade")
    elseif key == "3" then
        gotoByIndex(3, "fade")
    elseif key == "left" then
        sceneIndex = sceneIndex - 1
        if sceneIndex < 1 then sceneIndex = #sceneNames end
        composer:gotoScene(sceneNames[sceneIndex], {
            transition = transitions.slideRight,
            duration   = 0.4,
        })
    elseif key == "right" then
        sceneIndex = sceneIndex + 1
        if sceneIndex > #sceneNames then sceneIndex = 1 end
        composer:gotoScene(sceneNames[sceneIndex], {
            transition = transitions.slideLeft,
            duration   = 0.4,
        })
    end

    composer:keypressed(key)
end

function love.mousepressed(x, y, button)
    composer:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    composer:mousereleased(x, y, button)
end

---------- Helpers ----------

function gotoByIndex(idx, transition)
    sceneIndex = idx
    composer:gotoScene(sceneNames[idx], {
        transition = transition,
        duration   = 0.5,
    })
end

function drawMetrics()
    local scene = composer:getCurrentScene()
    local name  = composer:getCurrentSceneName() or "none"
    local count = scene and scene:objectCount() or 0
    local memKB = collectgarbage("count")

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 4, 4, 260, 90, 4, 4)

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Scene: " .. name, 12, 10)
    love.graphics.print("Objects: " .. count, 12, 28)
    love.graphics.print(string.format("Memory: %.1f KB", memKB), 12, 46)
    love.graphics.print("[1/2/3] scene  [</>] slide  [esc] quit", 12, 68)
    love.graphics.setColor(1, 1, 1, 1)
end
