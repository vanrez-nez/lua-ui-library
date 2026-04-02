package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')
local Stage = UI.Stage
local Container = UI.Container
local Drawable = UI.Drawable
local Column = UI.Column
local Row = UI.Row
local Text = UI.Text
local Button = UI.Button
local Checkbox = UI.Checkbox
local Switch = UI.Switch
local TextInput = UI.TextInput
local TextArea = UI.TextArea
local Tabs = UI.Tabs

local FONT_PATH = 'assets/fonts/DynaPuff-Regular.ttf'

local BG = { 0.08, 0.08, 0.1, 1 }
local BORDER = { 0.35, 0.38, 0.46, 1 }
local FG = { 0.95, 0.96, 1, 1 }
local SUB = { 0.66, 0.7, 0.78, 1 }
local ACCENT = { 0.2, 0.66, 0.95, 1 }

local stage
local active = 1
local names = {
    'Text',
    'Button',
    'Checkbox/Switch',
    'TextInput',
    'TextArea',
    'Tabs',
}

local demo_state = {
    buttons = { a = 0, b = 0 },
    controlled_tick = 0,
    controlled_value = false,
    input_log = '',
    tabs_value = 'home',
    tabs_disabled = {},
}

local function styled_text(s, size, variant)
    return Text.new({
        text = s,
        font = FONT_PATH,
        fontSize = size or 18,
        color = FG,
        textVariant = variant,
    })
end

local function screen_root(opts)
    opts = opts or {}
    return Column.new({
        width = 'fill',
        height = 'fill',
        gap = opts.gap or 16,
        padding = opts.padding or { 24, 24, 24, 24 },
        align = 'center',
        justify = opts.justify or 'center',
    })
end

