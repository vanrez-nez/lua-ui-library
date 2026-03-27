local Assert = require("spec.helpers.assert")
local Rectangle = require("lib.ui.core.rectangle")

return {
    {
        name = "fits to the overlapping area",
        run = function()
            local a = Rectangle.new(0, 0, 20, 20)
            local b = Rectangle.new(10, 8, 20, 20)

            a:fit(b)

            Assert.equal(a.x, 10)
            Assert.equal(a.y, 8)
            Assert.equal(a.width, 10)
            Assert.equal(a.height, 12)
        end,
    },
    {
        name = "enlarges to include another rect",
        run = function()
            local a = Rectangle.new(5, 5, 10, 10)
            local b = Rectangle.new(-2, 8, 4, 6)

            a:enlarge(b)

            Assert.equal(a.x, -2)
            Assert.equal(a.y, 5)
            Assert.equal(a.width, 17)
            Assert.equal(a.height, 10)
        end,
    },
}
