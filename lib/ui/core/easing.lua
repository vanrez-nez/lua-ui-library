local Easing = {}

local function clamp_01(value)
    if type(value) ~= 'number' then
        return 0
    end

    if value <= 0 then
        return 0
    end

    if value >= 1 then
        return 1
    end

    return value
end

function Easing.linear(progress)
    return clamp_01(progress)
end

function Easing.smoothstep(progress)
    progress = clamp_01(progress)
    return progress * progress * (3 - 2 * progress)
end

function Easing.easeInQuad(progress)
    progress = clamp_01(progress)
    return progress * progress
end

function Easing.easeOutQuad(progress)
    progress = clamp_01(progress)
    return 1 - (1 - progress) * (1 - progress)
end

function Easing.easeInOutQuad(progress)
    progress = clamp_01(progress)

    if progress < 0.5 then
        return 2 * progress * progress
    end

    return 1 - ((-2 * progress + 2) ^ 2) / 2
end

function Easing.easeOutCubic(progress)
    progress = clamp_01(progress)
    return 1 - ((1 - progress) ^ 3)
end

function Easing.easeOutExpo(progress)
    progress = clamp_01(progress)

    if progress >= 1 then
        return 1
    end

    return 1 - (2 ^ (-10 * progress))
end

return Easing
