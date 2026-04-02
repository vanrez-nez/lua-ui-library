package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')

local Stage = UI.Stage
local Container = UI.Container
local Column = UI.Column
local Row = UI.Row
local Flow = UI.Flow
local Text = UI.Text
local Button = UI.Button
local Modal = UI.Modal
local Alert = UI.Alert

local FONT_PATH = 'assets/fonts/DynaPuff-Regular.ttf'

local BG = { 0.07, 0.075, 0.09, 1 }
local PANEL = { 0.12, 0.13, 0.17, 1 }
local PANEL_ALT = { 0.16, 0.17, 0.22, 1 }
local BORDER = { 0.35, 0.38, 0.46, 1 }
local FG = { 0.95, 0.96, 1, 1 }
local SUB = { 0.66, 0.7, 0.78, 1 }
local ACCENT = { 0.18, 0.64, 0.95, 1 }
local SUCCESS = { 0.24, 0.76, 0.49, 1 }
local WARNING = { 0.96, 0.74, 0.25, 1 }
local DANGER = { 0.92, 0.35, 0.33, 1 }
local BACKDROP = { 0.02, 0.03, 0.05, 0.78 }

local stage
local active = 1
local current_screen

local screen_names = {
    'Modal Open/Close',
    'Focus Trap',
    'Alert',
    'Stacked Overlays',
    'Percentage Sizing',
    'Breakpoint Responsive',
}