local function panel_box(width, height, tag)
    return Column.new({
        width = width,
        height = height,
        gap = 0,
        padding = { 0, 0, 0, 0 },
        align = 'stretch',
        justify = 'center',
        tag = tag,
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

local function centered_text(s, size, variant, color)
    return centered_fill(Text.new({
        text = s,
        font = FONT_PATH,
        fontSize = size or 18,
        color = color or FG,
        textVariant = variant,
        width = 'fill',
        textAlign = 'center',
    }))
end

local function screen_panel(opts)
    opts = opts or {}
    return Column.new({
        width = opts.width or 'fill',
        height = opts.height or 'fill',
        gap = opts.gap or 12,
        padding = opts.padding or { 20, 20, 20, 20 },
        align = opts.align or 'stretch',
        justify = opts.justify or 'start',
        tag = opts.tag or 'screen_content_box',
    })
end

local function build_text_screen()
    local root = screen_root({ gap = 12 })
    local content = screen_panel({
        width = 760,
        height = 420,
        align = 'stretch',
        justify = 'start',
    })
    root:addChild(content)

    content:addChild(Text.new({
        text = 'Text Surface',
        font = FONT_PATH,
        fontSize = 38,
        textVariant = 'title',
        color = FG,
        width = 'fill',
        textAlign = 'center',
    }))
    content:addChild(Text.new({
        text = 'textAlign + textVariant + wrap',
        font = FONT_PATH,
        fontSize = 18,
        color = SUB,
        width = 'fill',
        textAlign = 'center',
    }))

    content:addChild(Text.new({
        text = 'Aligned start',
        font = FONT_PATH,
        fontSize = 20,
        textAlign = 'start',
        width = 'fill',
    }))
    content:addChild(Text.new({
        text = 'Aligned center',
        font = FONT_PATH,
        fontSize = 20,
        textAlign = 'center',
        width = 'fill',
    }))
    content:addChild(Text.new({
        text = 'Aligned end',
        font = FONT_PATH,
        fontSize = 20,
        textAlign = 'end',
        width = 'fill',
    }))

    content:addChild(Text.new({
        text = 'This paragraph is wrapped. It uses wrap=true and maxWidth so line breaks are deterministic and follow the Text contract.',
        font = FONT_PATH,
        fontSize = 18,
        wrap = true,
        maxWidth = 720,
        width = 'fill',
        color = SUB,
    }))

    return root
end

local function build_button_screen()
    local root = screen_root({ gap = 12 })
    local content = screen_panel({
        width = 820,
        height = 290,
        align = 'stretch',
        justify = 'start',
    })
    root:addChild(content)
    content:addChild(Text.new({
        text = 'Button Activation And Disabled Behavior',
        font = FONT_PATH,
        fontSize = 30,
        color = FG,
        width = 'fill',
        textAlign = 'center',
    }))

    local row = Row.new({ width = 'fill', height = 'content', gap = 12, align = 'center', justify = 'center' })

    local btn_a_label = Text.new({
        text = 'Primary +' .. tostring(demo_state.buttons.a),
        font = FONT_PATH,
        fontSize = 18,
        width = 'fill',
        textAlign = 'center',
    })
    local btn_a = Button.new({
        width = 220,
        height = 56,
        onActivate = function()
            demo_state.buttons.a = demo_state.buttons.a + 1
        end,
        content = centered_fill(btn_a_label),
    })

    local btn_b_label = Text.new({
        text = 'Secondary +' .. tostring(demo_state.buttons.b),
        font = FONT_PATH,
        fontSize = 18,
        width = 'fill',
        textAlign = 'center',
    })
    local btn_b = Button.new({
        width = 220,
        height = 56,
        onActivate = function()
            demo_state.buttons.b = demo_state.buttons.b + 1
        end,
        content = centered_fill(btn_b_label),
    })

    local disabled = Button.new({
        width = 220,
        height = 56,
        disabled = true,
        content = centered_text('Disabled Button', 18),
    })

    row:addChild(btn_a)
    row:addChild(btn_b)
    row:addChild(disabled)
    content:addChild(row)

    local note_box = panel_box('fill', 56)
    note_box:addChild(Text.new({
        text = 'Press Space while focused for keyboard activation. Release outside keeps activation suppressed.',
        font = FONT_PATH,
        fontSize = 16,
        wrap = true,
        maxWidth = 760,
        width = 'fill',
        color = SUB,
        textAlign = 'center',
    }))
    content:addChild(note_box)

    rawset(root, '_demo_button_refs', {
        btn_a = btn_a,
        btn_b = btn_b,
        btn_a_label = btn_a_label,
        btn_b_label = btn_b_label,
    })
    return root
end

local function build_checkbox_switch_screen()
    local root = screen_root({ gap = 12 })
    local content = screen_panel({
        width = 820,
        height = 360,
        align = 'stretch',
        justify = 'start',
    })
    root:addChild(content)
    content:addChild(Text.new({
        text = 'Checkbox And Switch',
        font = FONT_PATH,
        fontSize = 30,
        color = FG,
        width = 'fill',
        textAlign = 'center',
    }))

    local row = Row.new({ width = 'fill', height = 'content', gap = 24, align = 'start', justify = 'center' })

    local left = Column.new({ width = 360, height = 'content', gap = 8, align = 'center', justify = 'start' })
    left:addChild(styled_text('Checkboxes', 22))
    left:addChild(Checkbox.new({ width = 320, height = 42, label = 'Unchecked' }))
    left:addChild(Checkbox.new({ width = 320, height = 42, checked = 'checked', onCheckedChange = function() end, label = 'Checked (controlled)' }))
    left:addChild(Checkbox.new({ width = 320, height = 42, checked = 'indeterminate', onCheckedChange = function() end, label = 'Indeterminate (controlled)' }))
    left:addChild(Checkbox.new({ width = 320, height = 42, disabled = true, label = 'Disabled' }))

    local right = Column.new({ width = 360, height = 'content', gap = 8, align = 'center', justify = 'start' })
    right:addChild(styled_text('Switches', 22))
    right:addChild(Switch.new({ width = 320, height = 42, label = 'Off' }))
    right:addChild(Switch.new({ width = 320, height = 42, checked = true, onCheckedChange = function() end, label = 'On (controlled)' }))
    right:addChild(Switch.new({ width = 320, height = 42, dragThreshold = 6, snapBehavior = 'directional', label = 'Drag directional' }))
    right:addChild(Switch.new({ width = 320, height = 42, disabled = true, label = 'Disabled' }))

    row:addChild(left)
    row:addChild(right)
    content:addChild(row)

    return root
end

local function build_text_input_screen()
    local root = screen_root({ gap = 12 })
    local content = screen_panel({
        width = 820,
        height = 440,
        align = 'center',
        justify = 'start',
    })
    root:addChild(content)
    content:addChild(styled_text('TextInput Scenarios', 30))

    content:addChild(TextInput.new({ width = 520, height = 44, placeholder = 'Type here...', font = FONT_PATH, fontSize = 18 }))
    content:addChild(TextInput.new({ width = 520, height = 44, value = 'Controlled value', onValueChange = function(v) demo_state.input_log = 'controlled: ' .. tostring(v) end, font = FONT_PATH, fontSize = 18 }))
    content:addChild(TextInput.new({ width = 520, height = 44, maxLength = 20, placeholder = 'Max 20 chars', font = FONT_PATH, fontSize = 18 }))
    content:addChild(TextInput.new({ width = 520, height = 44, disabled = true, value = 'Disabled', onValueChange = function() end, font = FONT_PATH, fontSize = 18 }))
    content:addChild(TextInput.new({ width = 520, height = 44, readOnly = true, value = 'Read only', onValueChange = function() end, font = FONT_PATH, fontSize = 18 }))
    content:addChild(TextInput.new({ width = 520, height = 44, submitBehavior = 'submit', onSubmit = function(v) demo_state.input_log = 'submit: ' .. tostring(v) end, placeholder = 'Submit on Enter', font = FONT_PATH, fontSize = 18 }))

    local log_box = panel_box('fill', 44)
    log_box:addChild(Text.new({
        text = 'Log: ' .. (demo_state.input_log or ''),
        font = FONT_PATH,
        fontSize = 16,
        color = SUB,
        wrap = true,
        maxWidth = 760,
        width = 'fill',
        textAlign = 'center',
    }))
    content:addChild(log_box)

    return root
end

local function build_text_area_screen()
    local root = screen_root({ gap = 12 })
    local content = screen_panel({
        width = 880,
        height = 410,
        align = 'stretch',
        justify = 'start',
    })
    root:addChild(content)
    content:addChild(Text.new({
        text = 'TextArea Scenarios',
        font = FONT_PATH,
        fontSize = 30,
        color = FG,
        width = 'fill',
        textAlign = 'center',
    }))

    local row = Row.new({ width = 'fill', height = 'content', gap = 16, align = 'start', justify = 'center' })

    local left = TextArea.new({
        width = 560,
        height = 280,
        wrap = true,
        rows = 8,
        font = FONT_PATH,
        fontSize = 18,
        value = 'Wrapped multiline text.\nPress Enter to insert newline.\nWheel scroll supported.',
        onValueChange = function() end,
    })

    local right = TextArea.new({
        width = 560,
        height = 280,
        wrap = false,
        scrollXEnabled = true,
        scrollYEnabled = true,
        font = FONT_PATH,
        fontSize = 18,
        value = 'Long line long line long line long line long line long line long line',
        onValueChange = function() end,
    })

    row:addChild(left)
    row:addChild(right)
    content:addChild(row)

    return root
end

local function build_tabs_screen()
    local root = screen_root({ gap = 12 })
    local content = screen_panel({
        width = 860,
        height = 560,
        align = 'stretch',
        justify = 'start',
    })
    root:addChild(content)
    content:addChild(Text.new({
        text = 'Tabs (Manual Activation)',
        font = FONT_PATH,
        fontSize = 30,
        color = FG,
        width = 'fill',
        textAlign = 'center',
    }))

    local tabs = Tabs.new({
        width = 'fill',
        height = 440,
        value = demo_state.tabs_value,
        onValueChange = function(v)
            demo_state.tabs_value = v
        end,
        orientation = 'horizontal',
        activationMode = 'manual',
        loopFocus = true,
        listScrollable = true,
        disabledValues = demo_state.tabs_disabled,
    })

    tabs:_register_tab('home', centered_text('Home', 16), centered_text('Home panel content', 20))
    tabs:_register_tab('settings', centered_text('Settings', 16), centered_text('Settings panel content', 20))
    tabs:_register_tab('profile', centered_text('Profile', 16), centered_text('Profile panel content', 20))
    tabs:_register_tab('billing', centered_text('Billing', 16), centered_text('Billing panel content', 20))
    tabs:_register_tab('activity', centered_text('Activity', 16), centered_text('Activity panel content', 20))
    tabs:_register_tab('security', centered_text('Security', 16), centered_text('Security panel content', 20))
    tabs:_register_tab('notifications', centered_text('Notifications', 16), centered_text('Notifications panel content', 20))
    tabs:_register_tab('members', centered_text('Members', 16), centered_text('Members panel content', 20))

    content:addChild(tabs)
    content:addChild(Text.new({ text = 'Press D to toggle disabled "settings" tab', font = FONT_PATH, fontSize = 16, color = SUB, width = 'fill', textAlign = 'center' }))

    rawset(root, '_demo_tabs_ref', tabs)
    return root
end

local builders = {
    build_text_screen,
    build_button_screen,
    build_checkbox_switch_screen,
    build_text_input_screen,
    build_text_area_screen,
    build_tabs_screen,
}

local function build_demo()
    if stage then stage:destroy() end
    local w, h = love.graphics.getDimensions()
    stage = Stage.new({ width = w, height = h })
    local root = builders[active]()
    stage.baseSceneLayer:addChild(root)
    stage:update(0)
end

local function draw_control_node(g, node)
    if rawget(node, '_destroyed') then return end
    local ev = rawget(node, '_effective_values')
    if ev and ev.visible == false then return end
    local bounds = rawget(node, '_world_bounds_cache')
    if bounds == nil then return end

    if rawget(node, '_ui_text_control') then
        node:_draw_control(g)
        return
    end

    if rawget(node, '_ui_button_control') then
        local disabled = node.disabled == true
        local pressed = node:_is_pressed()
        local hovered = rawget(node, '_hovered') == true
        local color = { 0.26, 0.3, 0.38, 1 }
        if disabled then
            color = { 0.2, 0.2, 0.24, 1 }
        elseif pressed then
            color = { 0.14, 0.52, 0.76, 1 }
        elseif hovered then
            color = { 0.18, 0.6, 0.86, 1 }
        end
        g.setColor(color)
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        g.setColor(BORDER)
        g.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        return
    end

    if rawget(node, '_ui_checkbox_control') then
        g.setColor({ 0.17, 0.18, 0.23, 1 })
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        local size = math.min(22, bounds.height - 12)
        local bx = bounds.x + 8
        local by = bounds.y + (bounds.height - size) * 0.5
        g.setColor({ 0.26, 0.29, 0.36, 1 })
        g.rectangle('fill', bx, by, size, size, 4, 4)
        g.setColor(BORDER)
        g.rectangle('line', bx, by, size, size, 4, 4)
        local st = node:_get_checked_state()
        if st == 'checked' then
            g.setColor(ACCENT)
            g.rectangle('fill', bx + 5, by + 5, size - 10, size - 10, 2, 2)
        elseif st == 'indeterminate' then
            g.setColor(ACCENT)
            g.rectangle('fill', bx + 4, by + size * 0.5 - 2, size - 8, 4)
        end
        if node.label ~= nil then
            g.setColor(FG)
            g.print(tostring(node.label), bx + size + 10, bounds.y + 11)
        end
        return
    end

    if rawget(node, '_ui_switch_control') then
        g.setColor({ 0.17, 0.18, 0.23, 1 })
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        local tw = 56
        local th = 24
        local tx = bounds.x + 8
        local ty = bounds.y + (bounds.height - th) * 0.5
        g.setColor({ 0.25, 0.28, 0.34, 1 })
        g.rectangle('fill', tx, ty, tw, th, 12, 12)
        local on = node:_get_checked_state()
        if on then
            g.setColor(ACCENT)
            g.rectangle('fill', tx, ty, tw, th, 12, 12)
        end
        g.setColor({ 0.96, 0.98, 1, 1 })
        local thumb_x = on and (tx + tw - th + 1) or (tx + 1)
        g.circle('fill', thumb_x + (th - 2) * 0.5, ty + th * 0.5, (th - 2) * 0.5)
        if node.label ~= nil then
            g.setColor(FG)
            g.print(tostring(node.label), tx + tw + 12, bounds.y + 11)
        end
        return
    end

    if rawget(node, '_ui_text_input_control') then
        g.setColor({ 0.13, 0.15, 0.19, 1 })
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        g.setColor(BORDER)
        g.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)

        local value = node:_get_value()
        local focused = node:_is_focused()
        local draw_text = value
        if draw_text == '' and not focused and node.placeholder ~= nil then
            g.setColor(SUB)
            draw_text = tostring(node.placeholder)
        else
            g.setColor(FG)
        end

        local font = love.graphics.newFont(tonumber(node.fontSize or 16))
        local old = g.getFont()
        g.setFont(font)
        g.print(draw_text, bounds.x + 10, bounds.y + (bounds.height - font:getHeight()) * 0.5)

        if focused and rawget(node, '_caret_blink_on') then
            local _, e = node:_get_selection()
            local prefix = value:sub(1, e)
            local cx = bounds.x + 10 + font:getWidth(prefix)
            g.setColor(ACCENT)
            g.rectangle('fill', cx, bounds.y + 8, 2, bounds.height - 16)
        end

        if node:_is_composing() then
            g.setColor({ 1, 0.8, 0.3, 1 })
            g.print(node:_composition_text_value(), bounds.x + 10, bounds.y + bounds.height - 14)
        end

        g.setFont(old)
        return
    end

    if rawget(node, '_ui_tabs_control') then
        g.setColor({ 0.14, 0.15, 0.2, 1 })
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        g.setColor(BORDER)
        g.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        return
    end

    if rawget(node, '_tab_trigger_value') ~= nil then
        local active = rawget(node, '_tab_active') == true
        local disabled = rawget(node, '_tab_disabled') == true
        local c = active and { 0.2, 0.62, 0.9, 1 } or { 0.2, 0.23, 0.3, 1 }
        if disabled then c = { 0.2, 0.2, 0.22, 1 } end
        g.setColor(c)
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        g.setColor(BORDER)
        g.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        return
    end

    if (ev and ev.tag) == 'text_slot_box' then
        g.setColor({ 0.16, 0.17, 0.22, 1 })
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        g.setColor({ 0.27, 0.3, 0.38, 1 })
        g.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        return
    end

    if (ev and ev.tag) == 'text_wrap_box' then
        g.setColor({ 0.15, 0.16, 0.21, 1 })
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        g.setColor({ 0.25, 0.28, 0.36, 1 })
        g.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 6, 6)
        return
    end

    if (ev and ev.tag) == 'screen_content_box' then
        g.setColor({ 0.12, 0.13, 0.18, 1 })
        g.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
        g.setColor({ 0.3, 0.33, 0.42, 1 })
        g.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
        return
    end

