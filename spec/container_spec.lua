local Assert = require("spec.helpers.assert")
local Container = require("lib.ui.core.container")
local Vec2 = require("lib.ui.core.vec2")

return {
    {
        name = "positions a child using anchor and pivot",
        run = function()
            local root = Container.new({
                size = Vec2(200, 100),
                anchor = Vec2(0, 0),
                pivot = Vec2(0, 0),
            })
            local child = Container.new({
                size = Vec2(20, 10),
                anchor = Vec2(0.5, 0.5),
                pivot = Vec2(0.5, 0.5),
            })

            root:addChild(child)
            root:updateTransform()

            local x, y, w, h = child:getRect()
            Assert.near(x, 90)
            Assert.near(y, 45)
            Assert.near(w, 20)
            Assert.near(h, 10)
        end,
    },
    {
        name = "translates hit testing into local space",
        run = function()
            local root = Container.new({
                size = Vec2(200, 100),
                anchor = Vec2(0, 0),
                pivot = Vec2(0, 0),
            })
            local child = Container.new({
                size = Vec2(30, 20),
                pos = Vec2(25, 15),
                anchor = Vec2(0, 0),
                pivot = Vec2(0, 0),
            })

            root:addChild(child)
            root:updateTransform()

            Assert.truthy(child:containsPoint(30, 20))
            Assert.equal(child:containsPoint(10, 10), false)
        end,
    },
}
