local Assert = require('lib.ui.utils.assert')
local Easing = require('lib.ui.core.easing')
local Types = require('lib.ui.utils.types')
local MathUtils = require('lib.ui.utils.math')

local Transitions = {}

local BUILTIN_TRANSITIONS = {}

local function clamp_01(value)
    if not Types.is_number(value) then
        return 0
    end

    if value <= 0 then
        return 0
    end

    if value >= 1 then
        return 1
    end

    return MathUtils.clamp(value, 0, 1)
end

local function unwrap_canvas(canvas)
    if Types.is_table(canvas) and rawget(canvas, 'handle') ~= nil then
        return rawget(canvas, 'handle')
    end

    return canvas
end

local function draw_canvas(graphics, canvas, x, y, alpha)
    local handle = unwrap_canvas(canvas)

    if handle == nil or not Types.is_function(graphics.draw) then
        return
    end

    local restore_color = nil

    if Types.is_function(graphics.getColor) then
        local r, g, b, a = graphics.getColor()
        restore_color = { r, g, b, a }
    end

    if Types.is_function(graphics.setColor) then
        local red = 1
        local green = 1
        local blue = 1
        local current_alpha = 1

        if restore_color ~= nil then
            red = restore_color[1] or 1
            green = restore_color[2] or 1
            blue = restore_color[3] or 1
            current_alpha = restore_color[4] or 1
        end

        graphics.setColor(red, green, blue, current_alpha * (alpha or 1))
    end

    graphics.draw(handle, x or 0, y or 0)

    if restore_color ~= nil and Types.is_function(graphics.setColor) then
        graphics.setColor(
            restore_color[1],
            restore_color[2],
            restore_color[3],
            restore_color[4]
        )
    end
end

local function resolve_easing(easing, level)
    if easing == nil then
        return Easing.smoothstep
    end

    if Types.is_function(easing) then
        return easing
    end

    if Types.is_string(easing) and Types.is_function(Easing[easing]) then
        return Easing[easing]
    end

    Assert.fail(
        'transition easing must be a function or a known easing name',
        level or 1
    )
end

local function create_transition(compose_factory)
    return function(definition)
        local easing = resolve_easing(definition and definition.easing, 4)

        return {
            compose = function(graphics, progress, outgoing_canvas, incoming_canvas, width, height)
                compose_factory(
                    graphics,
                    easing(clamp_01(progress)),
                    outgoing_canvas,
                    incoming_canvas,
                    width or 0,
                    height or 0
                )
            end,
        }
    end
end

BUILTIN_TRANSITIONS.fade = create_transition(function(graphics, progress, outgoing_canvas, incoming_canvas)
    draw_canvas(graphics, outgoing_canvas, 0, 0, 1 - progress)
    draw_canvas(graphics, incoming_canvas, 0, 0, progress)
end)

BUILTIN_TRANSITIONS.slideLeft = create_transition(function(graphics, progress, outgoing_canvas, incoming_canvas, width)
    draw_canvas(graphics, outgoing_canvas, -width * progress, 0, 1)
    draw_canvas(graphics, incoming_canvas, width * (1 - progress), 0, 1)
end)

BUILTIN_TRANSITIONS.slideRight = create_transition(function(graphics, progress, outgoing_canvas, incoming_canvas, width)
    draw_canvas(graphics, outgoing_canvas, width * progress, 0, 1)
    draw_canvas(graphics, incoming_canvas, -width * (1 - progress), 0, 1)
end)

BUILTIN_TRANSITIONS.slideUp = create_transition(function(graphics, progress, outgoing_canvas, incoming_canvas, _, height)
    draw_canvas(graphics, outgoing_canvas, 0, -height * progress, 1)
    draw_canvas(graphics, incoming_canvas, 0, height * (1 - progress), 1)
end)

BUILTIN_TRANSITIONS.slideDown = create_transition(function(graphics, progress, outgoing_canvas, incoming_canvas, _, height)
    draw_canvas(graphics, outgoing_canvas, 0, height * progress, 1)
    draw_canvas(graphics, incoming_canvas, 0, -height * (1 - progress), 1)
end)

BUILTIN_TRANSITIONS.slideFade = create_transition(function(graphics, progress, outgoing_canvas, incoming_canvas, width)
    draw_canvas(graphics, outgoing_canvas, -width * progress, 0, 1 - progress)
    draw_canvas(graphics, incoming_canvas, width * (1 - progress), 0, progress)
end)

function Transitions.resolve(definition)
    if definition == nil or definition == false then
        return nil
    end

    if Types.is_string(definition) then
        local factory = BUILTIN_TRANSITIONS[definition]

        if factory == nil then
            Assert.fail('unknown internal transition "' .. definition .. '"', 2)
        end

        return factory({})
    end

    if Types.is_function(definition) then
        return {
            compose = definition,
        }
    end

    if not Types.is_table(definition) then
        Assert.fail(
            'transition must be nil, false, a built-in transition name, a compose function, or a transition table',
            2
        )
    end

    local compose = definition.compose or definition.update

    if not Types.is_function(compose) then
        Assert.fail(
            'transition tables must define compose(...) or update(...)',
            2
        )
    end

    if definition.easing == nil then
        return {
            compose = compose,
        }
    end

    local easing = resolve_easing(definition.easing, 2)

    return {
        compose = function(graphics, progress, outgoing_canvas, incoming_canvas, width, height)
            compose(
                graphics,
                easing(clamp_01(progress)),
                outgoing_canvas,
                incoming_canvas,
                width,
                height
            )
        end,
    }
end

return Transitions
