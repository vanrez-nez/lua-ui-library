local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_quad(quad, expected, message)
    assert_equal(type(quad), 'table', message .. ': expected a table')

    for key, value in pairs(expected) do
        assert_equal(quad[key], value, message .. ': expected ' .. key)
    end
end

local function assert_error(fn, needle, message)
    local ok, err = pcall(fn)

    if ok then
        error(message .. ': expected an error', 2)
    end

    local text = tostring(err)

    if needle ~= nil and text:find(needle, 1, true) == nil then
        error(message .. ': expected error containing "' .. needle ..
            '", got "' .. text .. '"', 2)
    end
end

local function run_root_and_contextual_resolution_tests()
    local Theme = UI.Theme
    local Styling = require('lib.ui.render.styling')

    local theme = Theme.new({
        tokens = {
            ['button.surface.backgroundColor'] = '#112233',
            ['button.surface.backgroundColor.hovered'] = '#223344',
        },
    })
    local defaults = {
        ['button.surface.backgroundColor'] = '#334455',
        ['button.surface.backgroundColor.hovered'] = '#445566',
    }

    local node = {
        skin = {
            backgroundColor = 'root-skin-background',
        },
    }

    local assembled = Styling.assemble_props(node, {
        component = 'button',
        part = 'surface',
        variant = 'hovered',
        theme = theme,
        defaults = defaults,
        partSkin = {
            surface = {
                backgroundColor = {
                    hovered = '#abcdef',
                },
            },
        },
    })

    assert_equal(assembled.backgroundColor[1], 0xab / 255,
        'Contextual styling assembly should resolve through the theme runtime')
    assert_equal(assembled.backgroundColor[2], 0xcd / 255,
        'Contextual styling assembly should normalize part skin color inputs')
    assert_equal(assembled.backgroundColor[3], 0xef / 255,
        'Contextual styling assembly should produce resolved RGB output')
    assert_equal(assembled.backgroundColor[4], 1,
        'Contextual styling assembly should preserve default alpha for hex inputs')

    local direct_assembled = Styling.assemble_props({
        backgroundColor = { 0.1, 0.2, 0.3, 1 },
        skin = {
            backgroundColor = '#ffffff',
        },
    })

    assert_equal(direct_assembled.backgroundColor[1], 0.1,
        'Direct root styling props should beat flat root skin values')
    assert_equal(direct_assembled.backgroundColor[2], 0.2,
        'Direct root styling props should remain unchanged when already normalized')
    assert_equal(direct_assembled.backgroundColor[3], 0.3,
        'Direct root styling props should continue to drive the resolved styling value')
    assert_equal(direct_assembled.backgroundColor[4], 1,
        'Direct root styling props should preserve alpha')

    local skin_assembled = Styling.assemble_props({
        skin = {
            backgroundColor = '#123456',
        },
    })

    assert_equal(skin_assembled.backgroundColor[1], 0x12 / 255,
        'Flat root skin values should still apply when no explicit resolver context exists')
    assert_equal(skin_assembled.backgroundColor[2], 0x34 / 255,
        'Flat root skin values should be normalized during assembly')
    assert_equal(skin_assembled.backgroundColor[3], 0x56 / 255,
        'Flat root skin values should resolve to RGBA tables')

    local shorthand_assembled = Styling.assemble_props({
        borderWidth = 3,
    })

    assert_quad(shorthand_assembled.borderWidth, {
        top = 3,
        right = 3,
        bottom = 3,
        left = 3,
    }, 'Border shorthand should normalize to a canonical side quad on the resolved props table')
    assert_equal(shorthand_assembled.borderWidthTop, 3,
        'Border shorthand should expand to top width')
    assert_equal(shorthand_assembled.borderWidthRight, 3,
        'Border shorthand should expand to right width')
    assert_equal(shorthand_assembled.borderWidthBottom, 3,
        'Border shorthand should expand to bottom width')
    assert_equal(shorthand_assembled.borderWidthLeft, 3,
        'Border shorthand should expand to left width')

    local mixed_assembled = Styling.assemble_props({
        borderWidth = 4,
        borderWidthLeft = 9,
    })

    assert_equal(mixed_assembled.borderWidthTop, 4,
        'Per-side widths should still inherit from the shorthand when absent')
    assert_equal(mixed_assembled.borderWidthLeft, 9,
        'Per-side widths should override the shorthand for their own side')

    local contextual_shorthand = Styling.assemble_props({}, {
        component = 'button',
        part = 'surface',
        theme = Theme.new({
            tokens = {
                ['button.surface.borderWidth'] = 5,
                ['button.surface.borderWidthRight'] = 7,
            },
        }),
        defaults = {},
    })

    assert_equal(contextual_shorthand.borderWidthTop, 5,
        'Contextual styling should expand token-provided borderWidth shorthand')
    assert_equal(contextual_shorthand.borderWidthRight, 7,
        'Contextual per-side token values should override the shorthand for that side')

    local corner_radius_assembled = Styling.assemble_props({
        cornerRadius = 6,
        cornerRadiusBottomLeft = 9,
    })

    assert_quad(corner_radius_assembled.cornerRadius, {
        topLeft = 6,
        topRight = 6,
        bottomRight = 6,
        bottomLeft = 9,
    }, 'Corner radius shorthand should normalize to a canonical corner quad on the resolved props table')
    assert_equal(corner_radius_assembled.cornerRadiusTopLeft, 6,
        'Corner radius shorthand should expand to the top-left corner')
    assert_equal(corner_radius_assembled.cornerRadiusBottomLeft, 9,
        'Per-corner radius props should override the shorthand for their own corner')

    local contextual_corner_radius = Styling.assemble_props({}, {
        component = 'button',
        part = 'surface',
        theme = Theme.new({
            tokens = {
                ['button.surface.cornerRadius'] = 10,
                ['button.surface.cornerRadiusTopRight'] = 14,
            },
        }),
        defaults = {},
    })

    assert_equal(contextual_corner_radius.cornerRadiusTopLeft, 10,
        'Contextual styling should expand token-provided cornerRadius shorthand')
    assert_equal(contextual_corner_radius.cornerRadiusTopRight, 14,
        'Contextual per-corner token values should override the shorthand for that corner')
