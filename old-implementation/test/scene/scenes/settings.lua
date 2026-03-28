-- settings.lua - Demo scene 3: minimal objects (resource freeing demo)

local Scene    = require("lib.ui.scene.scene")
local Drawable = require("lib.ui.core.drawable")
local Vec2     = require("lib.ui.core.vec2")

local Settings = {}

function Settings.new(params)
    local scene = Scene.new({ sceneName = "settings" })

    function scene:create(params)
        local w, h = love.graphics.getDimensions()

        -- Background
        local bg = Drawable.new({
            tag  = "bg",
            size = Vec2(w, h),
            anchor = Vec2(0, 0),
            pivot  = Vec2(0, 0),
        })
        function bg:draw()
            love.graphics.setColor(0.2, 0.15, 0.2, 1)
            love.graphics.rectangle("fill", 0, 0, self.size.x, self.size.y)
        end
        self:addChild(bg)

        -- Settings panel
        local panel = Drawable.new({
            tag  = "panel",
            size = Vec2(300, 200),
            anchor = Vec2(0.5, 0.4),
            pivot  = Vec2(0.5, 0.5),
        })
        function panel:draw()
            love.graphics.setColor(0.3, 0.25, 0.35, 1)
            love.graphics.rectangle("fill", 0, 0, self.size.x, self.size.y, 10, 10)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("SETTINGS", 0, 30, self.size.x, "center")
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.printf("Minimal scene (~4 objects)\nDemonstrates memory freeing", 0, 80, self.size.x, "center")
        end
        self:addChild(panel)
    end

    function scene:onEnter(phase)
        print("[settings] onEnter " .. phase)
    end

    function scene:onLeave(phase)
        print("[settings] onLeave " .. phase)
    end

    return scene
end

return Settings
