-- transitions.lua - built-in transition functions for Composer
-- Each function: (outCanvas, inCanvas, progress, w, h) -> outAlpha, inAlpha, outX, outY, inX, inY

local transitions = {}

function transitions.fade(outCanvas, inCanvas, progress, w, h)
    return 1 - progress, progress, 0, 0, 0, 0
end

function transitions.slideLeft(outCanvas, inCanvas, progress, w, h)
    return 1, 1, -w * progress, 0, w * (1 - progress), 0
end

function transitions.slideRight(outCanvas, inCanvas, progress, w, h)
    return 1, 1, w * progress, 0, -w * (1 - progress), 0
end

function transitions.slideUp(outCanvas, inCanvas, progress, w, h)
    return 1, 1, 0, -h * progress, 0, h * (1 - progress)
end

function transitions.slideDown(outCanvas, inCanvas, progress, w, h)
    return 1, 1, 0, h * progress, 0, -h * (1 - progress)
end

function transitions.slideFade(outCanvas, inCanvas, progress, w, h)
    return 1 - progress, progress, -w * progress * 0.3, 0, w * (1 - progress) * 0.3, 0
end

function transitions.none(outCanvas, inCanvas, progress, w, h)
    if progress < 1 then
        return 1, 0, 0, 0, 0, 0
    end
    return 0, 1, 0, 0, 0, 0
end

return transitions
