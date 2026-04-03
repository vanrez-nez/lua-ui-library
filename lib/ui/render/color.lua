local Color = {}

-- Named color catalog — nine entries only, per spec §5.3
-- Values are {r, g, b, a} in [0, 1] space
local NAMED_COLORS = {
    transparent = { 0,         0,         0,         0 },
    black       = { 0,         0,         0,         1 },
    white       = { 1,         1,         1,         1 },
    red         = { 1,         0,         0,         1 },
    green       = { 0,         128 / 255, 0,         1 },  -- #008000
    blue        = { 0,         0,         1,         1 },
    yellow      = { 1,         1,         0,         1 },
    cyan        = { 0,         1,         1,         1 },
    magenta     = { 1,         0,         1,         1 },
}

local function shallow_copy(t)
    return { t[1], t[2], t[3], t[4] }
end

-- Adapted from reference/color.lua is_color: validate positional fields are numbers.
-- Returns the component count (3 or 4) or raises an error.
local function validate_numeric_components(input, level)
    for i = 1, 3 do
        if type(input[i]) ~= "number" then
            if input[i] == nil then
                error("color: missing required component [" .. i .. "]", level)
            else
                error("color: component [" .. i .. "] must be a number, got " .. type(input[i]), level)
            end
        end
    end
    if input[4] ~= nil and type(input[4]) ~= "number" then
        error("color: alpha component must be a number, got " .. type(input[4]), level)
    end
end

local function parse_numeric(input, level)
    validate_numeric_components(input, level)

    local r, g, b, a = input[1], input[2], input[3], input[4]
    local has_alpha = a ~= nil
    local max_val = has_alpha and math.max(r, g, b, a) or math.max(r, g, b)

    if max_val <= 1 then
        -- [0, 1] passthrough — alpha defaults to 1 when absent
        return { r, g, b, a or 1 }
    end

    -- [0, 255] range detected: every component must be an integer and <= 255
    local components = has_alpha and { r, g, b, a } or { r, g, b }
    for _, v in ipairs(components) do
        if math.floor(v) ~= v then
            error("color: mixed-scale input — non-integer component alongside a component > 1", level)
        end
        if v > 255 then
            error("color: component exceeds 255 in [0,255] range input", level)
        end
    end

    return { r / 255, g / 255, b / 255, (a or 255) / 255 }
end

local function parse_hex(input, level)
    local hex = input:sub(2)  -- strip '#'
    local len = #hex
    local r_hex, g_hex, b_hex, a_hex

    if len == 3 then
        r_hex = hex:sub(1, 1):rep(2)
        g_hex = hex:sub(2, 2):rep(2)
        b_hex = hex:sub(3, 3):rep(2)
    elseif len == 4 then
        r_hex = hex:sub(1, 1):rep(2)
        g_hex = hex:sub(2, 2):rep(2)
        b_hex = hex:sub(3, 3):rep(2)
        a_hex = hex:sub(4, 4):rep(2)
    elseif len == 6 then
        r_hex = hex:sub(1, 2)
        g_hex = hex:sub(3, 4)
        b_hex = hex:sub(5, 6)
    elseif len == 8 then
        r_hex = hex:sub(1, 2)
        g_hex = hex:sub(3, 4)
        b_hex = hex:sub(5, 6)
        a_hex = hex:sub(7, 8)
    else
        error("color: invalid hex color '" .. input .. "' — expected #RGB, #RGBA, #RRGGBB, or #RRGGBBAA", level)
    end

    local r = tonumber(r_hex, 16)
    local g = tonumber(g_hex, 16)
    local b = tonumber(b_hex, 16)

    if r == nil or g == nil or b == nil then
        error("color: invalid hex color '" .. input .. "' — invalid hex characters", level)
    end

    if a_hex then
        local a = tonumber(a_hex, 16)
        if a == nil then
            error("color: invalid hex color '" .. input .. "' — invalid hex characters in alpha", level)
        end
        return { r / 255, g / 255, b / 255, a / 255 }
    end

    return { r / 255, g / 255, b / 255, 1 }
end

local function parse_hsl(input, level)
    -- Try hsla (4 args) first, then hsl (3 args)
    local h_s, s_s, l_s, a_s = input:match("^hsla%s*%((.-),%s*(.-),%s*(.-),%s*(.-)%s*%)$")
    local has_alpha = h_s ~= nil

    if not has_alpha then
        h_s, s_s, l_s = input:match("^hsl%s*%((.-),%s*(.-),%s*(.-)%s*%)$")
    end

    if not h_s then
        error("color: malformed hsl/hsla string '" .. input .. "'", level)
    end

    local h = tonumber(h_s)
    local s = tonumber(s_s)
    local l = tonumber(l_s)
    local a = has_alpha and tonumber(a_s) or 1

    if h == nil or s == nil or l == nil or (has_alpha and a == nil) then
        error("color: malformed hsl/hsla arguments in '" .. input .. "'", level)
    end

    if s < 0 or s > 1 then
        error("color: hsl saturation must be in [0, 1], got " .. s, level)
    end
    if l < 0 or l > 1 then
        error("color: hsl lightness must be in [0, 1], got " .. l, level)
    end
    if a < 0 or a > 1 then
        error("color: hsl alpha must be in [0, 1], got " .. a, level)
    end

    -- Hue wraps for any finite value; Lua % with positive divisor is always non-negative
    h = h % 360

    -- Standard HSL → RGB conversion
    -- C = chroma, H' = normalized hue sector, X = intermediate, m = lightness match
    local C = (1 - math.abs(2 * l - 1)) * s
    local H_prime = h / 60
    local X = C * (1 - math.abs(H_prime % 2 - 1))
    local m = l - C / 2

    local r1, g1, b1
    local sector = math.floor(H_prime)

    if sector == 0 then     r1, g1, b1 = C, X, 0
    elseif sector == 1 then r1, g1, b1 = X, C, 0
    elseif sector == 2 then r1, g1, b1 = 0, C, X
    elseif sector == 3 then r1, g1, b1 = 0, X, C
    elseif sector == 4 then r1, g1, b1 = X, 0, C
    else                    r1, g1, b1 = C, 0, X  -- sector 5
    end

    return { r1 + m, g1 + m, b1 + m, a }
end

-- Color.resolve(input) — single public entry point.
-- Returns {r, g, b, a} with all components in [0, 1].
-- Raises a hard error on any invalid input.
function Color.resolve(input)
    local t = type(input)

    if t == "table" then
        return parse_numeric(input, 3)
    elseif t == "string" then
        if #input == 0 then
            error("color: unsupported color string ''", 2)
        end
        if input:sub(1, 1) == "#" then
            return parse_hex(input, 3)
        elseif input:sub(1, 4) == "hsl(" or input:sub(1, 5) == "hsla(" then
            return parse_hsl(input, 3)
        elseif NAMED_COLORS[input] then
            return shallow_copy(NAMED_COLORS[input])
        else
            error("color: unsupported color string '" .. input .. "'", 2)
        end
    else
        error("color: expected a table or string, got " .. t, 2)
    end
end

return Color