local function add_log(state, message)
    local log = state.log or {}
    log[#log + 1] = message

    while #log > 12 do
        table.remove(log, 1)
    end

    state.log = log
end

local function focus_label(node)
    if node == nil then
        return 'none'
    end

    return node.tag or tostring(node)
end

local function watch_focus(state)
    if stage == nil or rawget(stage, '_destroyed') then
        return
    end

    local focus = rawget(stage, '_focus_owner')
    local label = focus_label(focus)

    if state.last_focus_label ~= label then
        state.last_focus_label = label
        add_log(state, 'focus -> ' .. label)
    end
end

local function sync_log_text(state)
    local log_text = state.log_text

    if log_text == nil then
        return
    end

    local lines = state.log or {}
    local joined = #lines > 0 and table.concat(lines, '\n') or 'No events yet.'
    log_text:setText(joined)
end

local function styled_text(text, size, color, opts)
    opts = opts or {}

    return Text.new({
        tag = opts.tag,
        text = text,
        font = FONT_PATH,
        fontSize = size or 18,
        color = color or FG,
        width = opts.width or 'fill',
        wrap = opts.wrap == true,
        maxWidth = opts.maxWidth,
        textAlign = opts.textAlign or 'start',
        textVariant = opts.textVariant,
    })
end

local function centered_fill(node)
    local wrapper = Column.new({
        width = 'fill',
        height = 'fill',
        align = 'stretch',
        justify = 'center',
    })

    if node ~= nil then
        wrapper:addChild(node)
    end

    return wrapper
end

local function button_content(label)
    return centered_fill(styled_text(label, 18, FG, {
        textAlign = 'center',
    }))
end

local function new_button(label, opts)
    opts = opts or {}

    return Button.new({
        tag = opts.tag,
        width = opts.width or 220,
        height = opts.height or 56,
        disabled = opts.disabled == true,
        onActivate = opts.onActivate,
        content = button_content(label),
    })
end

local function panel(tag, opts)
    opts = opts or {}

    return Column.new({
        tag = tag,
        width = opts.width or 'fill',
        height = opts.height or 'content',
        gap = opts.gap or 12,
        padding = opts.padding or { 18, 18, 18, 18 },
        align = opts.align or 'stretch',
        justify = opts.justify or 'start',
    })
end

local function screen_root(title, subtitle)
    local root = Column.new({
        tag = 'phase9.root',
        width = 'fill',
        height = 'fill',
        gap = 16,
        padding = { 28, 28, 28, 28 },
        align = 'stretch',
        justify = 'start',
    })

    root:addChild(styled_text(title, 32, FG, {
        tag = 'phase9.header',
        textAlign = 'center',
    }))
    root:addChild(styled_text(subtitle, 16, SUB, {
        tag = 'phase9.subheader',
        textAlign = 'center',
        wrap = true,
        maxWidth = 1200,
    }))

    return root
end

local function log_panel(state, title)
    local container = panel('phase9.log', {
        width = 360,
        height = 'fill',
        gap = 10,
    })

    container:addChild(styled_text(title, 20, FG, {
        textAlign = 'center',
    }))

    local text = styled_text('No events yet.', 14, SUB, {
        tag = 'phase9.log_text',
        wrap = true,
        maxWidth = 320,
        width = 'fill',
    })
    container:addChild(text)
    state.log_text = text

    return container
end

local function percentage_card(label, width_value, min_width, max_width)
    local card = panel('phase9.metric_card', {
        width = width_value,
        height = 90,
        gap = 8,
        padding = { 14, 14, 14, 14 },
    })

    if min_width ~= nil then
        card.minWidth = min_width
    end

    if max_width ~= nil then
        card.maxWidth = max_width
    end

    local label_text = styled_text(label, 18, FG, {
        textAlign = 'center',
    })
    local value_text = styled_text('0 px', 15, SUB, {
        textAlign = 'center',
    })

    card:addChild(label_text)
    card:addChild(value_text)

    return {
        node = card,
        value_text = value_text,
        label = label,
    }
end

local function update_percentage_cards(state)
    for index = 1, #state.cards do
        local item = state.cards[index]
        local width = item.node:getLocalBounds().width
        item.value_text:setText(string.format('%s = %d px', item.label, math.floor(width + 0.5)))
    end

    if state.nested_parent ~= nil and state.nested_child ~= nil and state.nested_text ~= nil then
        local parent_width = state.nested_parent:getLocalBounds().width
        local child_width = state.nested_child:getLocalBounds().width
        state.nested_text:setText(
            string.format(
                'Nested: parent 60%% = %d px, child 50%% of parent = %d px',
                math.floor(parent_width + 0.5),
                math.floor(child_width + 0.5)
            )
        )
    end
end

local function current_breakpoint(width)
    if width < 600 then
        return 'small'
    end

    if width <= 900 then
        return 'medium'
    end

    return 'large'
end

local function draw_node(graphics, node)
    local ev = rawget(node, '_effective_values')

    if ev ~= nil and ev.visible == false then
        return
    end

    local bounds = rawget(node, '_world_bounds_cache')

    if bounds == nil then
        return
    end

    if rawget(node, '_ui_text_control') then
        node:_draw_control(graphics)
        return
    end

    if rawget(node, '_ui_button_control') then
        local variant = node:_resolve_visual_variant()
        local fill = PANEL_ALT

        if variant == 'hovered' then
            fill = { 0.2, 0.54, 0.83, 1 }
        elseif variant == 'pressed' then
            fill = { 0.14, 0.45, 0.7, 1 }
        elseif variant == 'focused' then
            fill = { 0.18, 0.5, 0.77, 1 }
        elseif variant == 'disabled' then
            fill = { 0.19, 0.2, 0.23, 1 }
        else
            fill = ACCENT
        end

        graphics.setColor(fill)
        graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
        graphics.setColor(BORDER)
        graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
        return
    end

    local tag = node.tag

    if tag == 'phase9.panel' or tag == 'phase9.log' or tag == 'phase9.metric_card' or
        tag == 'phase9.item_card' or tag == 'phase9.footer_strip' then
        graphics.setColor(PANEL)
        graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 12, 12)
        graphics.setColor(BORDER)
        graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 12, 12)
        return
    end

    if tag == 'phase9.warning' then
        graphics.setColor({ 0.42, 0.16, 0.16, 1 })
        graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 12, 12)
        graphics.setColor(DANGER)
        graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 12, 12)
        return
    end

    if tag ~= nil and tag:find('modal.backdrop', 1, true) ~= nil then
        graphics.setColor(BACKDROP)
        graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height)
        return
    end

    if tag ~= nil and (tag:find('modal.surface', 1, true) ~= nil or tag == 'alert.body') then
        graphics.setColor(PANEL)
        graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 16, 16)
        graphics.setColor(BORDER)
        graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 16, 16)
        return
    end

    if tag == 'alert.actions' then
        graphics.setColor(PANEL_ALT)
        graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 12, 12)
        graphics.setColor(BORDER)
        graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 12, 12)
        return
    end