end

function love.load()
    love.graphics.setBackgroundColor(BG)
    build_demo()
end

function love.update(dt)
    demo_state.controlled_tick = demo_state.controlled_tick + dt
    if demo_state.controlled_tick > 3 then
        demo_state.controlled_tick = 0
        demo_state.controlled_value = not demo_state.controlled_value
    end

    if stage and not rawget(stage, '_destroyed') then
        if active == 2 then
            local root = (rawget(stage.baseSceneLayer, '_children') or {})[1]
            if root and rawget(root, '_demo_button_refs') then
                local refs = rawget(root, '_demo_button_refs')
                if refs.btn_a_label and rawget(refs.btn_a_label, '_ui_text_control') then
                    refs.btn_a_label:setText('Primary +' .. tostring(demo_state.buttons.a))
                end
                if refs.btn_b_label and rawget(refs.btn_b_label, '_ui_text_control') then
                    refs.btn_b_label:setText('Secondary +' .. tostring(demo_state.buttons.b))
                end
            end
        end

        if active == 6 then
            local root = (rawget(stage.baseSceneLayer, '_children') or {})[1]
            local tabs = root and rawget(root, '_demo_tabs_ref')
            if tabs ~= nil then
                tabs.value = demo_state.tabs_value
            end
        end

        stage:update(dt)
    end
