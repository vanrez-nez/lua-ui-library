local Types = require('lib.ui.utils.types')

local GraphicsStencil = {}

function GraphicsStencil.save(graphics)
    if Types.is_function(graphics.getStencilTest) then
        return { graphics.getStencilTest() }
    end

    return nil
end

function GraphicsStencil.restore(graphics, saved_state)
    if not Types.is_function(graphics.setStencilTest) then
        return
    end

    if saved_state == nil or saved_state[1] == nil then
        graphics.setStencilTest()
        return
    end

    graphics.setStencilTest(saved_state[1], saved_state[2])
end

function GraphicsStencil.write_polygon(graphics, flat_points)
    if not Types.is_function(graphics.stencil) or
        not Types.is_function(graphics.polygon) then
        return false
    end

    graphics.stencil(function()
        graphics.polygon('fill', flat_points)
    end, 'replace', 1)

    return true
end

return GraphicsStencil
