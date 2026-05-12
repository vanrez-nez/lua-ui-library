local Scene = require("lib.ui.scene.scene")
local Compat = require("scenes.ui_compat")
local Vec2 = Compat.Vec2

local FONT_PATH = "assets/fonts/DynaPuff-Regular.ttf"

local Components = {}

function Components.new()
    local scene = Scene.new()

    function scene:onCreate(params)
        local navigate = params and params.navigate
        local clickCount = 0

        local background = Compat.drawable({
            tag = "background",
            width = "fill",
            height = "fill",
            anchorX = 0,
            anchorY = 0,
            pivotX = 0,
            pivotY = 0,
        })
        function background.draw(drawable)
            local w, h = Compat.size(drawable.parent)
            love.graphics.setColor(0.10, 0.11, 0.14)
            love.graphics.rectangle("fill", 0, 0, w, h)
            love.graphics.setColor(0.14, 0.17, 0.23)
            love.graphics.rectangle("fill", 48, 56, w - 96, h - 112, 20, 20)
        end
        self:addChild(background)

        local title = Compat.text({
            text = "Components",
            fontPath = FONT_PATH,
            fontSize = 30,
            pos = Vec2(0, 0),
            anchor = Vec2(0.5, 0.16),
            pivot = Vec2(0.5, 0.5),
        })
        self:addChild(title)

        local description = Compat.text({
            text = "Text and Button are ready to iterate on here. The counter and status label give this scene a small interactive loop.",
            fontSize = 16,
            maxWidth = 560,
            pos = Vec2(0, 52),
            anchor = Vec2(0.5, 0.16),
            pivot = Vec2(0.5, 0.5),
            alignH = "center",
            color = { 0.82, 0.86, 0.92, 1 },
        })
        self:addChild(description)

        local status = Compat.text({
            text = "Status: waiting for input",
            fontSize = 16,
            pos = Vec2(0, 112),
            anchor = Vec2(0.5, 0.16),
            pivot = Vec2(0.5, 0.5),
            color = { 0.98, 0.91, 0.63, 1 },
        })
        self:addChild(status)

        local counterButton = Compat.button({
            label = "Counter 0",
            size = Vec2(220, 56),
            pos = Vec2(-150, 10),
            anchor = Vec2(0.5, 0.45),
            pivot = Vec2(0.5, 0.5),
            onClick = function(selfButton)
                clickCount = clickCount + 1
                selfButton:setLabel("Counter " .. clickCount)
                status:setText("Status: counter updated to " .. clickCount)
            end,
        })
        self:addChild(counterButton)

        local accentButton = Compat.button({
            label = "Accent Theme",
            size = Vec2(220, 56),
            pos = Vec2(150, 10),
            anchor = Vec2(0.5, 0.45),
            pivot = Vec2(0.5, 0.5),
            color = { 0.22, 0.29, 0.48 },
            hoverColor = { 0.29, 0.37, 0.62 },
            pressColor = { 0.18, 0.23, 0.38 },
            borderColor = { 0.50, 0.62, 0.95, 1 },
            onClick = function()
                status:setText("Status: accent button pressed")
            end,
        })
        self:addChild(accentButton)

        local disabledButton = Compat.button({
            label = "Disabled State",
            size = Vec2(220, 56),
            pos = Vec2(-150, 90),
            anchor = Vec2(0.5, 0.45),
            pivot = Vec2(0.5, 0.5),
            enabled = false,
        })
        self:addChild(disabledButton)

        local backButton = Compat.button({
            label = "Back Home",
            size = Vec2(220, 56),
            pos = Vec2(150, 90),
            anchor = Vec2(0.5, 0.45),
            pivot = Vec2(0.5, 0.5),
            color = { 0.18, 0.34, 0.25 },
            hoverColor = { 0.24, 0.44, 0.33 },
            pressColor = { 0.15, 0.26, 0.21 },
            borderColor = { 0.42, 0.72, 0.58, 1 },
            onClick = function()
                if navigate then
                    navigate("home", "fade")
                end
            end,
        })
        self:addChild(backButton)

        local caption = Compat.text({
            text = "For isolated visual checks, run the manual demos in _test/button and _test/text.",
            fontSize = 14,
            pos = Vec2(0, 210),
            anchor = Vec2(0.5, 0.45),
            pivot = Vec2(0.5, 0.5),
            color = { 0.66, 0.72, 0.78, 1 },
        })
        self:addChild(caption)
    end

    return scene
end

return Components
