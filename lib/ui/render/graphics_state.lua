local Types = require('lib.ui.utils.types')
local Rectangle = require('lib.ui.core.rectangle')

local GraphicsState = {}

function GraphicsState.get_scissor_rect(graphics)
    if not Types.is_function(graphics.getScissor) then
        return nil
    end

    local x, y, width, height = graphics.getScissor()

    if x == nil or y == nil or width == nil or height == nil then
        return nil
    end

    return Rectangle(x, y, width, height)
end

function GraphicsState.set_scissor_rect(graphics, rect)
    if not Types.is_function(graphics.setScissor) then
        return
    end

    if rect == nil then
        graphics.setScissor()
        return
    end

    graphics.setScissor(rect.x, rect.y, rect.width, rect.height)
end

function GraphicsState.get_stencil_test(graphics)
    if not Types.is_function(graphics.getStencilTest) then
        return nil, nil
    end

    return graphics.getStencilTest()
end

function GraphicsState.set_stencil_test(graphics, compare, value)
    if not Types.is_function(graphics.setStencilTest) then
        return
    end

    if compare == nil then
        graphics.setStencilTest()
        return
    end

    graphics.setStencilTest(compare, value)
end

function GraphicsState.get_current_canvas(graphics)
    if not Types.is_function(graphics.getCanvas) then
        return nil
    end

    return graphics.getCanvas()
end

function GraphicsState.set_current_canvas(graphics, canvas)
    if not Types.is_function(graphics.setCanvas) then
        return
    end

    graphics.setCanvas(canvas)
end

function GraphicsState.get_current_color(graphics)
    if not Types.is_function(graphics.getColor) then
        return nil
    end

    return { graphics.getColor() }
end

function GraphicsState.restore_color(graphics, color)
    if color == nil or not Types.is_function(graphics.setColor) then
        return
    end

    graphics.setColor(color[1], color[2], color[3], color[4])
end

function GraphicsState.get_current_shader(graphics)
    if not Types.is_function(graphics.getShader) then
        return nil
    end

    return graphics.getShader()
end

function GraphicsState.restore_shader(graphics, shader)
    if not Types.is_function(graphics.setShader) then
        return
    end

    graphics.setShader(shader)
end

function GraphicsState.get_current_blend_mode(graphics)
    if not Types.is_function(graphics.getBlendMode) then
        return nil
    end

    return { graphics.getBlendMode() }
end

function GraphicsState.set_blend_mode(graphics, mode, alpha_mode)
    if not Types.is_function(graphics.setBlendMode) then
        return
    end

    if mode == 'normal' then
        mode = 'alpha'
    end

    if alpha_mode == nil and (mode == 'multiply' or mode == 'lighten' or mode == 'darken') then
        alpha_mode = 'premultiplied'
    end

    if alpha_mode ~= nil then
        graphics.setBlendMode(mode, alpha_mode)
        return
    end

    graphics.setBlendMode(mode)
end

function GraphicsState.restore_blend_mode(graphics, blend_mode)
    if blend_mode == nil or not Types.is_function(graphics.setBlendMode) then
        return
    end

    GraphicsState.set_blend_mode(graphics, blend_mode[1], blend_mode[2])
end

function GraphicsState.clear_target(graphics)
    if Types.is_function(graphics.clear) then
        graphics.clear(0, 0, 0, 0)
    end
end

return GraphicsState