end

local function build_modal_open_screen()
    local state = {
        log = {},
    }
    local root = screen_root(
        'Modal Open/Close',
        'Open a modal, confirm or cancel, and verify that Escape closes it and focus returns to the base trigger.'
    )

    local body = Row.new({
        width = 'fill',
        height = 'fill',
        gap = 18,
        align = 'stretch',
        justify = 'start',
    })
    local main = panel('phase9.panel', {
        width = 'fill',
        height = 'fill',
        gap = 18,
        align = 'center',
        justify = 'center',
    })

    local open_button
    open_button = new_button('Open Modal', {
        tag = 'phase9.modal_open_button',
        onActivate = function()
            add_log(state, 'open requested')
            state.modal.open = true
        end,
    })

    main:addChild(open_button)
    main:addChild(styled_text('Tab moves focus between the modal actions. Escape closes the modal.', 15, SUB, {
        wrap = true,
        maxWidth = 520,
        textAlign = 'center',
    }))

    body:addChild(main)
    body:addChild(log_panel(state, 'Event Log'))
    root:addChild(body)

    local confirm_button = new_button('Confirm', {
        tag = 'phase9.modal_confirm',
        width = 180,
        onActivate = function()
            add_log(state, 'confirmed')
            state.modal.open = false
        end,
    })
    local cancel_button = new_button('Cancel', {
        tag = 'phase9.modal_cancel',
        width = 180,
        onActivate = function()
            add_log(state, 'cancelled')
            state.modal.open = false
        end,
    })

    local content = panel('modal.surface.content', {
        width = 'fill',
        height = 'fill',
        gap = 16,
        align = 'stretch',
        justify = 'start',
        padding = { 22, 22, 22, 22 },
    })
    local actions = Row.new({
        width = 'fill',
        height = 64,
        gap = 12,
        align = 'center',
        justify = 'center',
    })

    content:addChild(styled_text('Confirm action', 24, FG, {
        textAlign = 'center',
    }))
    content:addChild(styled_text('Are you sure you want to proceed?', 17, SUB, {
        textAlign = 'center',
        wrap = true,
        maxWidth = 520,
    }))
    actions:addChild(confirm_button)
    actions:addChild(cancel_button)
    content:addChild(actions)

    local modal
    modal = Modal.new({
        open = false,
        onOpenChange = function(next_value)
            add_log(state, 'onOpenChange(' .. tostring(next_value) .. ')')
            modal.open = next_value
        end,
        dismissOnBackdrop = true,
        dismissOnEscape = true,
        trapFocus = true,
        restoreFocus = true,
        safeAreaAware = true,
        backdropDismissBehavior = 'close',
        content = content,
    })
    root:addChild(modal)

    state.root = root
    state.modal = modal
    state.is_overlay_open = function()
        return modal:isOpen()
    end
    state.update = function()
        watch_focus(state)
        sync_log_text(state)
    end

    return state
end

