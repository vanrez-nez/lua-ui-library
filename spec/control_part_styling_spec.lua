local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
    end
end

local function run_part_styling_integration_tests()
    local Styling = require('lib.ui.render.styling')
    local Theme = UI.Theme

    local previous_theme = Theme.get_active()

    local button = UI.Button.new({})
    button._hovered = true
    Theme.set_active(Theme.new({
        tokens = {
            ['button.surface.backgroundColor.hovered'] = '#102030',
        },
    }))
    local button_props = Styling.assemble_props(button, rawget(button, '_styling_context'))
    assert_equal(button_props.backgroundColor[1], 0x10 / 255,
        'Button surface should resolve named-part styling through its contextual part binding')

    local text_input = UI.TextInput.new({})
    text_input._focused = true
    Theme.set_active(Theme.new({
        tokens = {
            ['textInput.field.backgroundColor.focused'] = '#203040',
        },
    }))
    local text_input_props = Styling.assemble_props(text_input, rawget(text_input, '_styling_context'))
    assert_equal(text_input_props.backgroundColor[2], 0x30 / 255,
        'TextInput root should resolve field styling through the documented field part')

    local checkbox = UI.Checkbox.new({})
    checkbox:update(0)
    Theme.set_active(Theme.new({
        tokens = {
            ['checkbox.box.backgroundColor.checked'] = '#abcdef',
            ['checkbox.indicator.backgroundColor.checked'] = '#fedcba',
        },
    }))
    checkbox._checked_uncontrolled = 'checked'
    checkbox:update(0)
    local checkbox_box_props = Styling.assemble_props(checkbox.box, rawget(checkbox.box, '_styling_context'))
    local checkbox_indicator_props = Styling.assemble_props(checkbox.indicator, rawget(checkbox.indicator, '_styling_context'))
    assert_equal(checkbox_box_props.backgroundColor[1], 0xab / 255,
        'Checkbox box should resolve styling through the documented box part')
    assert_equal(checkbox_indicator_props.backgroundColor[1], 0xfe / 255,
        'Checkbox indicator should resolve styling through the documented indicator part')

    local switch_control = UI.Switch.new({})
    switch_control._checked_uncontrolled = true
    switch_control:update(0)
    Theme.set_active(Theme.new({
        tokens = {
            ['switch.track.backgroundColor.checked'] = '#123456',
            ['switch.thumb.backgroundColor.checked'] = '#654321',
        },
    }))
    local switch_track_props = Styling.assemble_props(switch_control.track, rawget(switch_control.track, '_styling_context'))
    local switch_thumb_props = Styling.assemble_props(switch_control.thumb, rawget(switch_control.thumb, '_styling_context'))
    assert_equal(switch_track_props.backgroundColor[1], 0x12 / 255,
        'Switch track should resolve styling through the documented track part')
    assert_equal(switch_thumb_props.backgroundColor[1], 0x65 / 255,
        'Switch thumb should resolve styling through the documented thumb part')

    local radio = UI.Radio.new({ value = 'a' })
    rawset(radio, '_focused', true)
    radio:update(0)
    Theme.set_active(Theme.new({
        tokens = {
            ['radio.indicator.backgroundColor.focused'] = '#456789',
        },
    }))
    local radio_indicator_props = Styling.assemble_props(radio.indicator, rawget(radio.indicator, '_styling_context'))
    assert_equal(radio_indicator_props.backgroundColor[2], 0x67 / 255,
        'Radio indicator should resolve styling through the documented indicator part')

    local progress_bar = UI.ProgressBar.new({})
    progress_bar.indeterminate = true
    progress_bar:update(0)
    Theme.set_active(Theme.new({
        tokens = {
            ['progressBar.track.backgroundColor.indeterminate'] = '#111111',
            ['progressBar.indicator.backgroundColor.indeterminate'] = '#222222',
        },
    }))
    local progress_track_props = Styling.assemble_props(progress_bar.track, rawget(progress_bar.track, '_styling_context'))
    local progress_indicator_props = Styling.assemble_props(progress_bar.indicator, rawget(progress_bar.indicator, '_styling_context'))
    assert_equal(progress_track_props.backgroundColor[1], 0x11 / 255,
        'ProgressBar track should resolve styling through the documented track part')
    assert_equal(progress_indicator_props.backgroundColor[1], 0x22 / 255,
        'ProgressBar indicator should resolve styling through the documented indicator part')

    local slider = UI.Slider.new({})
    rawset(slider, '_focused', true)
    slider:update(0)
    Theme.set_active(Theme.new({
        tokens = {
            ['slider.track.backgroundColor.focused'] = '#345678',
            ['slider.thumb.backgroundColor.focused'] = '#876543',
        },
    }))
    local slider_track_props = Styling.assemble_props(slider.track, rawget(slider.track, '_styling_context'))
    local slider_thumb_props = Styling.assemble_props(slider.thumb, rawget(slider.thumb, '_styling_context'))
    assert_equal(slider_track_props.backgroundColor[1], 0x34 / 255,
        'Slider track should resolve styling through the documented track part')
    assert_equal(slider_thumb_props.backgroundColor[1], 0x87 / 255,
        'Slider thumb should resolve styling through the documented thumb part')

    local previous_love = rawget(_G, 'love')
    rawset(_G, 'love', {
        graphics = {
            newFont = function(size)
                return {
                    getWidth = function(_, text)
                        return #(text or '') * math.max(1, math.floor(size * 0.5))
                    end,
                    getHeight = function()
                        return size
                    end,
                    getWrap = function(_, text, width)
                        return width, { text or '' }
                    end,
                }
            end,
        },
    })

    local select = UI.Select.new({})
    local option_a = UI.Option.new({ value = 'a', label = 'A' })
    select:addChild(option_a)
    rawset(select, '_open_uncontrolled', true)
    select:update(0)
    Theme.set_active(Theme.new({
        tokens = {
            ['select.trigger.backgroundColor.open'] = '#112233',
            ['select.popup.backgroundColor.open'] = '#334455',
        },
    }))
    local select_trigger_props = Styling.assemble_props(select.trigger, rawget(select.trigger, '_styling_context'))
    local select_popup_props = Styling.assemble_props(select.popup, rawget(select.popup, '_styling_context'))
    assert_equal(select_trigger_props.backgroundColor[1], 0x11 / 255,
        'Select trigger should resolve styling through the documented trigger part')
    assert_equal(select_popup_props.backgroundColor[1], 0x33 / 255,
        'Select popup should resolve styling through the documented popup part')
    rawset(_G, 'love', previous_love)

    local tabs = UI.Tabs.new({})
    tabs:_register_tab(
        'home',
        UI.Drawable.new({ width = 10, height = 10 }),
        UI.Container.new({ width = 10, height = 10 })
    )
    tabs:update(0)
    local trigger = rawget(tabs, '_trigger_nodes').home
    local panel = rawget(tabs, '_panel_nodes').home
    Theme.set_active(Theme.new({
        tokens = {
            ['tabs.list.backgroundColor'] = '#203040',
            ['tabs.indicator.backgroundColor'] = '#102030',
            ['tabs.trigger.backgroundColor.active'] = '#304050',
            ['tabs.panel.backgroundColor.active'] = '#405060',
        },
    }))
    local list_props = Styling.assemble_props(tabs.list, rawget(tabs.list, '_styling_context'))
    local indicator_props = Styling.assemble_props(tabs.indicator, rawget(tabs.indicator, '_styling_context'))
    local trigger_props = Styling.assemble_props(trigger, rawget(trigger, '_styling_context'))
    local panel_props = Styling.assemble_props(panel, rawget(panel, '_styling_context'))
    assert_equal(list_props.backgroundColor[1], 0x20 / 255,
        'Tabs list should resolve styling through the documented list part')
    assert_equal(indicator_props.backgroundColor[1], 0x10 / 255,
        'Tabs indicator should resolve styling through the documented indicator part')
    assert_equal(trigger_props.backgroundColor[3], 0x50 / 255,
        'Tabs trigger drawables should resolve trigger part styling with active variants')
    assert_equal(panel_props.backgroundColor[1], 0x40 / 255,
        'Tabs panels should resolve panel part styling through their part binding')

    local modal = UI.Modal.new({})
    Theme.set_active(Theme.new({
        tokens = {
            ['modal.backdrop.backgroundColor'] = '#112244',
            ['modal.surface.backgroundColor'] = '#223355',
        },
    }))
    local backdrop_props = Styling.assemble_props(modal.backdrop, rawget(modal.backdrop, '_styling_context'))
    local modal_surface_props = Styling.assemble_props(modal.surface, rawget(modal.surface, '_styling_context'))
    assert_equal(backdrop_props.backgroundColor[3], 0x44 / 255,
        'Modal backdrop should resolve styling through the backdrop part carrier')
    assert_equal(modal_surface_props.backgroundColor[2], 0x33 / 255,
        'Modal surface should resolve styling through the documented surface part')

    local text_area = UI.TextArea.new({})
    text_area:update(0)
    Theme.set_active(Theme.new({
        tokens = {
            ['textArea.scroll region.backgroundColor'] = '#2468ac',
        },
    }))
    local text_area_scroll_props = Styling.assemble_props(text_area.scrollRegion, rawget(text_area.scrollRegion, '_styling_context'))
    assert_equal(text_area_scroll_props.backgroundColor[1], 0x24 / 255,
        'TextArea scroll region should resolve styling through the documented scroll region part')

    local tooltip = UI.Tooltip.new({})
    Theme.set_active(Theme.new({
        tokens = {
            ['tooltip.surface.backgroundColor'] = '#556677',
        },
    }))
    local tooltip_props = Styling.assemble_props(tooltip.surface, rawget(tooltip.surface, '_styling_context'))
    assert_equal(tooltip_props.backgroundColor[1], 0x55 / 255,
        'Tooltip surface should resolve styling through the surface part carrier')

    local notification = UI.Notification.new({})
    Theme.set_active(Theme.new({
        tokens = {
            ['notification.surface.backgroundColor'] = '#778899',
        },
    }))
    local notification_props = Styling.assemble_props(notification.surface, rawget(notification.surface, '_styling_context'))
    assert_equal(notification_props.backgroundColor[2], 0x88 / 255,
        'Notification surface should resolve styling through the surface part carrier')

    Theme.set_active(nil)

    local default_progress = UI.ProgressBar.new({})
    default_progress:update(0)
    local default_progress_track_props = Styling.assemble_props(default_progress.track, rawget(default_progress.track, '_styling_context'))
    assert_equal(default_progress_track_props.backgroundColor[1], 0.11,
        'Documented styling-property names should resolve through library default tokens when no theme is active')

    Theme.set_active(previous_theme)
end

local M = {}

function M.run()
    run_part_styling_integration_tests()
end

return M
