-- game.lua - Demo scene 2: image loading/unloading + 60+ objects

local Scene    = require("lib.ui.scene.scene")
local Drawable = require("lib.ui.core.drawable")
local Vec2     = require("lib.ui.core.vec2")

-- Resolve image path relative to project root (two levels up from test/scene/)
local SOURCE_DIR = love.filesystem.getSource()
local IMAGE_PATH = SOURCE_DIR .. "/../../assets/images/image.png"

local Game = {}

function Game.new(params)
    local scene = Scene.new({ sceneName = "game" })

    -- Resource handle, loaded/released via lifecycle
    scene._image = nil

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
            love.graphics.setColor(0.1, 0.18, 0.12, 1)
            love.graphics.rectangle("fill", 0, 0, self.size.x, self.size.y)
        end
        self:addChild(bg)

        -- Image display (draws the loaded texture)
        local imgDisplay = Drawable.new({
            tag    = "image",
            size   = Vec2(256, 256),
            anchor = Vec2(0.5, 0.08),
            pivot  = Vec2(0.5, 0),
        })
        imgDisplay._scene = self
        function imgDisplay:draw()
            local img = self._scene._image
            if img then
                love.graphics.setColor(1, 1, 1, 1)
                local sx = self.size.x / img:getWidth()
                local sy = self.size.y / img:getHeight()
                love.graphics.draw(img, 0, 0, 0, sx, sy)
            else
                love.graphics.setColor(0.3, 0.3, 0.3, 1)
                love.graphics.rectangle("fill", 0, 0, self.size.x, self.size.y, 4, 4)
                love.graphics.setColor(0.6, 0.6, 0.6, 1)
                love.graphics.printf("(unloaded)", 0, self.size.y / 2 - 8, self.size.x, "center")
            end
        end
        self:addChild(imgDisplay)

        -- Grid of colored cells below the image (8x8 = 64 cells)
        local cols, rows = 8, 8
        local cellW, cellH = 50, 28
        local gridW = cols * (cellW + 3) - 3
        local gridH = rows * (cellH + 3) - 3
        local startX = (w - gridW) / 2
        local startY = h * 0.08 + 256 + 16

        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                local cell = Drawable.new({
                    tag  = "cell_" .. row .. "_" .. col,
                    size = Vec2(cellW, cellH),
                    anchor = Vec2(0, 0),
                    pivot  = Vec2(0, 0),
                    pos  = Vec2(startX + col * (cellW + 3), startY + row * (cellH + 3)),
                })
                local r = 0.3 + (col / cols) * 0.5
                local g = 0.3 + (row / rows) * 0.5
                cell._color = {r, g, 0.5}
                function cell:draw()
                    love.graphics.setColor(self._color[1], self._color[2], self._color[3], 0.9)
                    love.graphics.rectangle("fill", 0, 0, self.size.x, self.size.y, 3, 3)
                end
                self:addChild(cell)
            end
        end
    end

    function scene:onEnter(phase)
        print("[game] onEnter " .. phase)
        if phase == "before" then
            -- Load image from disk (outside LOVE sandbox)
            local f = assert(io.open(IMAGE_PATH, "rb"))
            local bytes = f:read("*a")
            f:close()
            local fileData = love.filesystem.newFileData(bytes, "image.png")
            local imageData = love.image.newImageData(fileData)
            self._image = love.graphics.newImage(imageData)
            self._image:setFilter("linear", "linear")
            imageData:release()
            fileData:release()
            print("[game] loaded image: " .. IMAGE_PATH)
        end
    end

    function scene:onLeave(phase)
        print("[game] onLeave " .. phase)
        if phase == "after" then
            -- Release image resource for GC
            self._image:release()
            self._image = nil
            print("[game] released image: " .. IMAGE_PATH)
        end
    end

    return scene
end

return Game