local function build_focus_trap_screen()
    local state = {
        log = {},
        leaked = false,
    }
    local root = screen_root(
        'Focus Trap',
        'While the modal is open, focus traversal and pointer input must stay inside the overlay. Press B to toggle backdrop dismissal.'
    )

    local body = Row.new({
        width = 'fill',
        height = 'fill',
        gap = 18,
        align = 'stretch',
        justify = 'start',
    })
    local left = panel('phase9.panel', {
        width = 'fill',
        height = 'fill',
        gap = 16,
        align = 'center',
        justify = 'start',
    })

    local warning_box = panel('phase9.warning', {
        width = 'fill',
        height = 68,
        gap = 6,
        align = 'center',
        justify = 'center',
    })
    local warning_text = styled_text('No focus leaks detected.', 16, FG, {
        textAlign = 'center',
        wrap = true,
        maxWidth = 560,
    })
    warning_box:addChild(warning_text)

    local status_text = styled_text('Backdrop dismiss: ON', 16, SUB, {
        textAlign = 'center',
    })

    local base_row = Row.new({
        width = 'fill',
        height = 'content',
        gap = 12,
        align = 'center',
        justify = 'center',
    })

    local open_button
    open_button = new_button('Open Trap Modal', {
        tag = 'phase9.trap_open',
        width = 220,
        onActivate = function()
            add_log(state, 'trap modal opened')
            state.modal.open = true
        end,
    })

    local base_a = new_button('Base A', { tag = 'phase9.base_a', width = 140 })
    local base_b = new_button('Base B', { tag = 'phase9.base_b', width = 140 })
    local base_c = new_button('Base C', { tag = 'phase9.base_c', width = 140 })

    base_row:addChild(base_a)
    base_row:addChild(base_b)
    base_row:addChild(base_c)

    left:addChild(open_button)
    left:addChild(status_text)
    left:addChild(base_row)
    left:addChild(warning_box)
    body:addChild(left)
    body:addChild(log_panel(state, 'Focus Log'))
    root:addChild(body)

    local inner_a = new_button('Action One', {
        tag = 'phase9.trap_action_one',
        width = 180,
    })
    local inner_b = new_button('Action Two', {
        tag = 'phase9.trap_action_two',
        width = 180,
        onActivate = function()
            add_log(state, 'trap action two')
        end,
    })
    local close_button = new_button('Close', {
        tag = 'phase9.trap_close',
        width = 180,
        onActivate = function()
            state.modal.open = false
        end,
    })

    local content = panel('modal.surface.content', {
        width = 'fill',
        height = 'fill',
        gap = 14,
        align = 'center',
        justify = 'center',
    })
    content:addChild(styled_text('Focus stays trapped here.', 24, FG, {
        textAlign = 'center',
    }))
    content:addChild(styled_text('Clicking the backdrop closes the modal only when dismissal is enabled.', 16, SUB, {
        wrap = true,
        maxWidth = 520,
        textAlign = 'center',
    }))
    content:addChild(inner_a)
    content:addChild(inner_b)
    content:addChild(close_button)

    local modal
    modal = Modal.new({
        open = false,
        onOpenChange = function(next_value)
            add_log(state, 'onOpenChange(' .. tostring(next_value) .. ')')
            modal.open = next_value
        end,
        dismissOnBackdrop = true,
        dismissOnEscape = true,
        trapFocus = true,
        restoreFocus = true,
        backdropDismissBehavior = 'close',
        content = content,
    })
    root:addChild(modal)

    state.root = root
    state.modal = modal
    state.warning_text = warning_text
    state.status_text = status_text
    state.toggle_backdrop = function()
        state.backdrop_enabled = not state.backdrop_enabled
        modal.dismissOnBackdrop = state.backdrop_enabled
        modal.backdropDismissBehavior = state.backdrop_enabled and 'close' or 'ignore'
    end
    state.backdrop_enabled = true
    state.is_overlay_open = function()
        return modal:isOpen()
    end
    state.update = function()
        watch_focus(state)
        sync_log_text(state)
        status_text:setText('Backdrop dismiss: ' .. (state.backdrop_enabled and 'ON' or 'OFF') .. '  [B]')

        local focus = rawget(stage, '_focus_owner')
        local tag = focus and focus.tag or ''

        if modal:isOpen() and (tag == 'phase9.base_a' or tag == 'phase9.base_b' or tag == 'phase9.base_c' or tag == 'phase9.trap_open') then
            state.leaked = true
        end

        if state.leaked then
            warning_text:setText('Focus leaked to base-scene content while the modal was open.')
        else
            warning_text:setText('No focus leaks detected.')
        end
    end

    return state