end

function love.draw()
    if not stage or rawget(stage, '_destroyed') then return end

    if not rawget(stage, '_update_ran') then
        stage:update(0)
    end

    local g = love.graphics
    local w, h = g.getDimensions()

    stage:draw(g, function(node)
        draw_control_node(g, node)
    end)

    g.setColor(FG)
    g.printf('[' .. active .. '/' .. #names .. '] ' .. names[active], 0, 8, w, 'center')
    g.setColor(SUB)
    g.printf('Left/Right: switch screens   Backspace: delete in focused text field   D: toggle settings-tab disabled', 0, h - 22, w, 'center')
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
        return
    end

    if key == 'right' then
        active = (active % #names) + 1
        build_demo()
        return
    end

    if key == 'left' then
        active = ((active - 2) % #names) + 1
        build_demo()
        return
    end

    if key == 'd' and active == 6 then
        if demo_state.tabs_disabled[1] == 'settings' then
            demo_state.tabs_disabled = {}
        else
            demo_state.tabs_disabled = { 'settings' }
        end
        build_demo()
        return
    end

    if key == 'backspace' and stage and not rawget(stage, '_destroyed') then
        local focus = rawget(stage, '_focus_owner')
        if focus and rawget(focus, '_ui_text_input_control') then
            focus:_delete_backward()
            return
        end
    end

    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'keypressed', key = key })
    end
end

function love.wheelmoved(x, y)
    if stage and not rawget(stage, '_destroyed') then
        local mx, my = love.mouse.getPosition()
        stage:deliverInput({ kind = 'wheelmoved', x = x, y = y, stageX = mx, stageY = my })
    end
end

function love.mousepressed(x, y, button)
    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'mousepressed', x = x, y = y, button = button })
        if button == 1 then
            local target = stage:resolveTarget(x, y)
            local clear = true
            local node = target
            while node ~= nil do
                local ev = rawget(node, '_effective_values')
                if ev and ev.focusable == true and ev.enabled ~= false and ev.visible ~= false then
                    clear = false
                    break
                end
                node = rawget(node, 'parent')
                if node == stage then
                    break
                end
            end
            if clear and stage._request_focus_internal then
                stage:_request_focus_internal(nil)
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'mousereleased', x = x, y = y, button = button })
    end
end

function love.mousemoved(x, y, dx, dy)
    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'mousemoved', x = x, y = y, dx = dx, dy = dy })
    end
end

function love.textinput(text)
    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'textinput', text = text })
    end
end

function love.textedited(text, start, length)
    if stage and not rawget(stage, '_destroyed') then
        stage:deliverInput({ kind = 'textedited', text = text, start = start, length = length })
    end
end

function love.resize()
    build_demo()
end
