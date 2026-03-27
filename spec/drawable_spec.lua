local Assert = require("spec.helpers.assert")
local Drawable = require("lib.ui.core.drawable")
local Vec2 = require("lib.ui.core.vec2")

return {
    {
        name = "normalizes padding and computes content rect",
        run = function()
            local drawable = Drawable.new({
                size = Vec2(100, 50),
                padding = { 4, 10, 6, 8 },
            })

            local x, y, w, h = drawable:getContentRect()

            Assert.equal(x, 8)
            Assert.equal(y, 4)
            Assert.equal(w, 82)
            Assert.equal(h, 40)
        end,
    },
    {
        name = "positions content using alignment",
        run = function()
            local drawable = Drawable.new({
                size = Vec2(120, 60),
                padding = 10,
                alignH = "right",
                alignV = "bottom",
            })

            local x, y = drawable:getContentOrigin(30, 20)

            Assert.equal(x, 80)
            Assert.equal(y, 30)
        end,
    },
}
