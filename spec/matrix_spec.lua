local Assert = require("spec.helpers.assert")
local Matrix = require("lib.ui.core.matrix")

return {
    {
        name = "applies translation and inversion",
        run = function()
            local matrix = Matrix.new()
            matrix:translate(12, -7)

            local x, y = matrix:apply(4, 9)
            local lx, ly = matrix:applyInverse(x, y)

            Assert.equal(x, 16)
            Assert.equal(y, 2)
            Assert.near(lx, 4)
            Assert.near(ly, 9)
        end,
    },
    {
        name = "appends transforms in order",
        run = function()
            local left = Matrix.new()
            left:translate(10, 5)

            local right = Matrix.new()
            right:scale(2, 3)

            left:append(right)
            local x, y = left:apply(4, 6)

            Assert.equal(x, 18)
            Assert.equal(y, 23)
        end,
    },
}
