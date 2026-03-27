-- menu.lua - Demo scene 1: title/menu screen

local Scene    = require("lib.ui.scene.scene")
local Drawable = require("lib.ui.core.drawable")
local Vec2     = require("lib.ui.core.vec2")

local Menu = {}

function Menu.new(params)
    local scene = Scene.new({ sceneName = "menu" })
    return scene
end

-- Override create to build scene contents
local originalCreate = Scene.create
function Menu.new(params)
    local scene = Scene.new({ sceneName = "menu" })

    -- Override lifecycle and draw/update for this instance
    function scene:create(params)
        local w, h = love.graphics.getDimensions()

        -- Background panel
        local bg = Drawable.new({
            tag    = "bg",
            size   = Vec2(w, h),
            anchor = Vec2(0, 0),
            pivot  = Vec2(0, 0),
        })
        function bg:draw()
            love.graphics.setColor(0.15, 0.15, 0.25, 1)
            love.graphics.rectangle("fill", 0, 0, self.size.x, self.size.y)
        end
        self:addChild(bg)

        -- Title panel
        local titlePanel = Drawable.new({
            tag  = "title_panel",
            size = Vec2(400, 80),
            anchor = Vec2(0.5, 0.3),
            pivot  = Vec2(0.5, 0.5),
        })
        function titlePanel:draw()
            love.graphics.setColor(0.3, 0.5, 0.8, 1)
            love.graphics.rectangle("fill", 0, 0, self.size.x, self.size.y, 8, 8)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("SCENE DEMO", 0, 25, self.size.x, "center")
        end
        self:addChild(titlePanel)

        -- Subtitle
        local subtitle = Drawable.new({
            tag  = "subtitle",
            size = Vec2(400, 40),
            anchor = Vec2(0.5, 0.45),
            pivot  = Vec2(0.5, 0.5),
        })
        function subtitle:draw()
            love.graphics.setColor(0.7, 0.7, 0.8, 1)
            love.graphics.printf("Press 1, 2, 3 or arrow keys to navigate", 0, 10, self.size.x, "center")
        end
        self:addChild(subtitle)

        -- Decorative panels
        local colors = {
            {0.8, 0.3, 0.3},
            {0.3, 0.8, 0.3},
            {0.3, 0.3, 0.8},
        }
        for i, col in ipairs(colors) do
            local panel = Drawable.new({
                tag  = "panel_" .. i,
                size = Vec2(100, 100),
                anchor = Vec2(0.2 + (i - 1) * 0.3, 0.7),
                pivot  = Vec2(0.5, 0.5),
            })
            panel._color = col
            function panel:draw()
                love.graphics.setColor(self._color[1], self._color[2], self._color[3], 0.8)
                love.graphics.rectangle("fill", 0, 0, self.size.x, self.size.y, 6, 6)
            end
            self:addChild(panel)
        end
    end

    function scene:onEnter(phase)
        print("[menu] onEnter " .. phase)
    end

    function scene:onLeave(phase)
        print("[menu] onLeave " .. phase)
    end

    return scene
end

return Menu
