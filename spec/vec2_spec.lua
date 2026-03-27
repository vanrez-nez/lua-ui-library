local Assert = require("spec.helpers.assert")
local Vec2 = require("lib.ui.core.vec2")

return {
    {
        name = "supports arithmetic operators",
        run = function()
            local sum = Vec2(2, 3) + Vec2(4, 5)
            local product = Vec2(2, 3) * 4

            Assert.equal(sum.x, 6)
            Assert.equal(sum.y, 8)
            Assert.equal(product.x, 8)
            Assert.equal(product.y, 12)
        end,
    },
    {
        name = "clones and lerps",
        run = function()
            local a = Vec2(10, 20)
            local b = Vec2(30, 60)
            local cloned = a:clone()
            local lerped = a:lerp(b, 0.25)

            Assert.truthy(cloned == a)
            Assert.equal(lerped.x, 15)
            Assert.equal(lerped.y, 30)
        end,
    },
}