end

local function build_alert_screen()
    local state = {
        log = {},
        no_close = false,
    }
    local root = screen_root(
        'Alert',
        'Open the alert, verify that initial focus lands on Delete, and press N to toggle the non-closing configuration.'
    )

    local body = Row.new({
        width = 'fill',
        height = 'fill',
        gap = 18,
        align = 'stretch',
        justify = 'start',
    })
    local left = panel('phase9.panel', {
        width = 'fill',
        height = 'fill',
        gap = 16,
        align = 'center',
        justify = 'center',
    })

    local status_text = styled_text('No-close alert: OFF [N]', 16, SUB, {
        textAlign = 'center',
    })

    local open_button = new_button('Delete Item', {
        tag = 'phase9.alert_open',
        width = 240,
        onActivate = function()
            add_log(state, 'alert opened')
            state.alert.open = true
        end,
    })

    left:addChild(open_button)
    left:addChild(status_text)
    body:addChild(left)
    body:addChild(log_panel(state, 'Alert Log'))
    root:addChild(body)

    local delete_button = new_button('Delete', {
        tag = 'phase9.alert_delete',
        width = 170,
        onActivate = function()
            add_log(state, 'deleted')
            state.alert.open = false
        end,
    })
    delete_button.actionId = 'delete'

    local cancel_button = new_button('Cancel', {
        tag = 'phase9.alert_cancel',
        width = 170,
        onActivate = function()
            add_log(state, 'cancelled')
            state.alert.open = false
        end,
    })
    cancel_button.actionId = 'cancel'

    local alert
    alert = Alert.new({
        open = false,
        onOpenChange = function(next_value)
            add_log(state, 'onOpenChange(' .. tostring(next_value) .. ')')
            alert.open = next_value
        end,
        title = 'Delete item?',
        message = 'This action cannot be undone.',
        actions = { delete_button, cancel_button },
        initialFocus = 'delete',
        dismissOnBackdrop = true,
        dismissOnEscape = true,
        backdropDismissBehavior = 'close',
    })
    root:addChild(alert)

    state.root = root
    state.alert = alert
    state.status_text = status_text
    state.is_overlay_open = function()
        return alert:isOpen()
    end
    state.toggle_no_close = function()
        state.no_close = not state.no_close
        alert.dismissOnBackdrop = not state.no_close
        alert.dismissOnEscape = not state.no_close
        alert.backdropDismissBehavior = state.no_close and 'ignore' or 'close'
    end
    state.update = function()
        watch_focus(state)
        sync_log_text(state)
        status_text:setText('No-close alert: ' .. (state.no_close and 'ON' or 'OFF') .. ' [N]')
    end

    return state
end

