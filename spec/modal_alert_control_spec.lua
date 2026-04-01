local UI = require('lib.ui')

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message .. ': expected ' .. tostring(expected) ..
            ', got ' .. tostring(actual), 2)
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

local function focused(stage)
    return stage:_get_focus_owner_internal()
end

local function run_modal_mount_and_dismissal_tests()
    local stage = UI.Stage.new({ width = 320, height = 180 })
    local launcher = UI.Button.new({
        width = 80,
        height = 32,
    })
    local modal_open = true
    local open_changes = {}
    local modal_button = UI.Button.new({
        tag = 'modal.confirm',
        width = 80,
        height = 32,
    })
    local modal
    modal = UI.Modal.new({
        open = modal_open,
        onOpenChange = function(next_value)
            open_changes[#open_changes + 1] = next_value
            modal_open = next_value
            modal.open = next_value
        end,
        dismissOnBackdrop = false,
        dismissOnEscape = true,
        trapFocus = true,
        restoreFocus = true,
        content = modal_button,
    })

    stage.baseSceneLayer:addChild(launcher)
    stage.baseSceneLayer:addChild(modal)
    stage:_set_focus_owner_internal(launcher)
    stage:update()

    assert_equal(modal.root.parent, stage.overlayLayer,
        'Open modals should mount into the overlay layer')
    assert_equal(focused(stage), modal_button,
        'Open focus-trapped modals should move focus into modal content')

    stage:deliverInput({ kind = 'keypressed', key = 'escape' })
    assert_equal(open_changes[#open_changes], false,
        'Escape dismissal should request onOpenChange(false) when enabled')

    modal.open = true
    modal_open = true
    modal.dismissOnBackdrop = false
    stage:update()

    stage:deliverInput({ kind = 'mousepressed', x = 10, y = 10, button = 1 })
    stage:deliverInput({ kind = 'mousereleased', x = 10, y = 10, button = 1 })

    assert_equal(modal.open, true,
        'Backdrop clicks should not dismiss when dismissOnBackdrop is false')

    modal.dismissOnBackdrop = true
    stage:deliverInput({ kind = 'mousepressed', x = 10, y = 10, button = 1 })
    stage:deliverInput({ kind = 'mousereleased', x = 10, y = 10, button = 1 })

    assert_equal(open_changes[#open_changes], false,
        'Backdrop activation should request close when enabled')

    stage:update()

    assert_equal(modal.root.parent, nil,
        'Closed modals should detach from the overlay layer')
    assert_equal(focused(stage), launcher,
        'Closing a modal with restoreFocus should restore the prior focus owner')

    stage:destroy()
end

local function run_nested_modal_restoration_tests()
    local stage = UI.Stage.new({ width = 360, height = 200 })
    local base = UI.Button.new({
        tag = 'base.launcher',
        width = 80,
        height = 32,
    })
    local inner_button = UI.Button.new({
        tag = 'inner.button',
        width = 80,
        height = 32,
    })
    local inner_open = false
    local inner
    inner = UI.Modal.new({
        open = inner_open,
        onOpenChange = function(next_value)
            inner_open = next_value
            inner.open = next_value
        end,
        content = inner_button,
    })
    local outer_button = UI.Button.new({
        tag = 'outer.button',
        width = 80,
        height = 32,
    })
    local outer_open = true
    local outer_content = UI.Column.new({
        width = 'fill',
        height = 'fill',
        gap = 12,
        align = 'stretch',
        justify = 'start',
    })

    outer_content:addChild(outer_button)
    outer_content:addChild(inner)

    local outer
    outer = UI.Modal.new({
        open = outer_open,
        onOpenChange = function(next_value)
            outer_open = next_value
            outer.open = next_value
        end,
        content = outer_content,
    })

    stage.baseSceneLayer:addChild(base)
    stage.baseSceneLayer:addChild(outer)
    stage:_set_focus_owner_internal(base)
    stage:update()

    assert_equal(focused(stage), outer_button,
        'The first outer modal action should receive focus on open')

    inner.open = true
    stage:update()
    assert_equal(focused(stage), inner_button,
        'Nested modals should transfer focus to the inner overlay scope')

    inner.open = false
    stage:update()

    assert_equal(focused(stage), outer_button,
        'Closing the inner modal should restore focus to the outer modal scope')

    outer.open = false
    stage:update()

    assert_equal(focused(stage), base,
        'Closing the outer modal should restore focus to the base scene')

    stage:destroy()
end

local function run_alert_contract_tests()
    assert_error(function()
        UI.Alert.new({
            title = '',
            actions = {
                UI.Button.new({ width = 80, height = 32 }),
            },
        })
    end, 'Alert title must be a non-empty string or a content node.',
        'Empty alert titles should fail deterministically at construction')

    local stage = UI.Stage.new({ width = 360, height = 220 })
    local primary = UI.Button.new({
        tag = 'delete',
        actionId = 'delete',
        width = 80,
        height = 32,
    })
    local cancel = UI.Button.new({
        tag = 'cancel',
        actionId = 'cancel',
        width = 80,
        height = 32,
    })
    local alert
    alert = UI.Alert.new({
        open = true,
        onOpenChange = function(next_value)
            alert.open = next_value
        end,
        title = 'Delete item?',
        message = 'This action cannot be undone.',
        actions = { primary, cancel },
        initialFocus = 'cancel',
    })

    stage.baseSceneLayer:addChild(alert)
    stage:update()

    assert_equal(focused(stage), cancel,
        'Alert.initialFocus should move focus to the identified action when it exists')

    stage:destroy()

    stage = UI.Stage.new({ width = 360, height = 220 })
    local fallback_primary = UI.Button.new({
        tag = 'fallback.primary',
        actionId = 'primary',
        width = 80,
        height = 32,
    })
    local fallback
    fallback = UI.Alert.new({
        open = true,
        onOpenChange = function(next_value)
            fallback.open = next_value
        end,
        title = 'Fallback',
        actions = { fallback_primary },
        initialFocus = 'missing',
    })

    stage.baseSceneLayer:addChild(fallback)
    stage:update()

    assert_equal(focused(stage), fallback_primary,
        'Missing Alert.initialFocus targets should fall back to the first action')

    stage:destroy()

    stage = UI.Stage.new({ width = 360, height = 220 })
    local invalid
    invalid = UI.Alert.new({
        open = true,
        onOpenChange = function(next_value)
            invalid.open = next_value
        end,
        title = 'Broken',
        actions = UI.Container.new({
            width = 'fill',
            height = 40,
        }),
    })

    stage.baseSceneLayer:addChild(invalid)

    assert_error(function()
        stage:update()
    end, 'Alert requires at least one action node.',
        'Alerts without actions should fail when opened')

    stage:destroy()
end

local M = {}

function M.run()
    run_modal_mount_and_dismissal_tests()
    run_nested_modal_restoration_tests()
    run_alert_contract_tests()
end

return M
