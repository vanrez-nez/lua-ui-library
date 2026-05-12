local Scene = require("lib.ui.scene.scene")
local Compat = require("scenes.ui_compat")
local Vec2 = Compat.Vec2

local FONT_PATH = "assets/fonts/DynaPuff-Regular.ttf"

local function makePanel(tag, size, anchor, pivot, color, label)
    local panel = Compat.drawable({
        tag = tag,
        size = size,
        anchor = anchor,
        pivot = pivot,
    })
    panel._color = color
    panel._label = label

    function panel:draw()
        local w, h = Compat.size(self)
        love.graphics.setColor(self._color[1], self._color[2], self._color[3], 0.88)
        love.graphics.rectangle("fill", 0, 0, w, h, 16, 16)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.rectangle("line", 0, 0, w, h, 16, 16)
        love.graphics.printf(self._label, 0, h * 0.5 - 10, w, "center")
    end

    return panel
end

local Transforms = {}

function Transforms.new()
    local scene = Scene.new()

    function scene:onCreate(params)
        local navigate = params and params.navigate

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
            love.graphics.setColor(0.08, 0.10, 0.11)
            love.graphics.rectangle("fill", 0, 0, w, h)
            love.graphics.setColor(0.13, 0.15, 0.17)
            love.graphics.rectangle("fill", 36, 36, w - 72, h - 72, 28, 28)
        end
        self:addChild(background)

        local title = Compat.text({
            text = "Transforms",
            fontPath = FONT_PATH,
            fontSize = 30,
            pos = Vec2(0, 0),
            anchor = Vec2(0.5, 0.12),
            pivot = Vec2(0.5, 0.5),
        })
        self:addChild(title)

        local subtitle = Compat.text({
            text = "Nested drawables animate rotation and scale so changes to Container math are visible quickly.",
            fontSize = 16,
            maxWidth = 560,
            pos = Vec2(0, 50),
            anchor = Vec2(0.5, 0.12),
            pivot = Vec2(0.5, 0.5),
            alignH = "center",
            color = { 0.83, 0.88, 0.93, 1 },
        })
        self:addChild(subtitle)

        self.outer = makePanel(
            "outer",
            Vec2(330, 230),
            Vec2(0.5, 0.58),
            Vec2(0.5, 0.5),
            { 0.39, 0.25, 0.22 },
            "Outer"
        )
        self.middle = makePanel(
            "middle",
            Vec2(210, 145),
            Vec2(0.50, 0.50),
            Vec2(0.5, 0.5),
            { 0.20, 0.37, 0.30 },
            "Middle"
        )
        self.inner = makePanel("inner", Vec2(115, 75), Vec2(0.78, 0.48), Vec2(0.5, 0.5), { 0.22, 0.29, 0.45 }, "Inner")

        self.outer:addChild(self.middle)
        self.middle:addChild(self.inner)
        self:addChild(self.outer)

        local backButton = Compat.button({
            label = "Back Home",
            size = Vec2(220, 56),
            pos = Vec2(0, 185),
            anchor = Vec2(0.5, 0.58),
            pivot = Vec2(0.5, 0.5),
            onClick = function()
                if navigate then
                    navigate("home", "fade")
                end
            end,
        })
        self:addChild(backButton)
    end

    function scene:update(dt)
        Scene.update(self, dt)

        self._time = (self._time or 0) + dt
        local t = self._time

        if self.outer then
            self.outer.rotation = math.sin(t * 0.45) * 0.18
            self.outer.scaleX = 1 + math.sin(t * 0.70) * 0.08
            self.outer.scaleY = 1 + math.cos(t * 0.60) * 0.06
            self.outer:markDirty()
        end

        if self.middle then
            self.middle.rotation = -t * 0.9
            self.middle.scaleX = 1 + math.sin(t * 1.10) * 0.10
            self.middle.scaleY = 1 + math.cos(t * 1.00) * 0.10
            self.middle:markDirty()
        end

        if self.inner then
            self.inner.rotation = t * 1.8
            Compat.set_pos(self.inner, math.cos(t * 1.4) * 12, math.sin(t * 1.2) * 16)
            self.inner:markDirty()
        end
    end

    return scene
end

return Transforms
