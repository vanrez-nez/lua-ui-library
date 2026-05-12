local Composer = require("lib.ui.scene.composer")
local transitions = require("lib.ui.scene.transitions")

local composer
local sceneNames = { "home", "components", "transforms" }
local sceneIndex = 1
local sceneIndexByName = {
    home = 1,
    components = 2,
    transforms = 3,
}

local function transitionDuration(transition)
    if transition == "none" or transition == transitions.none then
        return 0
    end
    return 0.35
end

local function gotoScene(name, transition)
    sceneIndex = sceneIndexByName[name] or sceneIndex
    composer:gotoScene(name, {
        transition = transition or "fade",
        duration = transitionDuration(transition),
        params = {
            navigate = gotoScene,
        },
    })
end

local function gotoByIndex(index, transition)
    gotoScene(sceneNames[index], transition)
end

local function countObjects(node)
    if node == nil then
        return 0
    end

    local count = 1
    local children = node._children or {}

    for index = 1, #children do
        count = count + countObjects(children[index])
    end

    return count
end

local function drawOverlay()
    local scene = composer._current_scene
    local name = composer._current_scene_name or "none"
    local count = countObjects(scene)

    love.graphics.setColor(0.05, 0.06, 0.08, 0.82)
    love.graphics.rectangle("fill", 12, 12, 360, 96, 12, 12)

    love.graphics.setColor(0.96, 0.98, 1, 1)
    love.graphics.print("Scene: " .. name, 24, 24)
    love.graphics.print("Objects: " .. count, 24, 44)
    love.graphics.print("[1/2/3] scene  [left/right] slide  [esc] quit", 24, 64)
    love.graphics.print("Manual demos: love src/lua/demos/01-container", 24, 84)
end

function love.load()
    love.graphics.setBackgroundColor(0.06, 0.07, 0.09)

    composer = Composer.new()
    composer:register("home", require("scenes.home"))
    composer:register("components", require("scenes.components"))
    composer:register("transforms", require("scenes.transforms"))

    gotoScene("home", "none")
end

function love.update(dt)
    composer:update(dt)
end

function love.draw()
    composer:draw()
    drawOverlay()
end

function love.resize(w, h)
    composer:resize(w, h)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    end

    if key == "1" then
        gotoByIndex(1, "fade")
    elseif key == "2" then
        gotoByIndex(2, "fade")
    elseif key == "3" then
        gotoByIndex(3, "fade")
    elseif key == "left" then
        sceneIndex = sceneIndex - 1
        if sceneIndex < 1 then
            sceneIndex = #sceneNames
        end
        gotoByIndex(sceneIndex, transitions.slideRight)
    elseif key == "right" then
        sceneIndex = sceneIndex + 1
        if sceneIndex > #sceneNames then
            sceneIndex = 1
        end
        gotoByIndex(sceneIndex, transitions.slideLeft)
    end

    composer:deliverInput({
        kind = "keypressed",
        key = key,
    })
end

function love.mousepressed(x, y, button)
    composer:deliverInput({
        kind = "mousepressed",
        x = x,
        y = y,
        button = button,
    })
end

function love.mousereleased(x, y, button)
    composer:deliverInput({
        kind = "mousereleased",
        x = x,
        y = y,
        button = button,
    })
end
