local Scene = require("lib.ui.scene.scene")
local Drawable = require("lib.ui.core.drawable")
local Text = require("lib.ui.components.text")
local Button = require("lib.ui.components.button")
local Vec2 = require("lib.ui.core.vec2")

local FONT_PATH = "assets/fonts/DynaPuff-Regular.ttf"

local Home = {}

function Home.new()
    local scene = Scene.new({ sceneName = "home" })

    function scene:create(params)
        local navigate = params and params.navigate

        local background = Drawable.new({
            tag = "background",
            size = Vec2(self.size.x, self.size.y),
            anchor = Vec2(0, 0),
            pivot = Vec2(0, 0),
        })
        function background:draw()
            local w, h = self.parent.size.x, self.parent.size.y
            love.graphics.setColor(0.08, 0.09, 0.12)
            love.graphics.rectangle("fill", 0, 0, w, h)
            love.graphics.setColor(0.16, 0.20, 0.28, 1)
            love.graphics.circle("fill", w * 0.18, h * 0.22, 90)
            love.graphics.setColor(0.22, 0.30, 0.22, 0.95)
            love.graphics.circle("fill", w * 0.82, h * 0.78, 120)
            love.graphics.setColor(0.11, 0.13, 0.18, 1)
            love.graphics.rectangle("fill", w * 0.12, h * 0.18, w * 0.76, h * 0.64, 24, 24)
        end
        self:addChild(background)

        local title = Text.new({
            text = "Lua UI Library",
            fontPath = FONT_PATH,
            fontSize = 34,
            pos = Vec2(0, -120),
            anchor = Vec2(0.5, 0.28),
            pivot = Vec2(0.5, 0.5),
        })
        self:addChild(title)

        local subtitle = Text.new({
            text = "Standalone LÖVE project for the extracted lib/ui package.",
            maxWidth = 540,
            fontSize = 18,
            pos = Vec2(0, -60),
            anchor = Vec2(0.5, 0.34),
            pivot = Vec2(0.5, 0.5),
            alignH = "center",
        })
        self:addChild(subtitle)

        local componentsButton = Button.new({
            label = "Open Components Scene",
            size = Vec2(280, 60),
            pos = Vec2(0, 20),
            anchor = Vec2(0.5, 0.5),
            pivot = Vec2(0.5, 0.5),
            onClick = function()
                if navigate then
                    navigate("components", "fade")
                end
            end,
        })
        self:addChild(componentsButton)

        local transformsButton = Button.new({
            label = "Open Transforms Scene",
            size = Vec2(280, 60),
            pos = Vec2(0, 100),
            anchor = Vec2(0.5, 0.5),
            pivot = Vec2(0.5, 0.5),
            color = { 0.18, 0.33, 0.28 },
            hoverColor = { 0.24, 0.42, 0.36 },
            pressColor = { 0.14, 0.25, 0.21 },
            borderColor = { 0.43, 0.69, 0.58, 1 },
            onClick = function()
                if navigate then
                    navigate("transforms", "fade")
                end
            end,
        })
        self:addChild(transformsButton)

        local footer = Text.new({
            text = "Use the root app for scene work. Use the test folders for focused component checks.",
            maxWidth = 620,
            fontSize = 15,
            pos = Vec2(0, 180),
            anchor = Vec2(0.5, 0.5),
            pivot = Vec2(0.5, 0.5),
            alignH = "center",
            color = { 0.78, 0.82, 0.88, 1 },
        })
        self:addChild(footer)
    end

    return scene
end

return Home