local function build_stacked_overlay_screen()
    local state = {
        log = {},
    }
    local root = screen_root(
        'Stacked Overlays',
        'Open Modal A, then Modal B from inside it, and verify the focus restoration chain when the nested overlays close.'
    )

    local body = Row.new({
        width = 'fill',
        height = 'fill',
        gap = 18,
        align = 'stretch',
        justify = 'start',
    })
    local left = panel('phase9.panel', {
        width = 'fill',
        height = 'fill',
        gap = 18,
        align = 'center',
        justify = 'center',
    })

    local base_open = new_button('Open Modal A', {
        tag = 'phase9.stack_open_outer',
        width = 240,
        onActivate = function()
            add_log(state, 'outer modal opened')
            state.outer.open = true
        end,
    })

    left:addChild(base_open)
    left:addChild(styled_text('With Modal B open, only the inner modal should be reachable.', 15, SUB, {
        wrap = true,
        maxWidth = 520,
        textAlign = 'center',
    }))
    body:addChild(left)
    body:addChild(log_panel(state, 'Focus Chain'))
    root:addChild(body)

    local inner_close = new_button('Close Modal B', {
        tag = 'phase9.stack_close_inner',
        width = 180,
        onActivate = function()
            add_log(state, 'inner modal closed')
            state.inner.open = false
        end,
    })

    local inner_content = panel('modal.surface.content', {
        width = 'fill',
        height = 'fill',
        gap = 14,
        align = 'center',
        justify = 'center',
    })
    inner_content:addChild(styled_text('Modal B', 24, FG, {
        textAlign = 'center',
    }))
    inner_content:addChild(styled_text('Focus should remain here until Modal B closes.', 16, SUB, {
        wrap = true,
        maxWidth = 420,
        textAlign = 'center',
    }))
    inner_content:addChild(inner_close)

    local inner
    inner = Modal.new({
        open = false,
        onOpenChange = function(next_value)
            add_log(state, 'inner onOpenChange(' .. tostring(next_value) .. ')')
            inner.open = next_value
        end,
        content = inner_content,
        dismissOnBackdrop = true,
        dismissOnEscape = true,
        trapFocus = true,
        restoreFocus = true,
        backdropDismissBehavior = 'close',
    })

    local open_inner = new_button('Open Modal B', {
        tag = 'phase9.stack_open_inner',
        width = 180,
        onActivate = function()
            add_log(state, 'inner modal opened')
            state.inner.open = true
        end,
    })
    local outer_close = new_button('Close Modal A', {
        tag = 'phase9.stack_close_outer',
        width = 180,
        onActivate = function()
            add_log(state, 'outer modal closed')
            state.outer.open = false
        end,
    })

    local outer_content = panel('modal.surface.content', {
        width = 'fill',
        height = 'fill',
        gap = 14,
        align = 'center',
        justify = 'center',
    })
    outer_content:addChild(styled_text('Modal A', 24, FG, {
        textAlign = 'center',
    }))
    outer_content:addChild(open_inner)
    outer_content:addChild(outer_close)
    outer_content:addChild(inner)

    local outer
    outer = Modal.new({
        open = false,
        onOpenChange = function(next_value)
            add_log(state, 'outer onOpenChange(' .. tostring(next_value) .. ')')
            outer.open = next_value
        end,
        content = outer_content,
        dismissOnBackdrop = true,
        dismissOnEscape = true,
        trapFocus = true,
        restoreFocus = true,
        backdropDismissBehavior = 'close',
    })
    root:addChild(outer)

    state.root = root
    state.outer = outer
    state.inner = inner
    state.is_overlay_open = function()
        return outer:isOpen() or inner:isOpen()
    end
    state.update = function()
        watch_focus(state)
        sync_log_text(state)
    end

    return state
end

