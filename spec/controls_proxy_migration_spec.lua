local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual), 2)
    end
end

local function assert_true(value, message)
    if not value then
        error(message, 2)
    end
end

local function capture_error(fn)
    local ok, err = pcall(fn)
    if ok then
        error('expected an error', 2)
    end
    return tostring(err):gsub('^.-:%d+: ', '')
end

local function listener_count(node, event_type, phase)
    local listeners = rawget(node, '_event_listeners') or {}
    local by_phase = listeners[phase or 'bubble'] or {}
    local list = by_phase[event_type]
    return list and #list or 0
end

local function run_slider_constructor_validation_tests()
    assert_equal(capture_error(function()
        UI.Slider.new({ min = 10, max = 10 })
    end), 'Slider.max must be greater than Slider.min',
        'Slider min/max validation should preserve the old error message')

    assert_equal(capture_error(function()
        UI.Slider.new({ step = 0 })
    end), 'Slider.step must be > 0 when provided',
        'Slider step validation should preserve the old error message')
end

local function run_select_registry_validation_tests()
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
    assert_equal(capture_error(function()
        select:update(0)
    end), 'zero registered options within one Select root are invalid',
        'Select should preserve the missing option-set error message')
    rawset(_G, 'love', previous_love)
end

local function run_checkbox_destroy_listener_cleanup_tests()
    local checkbox = UI.Checkbox.new({})
    assert_equal(listener_count(checkbox, 'ui.activate', 'bubble'), 1,
        'Checkbox should register its activate listener during construction')

    checkbox:destroy()

    assert_equal(listener_count(checkbox, 'ui.activate', 'bubble'), 0,
        'Checkbox.destroy should remove its constructor listener')
    assert_true(rawget(checkbox, '_destroyed') == true,
        'Checkbox.destroy should still destroy the control subtree')
end

local function run_tooltip_overlay_mixin_tests()
    local stage = UI.Stage.new({ width = 320, height = 200 })
    local tooltip = UI.Tooltip.new({})
    local overlay_root = rawget(tooltip, '_overlay_root')

    tooltip:_attach_overlay(stage)
    assert_equal(tooltip.surface.parent, overlay_root,
        'Tooltip surface should remain in the overlay root')
    assert_equal(overlay_root.parent, stage.overlayLayer,
        'Tooltip overlay mixin should attach the overlay root to the stage layer')

    tooltip:_detach_overlay()
    assert_equal(overlay_root.parent, nil,
        'Tooltip overlay mixin should detach the overlay root from the stage layer')

    stage:destroy()
end

local M = {}

function M.run()
    run_slider_constructor_validation_tests()
    run_select_registry_validation_tests()
    run_checkbox_destroy_listener_cleanup_tests()
    run_tooltip_overlay_mixin_tests()
end

return M
