local NAMES = {
    white = { 1, 1, 1, 1 },
    black = { 0, 0, 0, 1 },

    slate_950 = { 0.07, 0.08, 0.1, 1 },
    slate_925 = { 0.08, 0.09, 0.12, 1 },
    slate_900 = { 0.12, 0.13, 0.17, 1 },
    slate_850 = { 0.14, 0.15, 0.19, 1 },
    slate_800 = { 0.14, 0.16, 0.21, 1 },
    slate_750 = { 0.16, 0.18, 0.24, 1 },
    slate_500 = { 0.67, 0.7, 0.77, 1 },
    slate_400 = { 0.72, 0.75, 0.81, 1 },
    slate_100 = { 0.93, 0.95, 0.98, 1 },
    slate_050 = { 0.95, 0.96, 0.99, 1 },

    blue_500 = { 0.24, 0.52, 0.84, 1 },
    blue_300 = { 0.46, 0.72, 1, 1 },
    green_500 = { 0.24, 0.72, 0.46, 1 },
    green_300 = { 0.49, 0.92, 0.66, 1 },
    amber_500 = { 0.82, 0.64, 0.19, 1 },
    amber_400 = { 0.96, 0.8, 0.38, 1 },
    red_500 = { 0.8, 0.28, 0.28, 1 },
    red_300 = { 0.98, 0.58, 0.58, 1 },
    violet_500 = { 0.56, 0.37, 0.78, 1 },
    violet_300 = { 0.8, 0.64, 0.98, 1 },
    cyan_500 = { 0.14, 0.7, 0.8, 1 },
    cyan_300 = { 0.42, 0.92, 0.98, 1 },
    gold_400 = { 0.9, 0.78, 0.32, 1 },
}

local function rgba(color, alpha)
    local base_alpha = 1
    if color[4] ~= nil then
        base_alpha = color[4]
    end

    return {
        color[1],
        color[2],
        color[3],
        base_alpha * alpha,
    }
end

local ROLES = {
    -- Keep roles generic. Do not add per-component aliases like "modal_*",
    -- "sidebar_*", or "monitor_*" when an existing surface/text role fits.
    background = NAMES.slate_950,
    background_alt = NAMES.slate_925,
    foreground = NAMES.slate_900,
    foreground_strong = NAMES.slate_850,
    foreground_light = NAMES.slate_800,
    overlay = NAMES.slate_925,
    overlay_soft = NAMES.slate_900,

    heading = NAMES.slate_050,
    body = NAMES.slate_100,
    body_muted = NAMES.slate_500,
    body_subtle = NAMES.slate_400,
    text_inverted = NAMES.black,

    border = NAMES.slate_500,
    border_light = NAMES.slate_750,
    border_strong = NAMES.black,

    surface = NAMES.slate_900,
    surface_alt = NAMES.slate_850,
    surface_alt_soft = NAMES.slate_850,
    surface_emphasis = NAMES.slate_800,
    surface_interactive = NAMES.slate_750,

    text = NAMES.slate_050,
    text_muted = NAMES.slate_500,
    text_subtle = NAMES.slate_400,

    accent_blue_fill = NAMES.blue_300,
    accent_blue_line = NAMES.blue_300,
    accent_green_fill = NAMES.green_300,
    accent_green_line = NAMES.green_300,
    accent_amber_fill = NAMES.amber_400,
    accent_amber_line = NAMES.amber_400,
    accent_red_fill = NAMES.red_300,
    accent_red_line = NAMES.red_300,
    accent_violet_fill = NAMES.violet_300,
    accent_violet_line = NAMES.violet_300,
    accent_cyan_fill = NAMES.cyan_300,
    accent_cyan_line = NAMES.cyan_300,
    accent_highlight = NAMES.gold_400,
}

return {
    names = NAMES,
    roles = ROLES,
    rgba = rgba,
}