local function build_percentage_screen()
    local state = {
        cards = {},
    }
    local root = screen_root(
        'Percentage Sizing',
        'Resize the window to verify percentage sizing and min/max clamp behavior against the effective parent region.'
    )

    local content = panel('phase9.panel', {
        width = 'fill',
        height = 'fill',
        gap = 14,
        align = 'center',
        justify = 'start',
    })

    local card_a = percentage_card('25%', '25%')
    local card_b = percentage_card('50%', '50%')
    local card_c = percentage_card('75%', '75%')
    local card_d = percentage_card('100%', '100%')
    local card_e = percentage_card('50% clamp 120..400', '50%', 120, 400)
    local nested_host = panel('phase9.metric_card', {
        width = '100%',
        height = 150,
        gap = 10,
        padding = { 14, 14, 14, 14 },
        align = 'center',
        justify = 'center',
    })
    local nested_parent = panel('phase9.item_card', {
        width = '60%',
        height = 78,
        gap = 6,
        padding = { 10, 10, 10, 10 },
        align = 'center',
        justify = 'center',
    })
    local nested_child = panel('phase9.metric_card', {
        width = '50%',
        height = 36,
        gap = 0,
        padding = { 0, 0, 0, 0 },
        align = 'center',
        justify = 'center',
    })
    local nested_text = styled_text('Nested: measuring...', 14, SUB, {
        textAlign = 'center',
        wrap = true,
        maxWidth = 900,
    })

    nested_child:addChild(styled_text('50% child', 14, FG, {
        textAlign = 'center',
    }))
    nested_parent:addChild(styled_text('60% parent', 16, FG, {
        textAlign = 'center',
    }))
    nested_parent:addChild(nested_child)
    nested_host:addChild(styled_text('One-level nested percentage demo', 18, FG, {
        textAlign = 'center',
    }))
    nested_host:addChild(nested_parent)
    nested_host:addChild(nested_text)

    state.cards = { card_a, card_b, card_c, card_d, card_e }
    state.nested_parent = nested_parent
    state.nested_child = nested_child
    state.nested_text = nested_text

    for index = 1, #state.cards do
        content:addChild(state.cards[index].node)
    end

    content:addChild(nested_host)

    root:addChild(content)

    state.root = root
    state.is_overlay_open = function()
        return false
    end
    state.update = function()
        update_percentage_cards(state)
    end

    return state
end

local function build_breakpoint_screen()
    local state = {
        last_breakpoint = nil,
        change_count = 0,
    }
    local root = screen_root(
        'Breakpoint Responsive',
        'Resize across small, medium, and large widths. The grid items use declarative responsive rules; the footer shows the active state.'
    )

    local content = panel('phase9.panel', {
        width = 'fill',
        height = 'fill',
        gap = 14,
        align = 'stretch',
        justify = 'start',
    })
    local flow = Flow.new({
        tag = 'phase9.flow',
        width = 'fill',
        height = 'fill',
        gap = 12,
        wrap = true,
        align = 'start',
        justify = 'start',
    })

    for index = 1, 6 do
        local item = panel('phase9.item_card', {
            width = '100%',
            height = 116,
            gap = 8,
            align = 'center',
            justify = 'center',
            padding = { 14, 14, 14, 14 },
        })
        item.responsive = {
            small = {
                maxWidth = 599,
                props = {
                    width = '100%',
                },
            },
            medium = {
                minWidth = 600,
                maxWidth = 900,
                props = {
                    width = '48%',
                },
            },
            large = {
                minWidth = 901,
                props = {
                    width = '31%',
                },
            },
        }
        item:addChild(styled_text('Item ' .. tostring(index), 22, FG, {
            textAlign = 'center',
        }))
        item:addChild(styled_text('Responsive width', 15, SUB, {
            textAlign = 'center',
        }))
        flow:addChild(item)
    end

    local footer = panel('phase9.footer_strip', {
        width = 'fill',
        height = 70,
        gap = 6,
        align = 'center',
        justify = 'center',
    })
    local footer_text = styled_text('', 15, SUB, {
        textAlign = 'center',
        wrap = true,
        maxWidth = 1120,
    })

    footer:addChild(footer_text)
    content:addChild(flow)
    content:addChild(footer)
    root:addChild(content)

    state.root = root
    state.footer_text = footer_text
    state.is_overlay_open = function()
        return false
    end
    state.update = function()
        local viewport = stage:getViewport()
        local breakpoint = current_breakpoint(viewport.width)

        if state.last_breakpoint ~= breakpoint then
            state.last_breakpoint = breakpoint
            state.change_count = state.change_count + 1
        end

        local orientation = viewport.width >= viewport.height and 'landscape' or 'portrait'
        footer_text:setText(
            'breakpoint = ' .. breakpoint ..
            '   viewport = ' .. tostring(math.floor(viewport.width)) .. 'x' .. tostring(math.floor(viewport.height)) ..
            '   orientation = ' .. orientation ..
            '   transitions = ' .. tostring(state.change_count - 1) ..
            '   rules here are viewport-driven for visibility; the responsive runtime also supports parent, orientation, and safe-area inputs.'
        )
    end

    return state