end

local function run_coercion_and_failure_tests()
    local Theme = UI.Theme
    local Styling = require('lib.ui.render.styling')

    local coerced_skin = Styling.assemble_props({
        skin = {
            backgroundColor = '#0f0',
        },
    })

    assert_equal(coerced_skin.backgroundColor[1], 0,
        'Skin-provided color inputs should be normalized through Drawable styling validation')
    assert_equal(coerced_skin.backgroundColor[2], 1,
        'Skin-provided color inputs should resolve to RGBA tables')
    assert_equal(coerced_skin.backgroundColor[3], 0,
        'Skin-provided color inputs should preserve the resolved color')
    assert_equal(coerced_skin.backgroundColor[4], 1,
        'Skin-provided color inputs should default alpha to 1 when omitted')

    local coerced_contextual = Styling.assemble_props({}, {
        component = 'button',
        part = 'surface',
        variant = 'hovered',
        theme = Theme.new({
            tokens = {
                ['button.surface.backgroundColor.hovered'] = '#00f',
            },
        }),
        defaults = {},
    })

    assert_equal(coerced_contextual.backgroundColor[1], 0,
        'Theme token styling values should be normalized before reaching the renderer')
    assert_equal(coerced_contextual.backgroundColor[2], 0,
        'Theme token styling normalization should preserve resolved RGB values')
    assert_equal(coerced_contextual.backgroundColor[3], 1,
        'Theme token styling normalization should support hex color input')
    assert_equal(coerced_contextual.backgroundColor[4], 1,
        'Theme token styling normalization should produce RGBA output')

    assert_error(function()
        Styling.assemble_props({
            skin = {
                backgroundColor = 'purple',
            },
        })
    end, "unsupported color string 'purple'",
        'Invalid skin styling values should fail deterministically during assembly')

    assert_error(function()
        Styling.assemble_props({
            skin = {
                shadowBlur = math.huge,
            },
        })
    end, 'shadowBlur must be finite',
        'Infinite styling numeric inputs should fail during assembly')

    assert_error(function()
        Styling.assemble_props({
            skin = {
                backgroundOffsetX = 0 / 0,
            },
        })
    end, 'backgroundOffsetX must be finite',
        'NaN styling numeric inputs should fail during assembly')

    assert_error(function()
        Styling.assemble_props({
            borderWidth = { 1, 2, 3 },
        })
    end, 'borderWidth must be a number, a keyed table, or contain 2 or 4 values',
        'Malformed side-quad styling inputs should fail deterministically during assembly')

    assert_error(function()
        Styling.assemble_props({
            cornerRadius = { 1, 2, 3 },
        })
    end, 'cornerRadius must be a number, a keyed table, or contain 4 values',
        'Malformed corner-quad styling inputs should fail deterministically during assembly')
end

local function run_foundation_quad_read_tests()
    local drawable = UI.Drawable.new({
        width = 120,
        height = 80,
        padding = 12,
        paddingLeft = 3,
        margin = { 5, 8 },
        marginTop = 2,
    })

    drawable:update()

    assert_quad(drawable.padding, {
        top = 12,
        right = 12,
        bottom = 12,
        left = 3,
    }, 'Drawable padding reads should expose merged aggregate-plus-member effective values')
    assert_equal(drawable.paddingLeft, 3,
        'Drawable flat padding member reads should reflect the effective merged side value')
    assert_equal(drawable.paddingTop, 12,
        'Drawable flat padding members should inherit from the aggregate when not overridden')

    assert_quad(drawable.margin, {
        top = 2,
        right = 8,
        bottom = 5,
        left = 8,
    }, 'Drawable margin reads should expose merged aggregate-plus-member effective values')
    assert_equal(drawable.marginTop, 2,
        'Drawable flat margin member reads should reflect their own override')
    assert_equal(drawable.marginLeft, 8,
        'Drawable flat margin members should inherit from the aggregate when not overridden')
end

local M = {}

function M.run()
    run_root_and_contextual_resolution_tests()
    run_coercion_and_failure_tests()
    run_foundation_quad_read_tests()
end

return M
