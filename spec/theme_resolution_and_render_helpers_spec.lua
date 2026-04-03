local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function assert_same(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected same reference', 2)
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

local function run_theme_resolution_tests()
    local Theme = UI.Theme
    local Resolver = UI.ThemeResolver

    local theme = Theme.new({
        tokens = {
            ['button.surface.fillColor'] = 'theme-base',
            ['button.surface.fillColor.hovered'] = 'theme-hovered',
            ['button.surface.backgroundColor'] = '#112233',
            ['button.surface.backgroundColor.hovered'] = '#223344',
        },
    })
    local defaults = {
        ['button.surface.fillColor'] = 'default-base',
        ['button.surface.fillColor.hovered'] = 'default-hovered',
        ['button.surface.backgroundColor'] = '#334455',
        ['button.surface.backgroundColor.hovered'] = '#445566',
    }

    assert_equal(Resolver.resolve({
        component = 'button',
        part = 'surface',
        property = 'fillColor',
        variant = 'hovered',
        theme = theme,
        defaults = defaults,
    }), 'theme-hovered',
        'Theme variant tokens should resolve before defaults')

    assert_equal(Resolver.resolve({
        component = 'button',
        part = 'surface',
        property = 'fillColor',
        variant = 'hovered',
        theme = theme,
        defaults = defaults,
        partSkin = {
            surface = {
                fillColor = {
                    hovered = 'skin-hovered',
                },
            },
        },
    }), 'skin-hovered',
        'Part skin overrides should beat active theme tokens')

    assert_equal(Resolver.resolve({
        component = 'button',
        part = 'surface',
        property = 'fillColor',
        variant = 'hovered',
        theme = theme,
        defaults = defaults,
        instanceOverrides = {
            surface = {
                fillColor = {
                    hovered = 'instance-hovered',
                },
            },
        },
    }), 'instance-hovered',
        'Instance overrides should beat part skin and theme tokens')

    assert_equal(Resolver.resolve({
        component = 'button',
        part = 'surface',
        property = 'fillColor',
        variant = 'hovered',
        theme = theme,
        defaults = defaults,
        instanceValue = 'direct-instance',
    }), 'direct-instance',
        'Direct instance-level visual values should have highest precedence')

    assert_error(function()
        Resolver.resolve({
            component = 'button',
            part = 'surface',
            property = 'missing',
            variant = 'base',
            theme = Theme.new({ tokens = {} }),
            defaults = {},
        })
    end, 'missing token',
        'Missing tokens without defaults should fail deterministically')
end

local function run_canvas_pool_tests()
    local created = {}
    local pool = UI.CanvasPool.new({
        graphics = {
            newCanvas = function(width, height)
                local canvas = { width = width, height = height }
                created[#created + 1] = canvas
                return canvas
            end,
        },
    })

    local canvas = pool:acquire(10, 20)

    assert_equal(canvas.width, 64,
        'Canvas pool should bucket widths to the next 64-pixel boundary')
    assert_equal(canvas.height, 64,
        'Canvas pool should bucket heights to the next 64-pixel boundary')

    pool:release(canvas)
    pool:release({ width = 64, height = 64 })

    local reused = pool:acquire(12, 24)

    assert_same(reused, canvas,
        'Released canvases from the same pool should be reused')
end

local function run_nine_slice_tests()
    local NineSlice = UI.NineSlice

    local definition = NineSlice.define({
        x = 0,
        y = 0,
        width = 20,
        height = 20,
        top = 4,
        right = 5,
        bottom = 6,
        left = 3,
    })
    local layout = NineSlice.layout(definition, 6, 20)

    assert_equal(layout.edges.top, nil,
        'Collapsed horizontal space should omit the top edge cell')
    assert_equal(layout.edges.bottom, nil,
        'Collapsed horizontal space should omit the bottom edge cell')
    assert_equal(layout.center, nil,
        'Collapsed horizontal space should omit the center cell')

    assert_error(function()
        NineSlice.define({
            x = 0,
            y = 0,
            width = 10,
            height = 10,
            top = 2,
            right = 8,
            bottom = 2,
            left = 4,
        })
    end, 'horizontal insets exceed source width',
        'Invalid nine-slice definitions should fail at definition time')
end

local function run_variant_priority_tests()
    local button = UI.Button.new({})
    button._hovered = true
    button._focused = true
    assert_equal(button:_resolve_visual_variant(), 'hovered',
        'Button hovered should beat focused')
    button._pressed_uncontrolled = true
    assert_equal(button:_resolve_visual_variant(), 'pressed',
        'Button pressed should beat hovered')
    button.disabled = true
    assert_equal(button:_resolve_visual_variant(), 'disabled',
        'Button disabled should beat all other button states')

    local checkbox = UI.Checkbox.new({})
    checkbox._focused = true
    assert_equal(checkbox:_resolve_visual_variant(), 'focused',
        'Checkbox should fall back to focused when no checked state is active')
    checkbox._checked_uncontrolled = 'checked'
    assert_equal(checkbox:_resolve_visual_variant(), 'checked',
        'Checkbox checked should beat focused')
    checkbox._checked_uncontrolled = 'indeterminate'
    assert_equal(checkbox:_resolve_visual_variant(), 'indeterminate',
        'Checkbox indeterminate should beat checked')

    local switch = UI.Switch.new({})
    switch._focused = true
    assert_equal(switch:_resolve_visual_variant(), 'focused',
        'Switch should fall back to focused when idle')
    switch._checked_uncontrolled = true
    assert_equal(switch:_resolve_visual_variant(), 'checked',
        'Switch checked should beat focused')
    switch._dragging = true
    assert_equal(switch:_resolve_visual_variant(), 'dragging',
        'Switch dragging should beat checked')

    local text_input = UI.TextInput.new({})
    text_input._focused = true
    assert_equal(text_input:_resolve_visual_variant(), 'focused',
        'TextInput focused should be exposed as the active variant')
    text_input._composing = true
    assert_equal(text_input:_resolve_visual_variant(), 'composing',
        'TextInput composing should beat focused')
    text_input.readOnly = true
    assert_equal(text_input:_resolve_visual_variant(), 'readOnly',
        'TextInput readOnly should beat composing')
    text_input.disabled = true
    assert_equal(text_input:_resolve_visual_variant(), 'disabled',
        'TextInput disabled should beat all other states')

    local tabs = UI.Tabs.new({})
    local trigger = UI.Drawable.new({})
    local panel = UI.Container.new({})
    trigger._focused = true
    assert_equal(tabs:_resolve_trigger_variant(trigger), 'focused',
        'Tabs trigger focus should surface the focused variant')
    trigger._tab_active = true
    assert_equal(tabs:_resolve_trigger_variant(trigger), 'active',
        'Tabs trigger active should beat focused')
    trigger._tab_disabled = true
    assert_equal(tabs:_resolve_trigger_variant(trigger), 'disabled',
        'Tabs trigger disabled should beat active')

    assert_equal(tabs:_resolve_panel_variant(panel), 'inactive',
        'Inactive tabs panels should surface the inactive variant')
    panel._tab_active = true
    assert_equal(tabs:_resolve_panel_variant(panel), 'active',
        'Active tabs panels should surface the active variant')
end

local M = {}

function M.run()
    run_theme_resolution_tests()
    run_canvas_pool_tests()
    run_nine_slice_tests()
    run_variant_priority_tests()
end

return M