end

local builders = {
    build_modal_open_screen,
    build_focus_trap_screen,
    build_alert_screen,
    build_stacked_overlay_screen,
    build_percentage_screen,
    build_breakpoint_screen,
}

local function build_screen()
    if stage ~= nil and not rawget(stage, '_destroyed') then
        stage:destroy()
    end

    local width, height = love.graphics.getDimensions()
    stage = Stage.new({
        width = width,
        height = height,
    })
    current_screen = builders[active]()
    stage.baseSceneLayer:addChild(current_screen.root)
    stage:update(0)
end

local function deliver_key_to_stage(key)
    if stage ~= nil and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'keypressed', key = key })
    end
end

local function overlay_open()
    return current_screen ~= nil and current_screen.is_overlay_open ~= nil and current_screen.is_overlay_open()
end

function love.load()
    love.graphics.setBackgroundColor(BG)
    build_screen()
end

function love.update(dt)
    if stage == nil or rawget(stage, '_destroyed') then
        return
    end

    stage:update(dt)

    if current_screen ~= nil and current_screen.update ~= nil then
        current_screen.update(dt)
    end
end

function love.draw()
    if stage == nil or rawget(stage, '_destroyed') then
        return
    end

    if not rawget(stage, '_update_ran') then
        stage:update(0)
    end

    local graphics = love.graphics
    local width, height = graphics.getDimensions()

    stage:draw(graphics, function(node)
        draw_node(graphics, node)
    end)

    graphics.setColor(FG)
    graphics.printf('[' .. tostring(active) .. '/' .. tostring(#screen_names) .. '] ' .. screen_names[active], 0, 8, width, 'center')
    graphics.setColor(SUB)
    graphics.printf('Left/Right switch screens when no overlay is open. Q quits. Screen 2: B toggles backdrop dismissal. Screen 3: N toggles no-close alert.', 0, height - 24, width, 'center')
end

function love.keypressed(key)
    if key == 'q' then
        love.event.quit()
        return
    end

    if key == 'right' and not overlay_open() then
        active = (active % #screen_names) + 1
        build_screen()
        return
    end

    if key == 'left' and not overlay_open() then
        active = ((active - 2) % #screen_names) + 1
        build_screen()
        return
    end

    if active == 2 and current_screen ~= nil and key == 'b' then
        current_screen.toggle_backdrop()
        return
    end

    if active == 3 and current_screen ~= nil and key == 'n' then
        current_screen.toggle_no_close()
        return
    end

    deliver_key_to_stage(key)
end

function love.mousepressed(x, y, button)
    if stage ~= nil and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'mousepressed', x = x, y = y, button = button })
    end
end

function love.mousereleased(x, y, button)
    if stage ~= nil and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'mousereleased', x = x, y = y, button = button })
    end
end

function love.mousemoved(x, y, dx, dy)
    if stage ~= nil and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'mousemoved', x = x, y = y, dx = dx, dy = dy })
    end
end

function love.wheelmoved(x, y)
    if stage ~= nil and not rawget(stage, '_destroyed') then
        local mouse_x, mouse_y = love.mouse.getPosition()
        stage:deliverInput({
            kind = 'wheelmoved',
            x = x,
            y = y,
            stageX = mouse_x,
            stageY = mouse_y,
        })
    end
end

function love.textinput(text)
    if stage ~= nil and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'textinput', text = text })
    end
end

function love.textedited(text, start, length)
    if stage ~= nil and not rawget(stage, '_destroyed') then
        stage:deliverInput({
            kind = 'textedited',
            text = text,
            start = start,
            length = length,
        })
    end
end

function love.resize(width, height)
    if stage ~= nil and not rawget(stage, '_destroyed') then
        stage:resize(width, height)
    end
end
