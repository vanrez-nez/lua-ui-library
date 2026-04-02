package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')

local Stage = UI.Stage
local Column = UI.Column
local Row = UI.Row
local Container = UI.Container
local Text = UI.Text
local Button = UI.Button
local Modal = UI.Modal
local Alert = UI.Alert
local Tabs = UI.Tabs
local Radio = UI.Radio
local RadioGroup = UI.RadioGroup
local Select = UI.Select
local Option = UI.Option
local Slider = UI.Slider
local ProgressBar = UI.ProgressBar
local Notification = UI.Notification
local Tooltip = UI.Tooltip
local Texture = UI.Texture
local Atlas = UI.Atlas
local Sprite = UI.Sprite
local Image = UI.Image

local BG = { 0.08, 0.09, 0.11, 1 }
local PANEL = { 0.14, 0.15, 0.19, 1 }
local BORDER = { 0.36, 0.39, 0.46, 1 }
local FG = { 0.95, 0.96, 0.98, 1 }
local SUB = { 0.66, 0.69, 0.75, 1 }
local ACCENT = { 0.19, 0.66, 0.96, 1 }
local SUCCESS = { 0.25, 0.76, 0.49, 1 }
local WARNING = { 0.96, 0.74, 0.25, 1 }
local DANGER = { 0.91, 0.35, 0.34, 1 }

local stage
local root
local refs = {}
local demo = {
    screen = 1,
    radio_value = 'alpha',
    single_value = nil,
    multi_value = { 'one', 'three' },
    select_open = false,
    notification_open = false,
    tooltip_open = false,
    slider_value = 0.35,
    progress_value = 0.45,
    modal_open = false,
    alert_open = false,
    tabs_value = 'overview',
    log_lines = {},
}
local screen_defs

local function push_log(message)
    local log = demo.log_lines
    log[#log + 1] = message
    while #log > 14 do
        table.remove(log, 1)
    end
end

local function label(text, size, color)
    return Text.new({
        text = text,
        fontSize = size or 16,
        color = color or FG,
        width = 'fill',
        wrap = true,
    })
end

local function panel(width, height)
    local node = Column.new({
        width = width or 'fill',
        height = height or 'content',
        padding = { 16, 16, 16, 16 },
        gap = 12,
        align = 'stretch',
        justify = 'start',
    })
    rawset(node, '_phase10_panel', true)
    return node
end

local function button(label_text, on_activate)
    return Button.new({
        width = 180,
        height = 42,
        onActivate = on_activate,
        content = label(label_text, 16, FG),
        motionPreset = 'quick',
    })
end

local function make_texture()
    local image_data = love.image.newImageData(32, 32)
    for y = 0, 31 do
        for x = 0, 31 do
            local on = ((math.floor(x / 8)) + (math.floor(y / 8))) % 2 == 0
            image_data:setPixel(x, y, on and 0.2 or 0.9, on and 0.75 or 0.4, on and 0.95 or 0.25, 1)
        end
    end
    local image = love.graphics.newImage(image_data)
    return Texture.new({ source = image, resolvedSourceIdentity = 'generated-checker' })
end

local function build_graphics_screen()
    local texture = make_texture()
    local atlas = Atlas.new({
        texture = texture,
        regions = {
            left = { x = 0, y = 0, width = 16, height = 32 },
            right = { x = 16, y = 0, width = 16, height = 32 },
        },
    })
    local left_sprite = Sprite.new({ atlas = atlas, region = 'left' })
    local clipped_sprite = Sprite.new({
        texture = texture,
        region = { x = 20, y = 0, width = 20, height = 32 },
    })

    local row = Row.new({
        width = 'fill',
        height = 220,
        gap = 24,
    })
    row:addChild(Image.new({ width = 180, height = 180, source = texture, fit = 'contain' }))
    row:addChild(Image.new({ width = 180, height = 180, source = left_sprite, fit = 'stretch', sampling = 'nearest' }))
    row:addChild(Image.new({ width = 180, height = 180, source = clipped_sprite, fit = 'cover' }))

    local info = panel('fill', 'content')
    info:addChild(label('Graphics: Texture, Atlas, Sprite, and Image'))
    info:addChild(label('Texture size: ' .. texture:getWidth() .. 'x' .. texture:getHeight(), 14, SUB))
    info:addChild(label('Sprite size: ' .. left_sprite:getWidth() .. 'x' .. left_sprite:getHeight(), 14, SUB))
    info:addChild(row)
    refs.graphics_texture = texture
    refs.graphics_sprite = left_sprite
    return info
end

local function build_radio_screen()
    local group = RadioGroup.new({
        width = 'fill',
        height = 180,
        value = demo.radio_value,
        onValueChange = function(value)
            demo.radio_value = value
            push_log('radio -> ' .. tostring(value))
        end,
    })
    group:addChild(Radio.new({ value = 'alpha', width = 'fill', height = 40 }))
    group:addChild(Radio.new({ value = 'beta', width = 'fill', height = 40, disabled = true }))
    group:addChild(Radio.new({ value = 'gamma', width = 'fill', height = 40 }))

    local content = panel('fill', 'content')
    content:addChild(label('RadioGroup'))
    content:addChild(label('Current value: ' .. tostring(demo.radio_value), 14, SUB))
    content:addChild(group)
    refs.radio_group = group
    return content
end

local function build_select_screen()
    local single = Select.new({
        width = 280,
        height = 44,
        value = demo.single_value,
        onValueChange = function(value)
            demo.single_value = value
            push_log('single select -> ' .. tostring(value))
        end,
        open = demo.select_open,
        onOpenChange = function(value)
            demo.select_open = value
            push_log('single popup -> ' .. tostring(value))
        end,
        placeholder = 'Pick one',
        motionPreset = 'popup',
    })
    single:addChild(Option.new({ value = 'one' }))
    single:addChild(Option.new({ value = 'two', disabled = true }))
    single:addChild(Option.new({ value = 'three' }))

    local multi = Select.new({
        width = 280,
        height = 44,
        selectionMode = 'multiple',
        value = demo.multi_value,
        onValueChange = function(value)
            demo.multi_value = value
            push_log('multi select -> ' .. tostring(value and #value or 0) .. ' item(s)')
        end,
        placeholder = 'Pick many',
        modal = true,
        motionPreset = 'popup',
    })
    multi:addChild(Option.new({ value = 'one' }))
    multi:addChild(Option.new({ value = 'two' }))
    multi:addChild(Option.new({ value = 'three' }))

    local content = panel('fill', 'content')
    content:addChild(label('Select / Option'))
    content:addChild(single)
    content:addChild(multi)
    refs.single_select = single
    refs.multi_select = multi
    return content
end

local function build_overlay_screen()
    local content = panel('fill', 'content')
    content:addChild(label('Notification / Tooltip'))
    content:addChild(button('Toggle Notification', function()
        demo.notification_open = not demo.notification_open
    end))
    content:addChild(button('Toggle Tooltip', function()
        demo.tooltip_open = not demo.tooltip_open
    end))

    local notice = Notification.new({
        open = demo.notification_open,
        onOpenChange = function(value)
            demo.notification_open = value
            push_log('notification -> ' .. tostring(value))
        end,
        closeMethod = 'button',
        motionPreset = 'notice',
        content = label('Phase 10 notification', 16, FG),
    })
    content:addChild(notice)

    local tip = Tooltip.new({
        open = demo.tooltip_open,
        onOpenChange = function(value)
            demo.tooltip_open = value
            push_log('tooltip -> ' .. tostring(value))
        end,
        triggerMode = 'manual',
        trigger = button('Tooltip Trigger', function() end),
        content = label('Tooltip content anchored to the trigger.', 14, FG),
        motionPreset = 'tip',
    })
    content:addChild(tip)
    refs.notification = notice
    refs.tooltip = tip
    return content
end

local function build_motion_screen()
    local content = panel('fill', 'content')
    content:addChild(label('Motion / Retrofits'))

    local slider = Slider.new({
        width = 320,
        height = 36,
        value = demo.slider_value,
        onValueChange = function(value)
            demo.slider_value = value
            slider.value = value
            push_log(string.format('slider -> %.2f', value))
        end,
        motionPreset = 'state',
    })
    local progress = ProgressBar.new({
        width = 320,
        height = 26,
        value = demo.progress_value,
        motionPreset = 'progress',
    })
    local tabs = Tabs.new({
        width = 520,
        height = 220,
        value = demo.tabs_value,
        onValueChange = function(value)
            demo.tabs_value = value
            tabs.value = value
            push_log('tabs -> ' .. tostring(value))
        end,
        motionPreset = 'tabs',
    })
    tabs:_register_tab('overview', label('Overview'), label('Overview panel'))
    tabs:_register_tab('details', label('Details'), label('Details panel'))

    local modal = Modal.new({
        open = demo.modal_open,
        onOpenChange = function(value)
            demo.modal_open = value
            push_log('modal -> ' .. tostring(value))
        end,
        motionPreset = 'overlay',
        content = label('Modal surface', 18, FG),
    })
    local alert = Alert.new({
        open = demo.alert_open,
        onOpenChange = function(value)
            demo.alert_open = value
            push_log('alert -> ' .. tostring(value))
        end,
        title = 'Alert',
        actions = { button('Close', function() demo.alert_open = false end) },
        motionPreset = 'overlay',
    })

    content:addChild(button('Advance Progress', function()
        demo.progress_value = demo.progress_value + 0.1
        if demo.progress_value > 1 then
            demo.progress_value = 0
        end
        progress.value = demo.progress_value
    end))
    content:addChild(button('Toggle Modal', function() demo.modal_open = not demo.modal_open end))
    content:addChild(button('Toggle Alert', function() demo.alert_open = not demo.alert_open end))
    content:addChild(slider)
    content:addChild(progress)
    content:addChild(tabs)
    content:addChild(modal)
    content:addChild(alert)
    refs.slider = slider
    refs.progress = progress
    refs.tabs = tabs
    refs.modal = modal
    refs.alert = alert
    return content
end

screen_defs = {
    {
        title = 'Graphics Objects',
        subtitle = 'Texture, Atlas, Sprite, and Image.',
        build = build_graphics_screen,
    },
    {
        title = 'Radio Group',
        subtitle = 'Single-selection coordination and roving focus.',
        build = build_radio_screen,
    },
    {
        title = 'Select And Option',
        subtitle = 'Single and multiple popup selection behavior.',
        build = build_select_screen,
    },
    {
        title = 'Notification And Tooltip',
        subtitle = 'Overlay-mounted non-modal surfaces.',
        build = build_overlay_screen,
    },
    {
        title = 'Motion And Retrofits',
        subtitle = 'Slider, ProgressBar, Tabs, Modal, and Alert.',
        build = build_motion_screen,
    },
}

local function sync_log_view()
    if refs.log_text ~= nil then
        refs.log_text:setText((#demo.log_lines > 0) and table.concat(demo.log_lines, '\n') or 'No events yet.')
    end
end

local function sync_demo_state()
    if refs.radio_group ~= nil then
        refs.radio_group.value = demo.radio_value
    end
    if refs.single_select ~= nil then
        refs.single_select.value = demo.single_value
        refs.single_select.open = demo.select_open
    end
    if refs.multi_select ~= nil then
        refs.multi_select.value = demo.multi_value
    end
    if refs.notification ~= nil then
        refs.notification.open = demo.notification_open
    end
    if refs.tooltip ~= nil then
        refs.tooltip.open = demo.tooltip_open
    end
    if refs.slider ~= nil then
        refs.slider.value = demo.slider_value
    end
    if refs.progress ~= nil then
        refs.progress.value = demo.progress_value
    end
    if refs.modal ~= nil then
        refs.modal.open = demo.modal_open
    end
    if refs.alert ~= nil then
        refs.alert.open = demo.alert_open
    end
    if refs.tabs ~= nil then
        refs.tabs.value = demo.tabs_value
    end
    sync_log_view()
end

local function rebuild()
    if stage ~= nil then
        stage:destroy()
    end

    stage = Stage.new({ width = love.graphics.getWidth(), height = love.graphics.getHeight() })
    refs = {}

    root = Column.new({
        width = 'fill',
        height = 'fill',
        padding = { 20, 20, 20, 20 },
        gap = 16,
    })

    local screen = screen_defs[demo.screen] or screen_defs[1]

    root:addChild(label('Phase 10 Harness', 28, FG))
    root:addChild(label('Press 1-5 to switch feature screens for isolated debugging.', 14, SUB))
    root:addChild(label(
        string.format('Screen %d: %s', demo.screen, screen.title),
        16,
        ACCENT
    ))

    local content = Column.new({
        width = 'fill',
        height = 'fill',
        gap = 16,
        align = 'stretch',
        justify = 'start',
    })
    local wrapper = panel('fill', 'fill')
    wrapper:addChild(label(screen.title, 22, FG))
    wrapper:addChild(label(screen.subtitle, 14, SUB))
    wrapper:addChild(screen.build())
    content:addChild(wrapper)
    root:addChild(content)

    local log = panel('fill', 160)
    log:addChild(label('Log', 16, FG))
    local log_text = label((#demo.log_lines > 0) and table.concat(demo.log_lines, '\n') or 'No events yet.', 13, SUB)
    log:addChild(log_text)
    refs.log_text = log_text
    root:addChild(log)

    stage.baseSceneLayer:addChild(root)
    sync_demo_state()
    stage:update(0)
end

local function draw_node(node)
    local bounds = rawget(node, '_world_bounds_cache')
    if bounds == nil then
        return
    end

    if rawget(node, '_ui_text_control') then
        node:_draw_control(love.graphics)
        return
    end

    if rawget(node, '_ui_image_control') then
        node:_draw_control(love.graphics)
        love.graphics.setColor(BORDER)
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height)
        return
    end

    if rawget(node, '_ui_button_control') then
        love.graphics.setColor(PANEL)
        love.graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        love.graphics.setColor(BORDER)
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        return
    end

    if rawget(node, '_phase10_panel') then
        love.graphics.setColor(PANEL)
        love.graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
        love.graphics.setColor(BORDER)
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
        return
    end

    if rawget(node, '_ui_radio_control') then
        love.graphics.setColor(PANEL)
        love.graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        love.graphics.setColor(BORDER)
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        local cx = bounds.x + 16
        local cy = bounds.y + bounds.height * 0.5
        love.graphics.circle('line', cx, cy, 8)
        if node:_is_selected() then
            love.graphics.setColor(ACCENT)
            love.graphics.circle('fill', cx, cy, 4)
        end
        return
    end

    if rawget(node, '_ui_option_control') or rawget(node, '_ui_select_control') or rawget(node, '_ui_notification_control') or rawget(node, '_ui_tooltip_control') or rawget(node, '_ui_modal_control') then
        love.graphics.setColor(PANEL)
        love.graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        love.graphics.setColor(BORDER)
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        return
    end

    if rawget(node, '_ui_slider_control') then
        love.graphics.setColor(BORDER)
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        return
    end

    if rawget(node, '_ui_progress_bar_control') then
        love.graphics.setColor({ 0.2, 0.23, 0.28, 1 })
        love.graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        love.graphics.setColor(BORDER)
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        return
    end

    if rawget(node, '_ui_tabs_control') then
        love.graphics.setColor(PANEL)
        love.graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        love.graphics.setColor(BORDER)
        love.graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 8, 8)
        return
    end
end

function love.load()
    rebuild()
end

function love.update(dt)
    if stage ~= nil then
        sync_demo_state()
        stage:update(dt)
    end
end

function love.draw()
    love.graphics.clear(BG)
    if stage ~= nil then
        stage:draw(love.graphics, function(node)
            draw_node(node)
        end)
    end
end

function love.keypressed(key)
    if key == '1' or key == '2' or key == '3' or key == '4' or key == '5' then
        demo.screen = tonumber(key)
        rebuild()
        return
    end

    if stage ~= nil then
        stage:deliverInput({ kind = 'keypressed', key = key })
    end
end

function love.mousepressed(x, y, button)
    if stage ~= nil then
        stage:deliverInput({ kind = 'mousepressed', x = x, y = y, button = button })
    end
end

function love.mousereleased(x, y, button)
    if stage ~= nil then
        stage:deliverInput({ kind = 'mousereleased', x = x, y = y, button = button })
    end
end

function love.mousemoved(x, y, dx, dy)
    if stage ~= nil then
        stage:deliverInput({ kind = 'mousemoved', x = x, y = y, dx = dx, dy = dy })
    end
end

function love.wheelmoved(x, y)
    if stage ~= nil then
        local mx, my = love.mouse.getPosition()
        stage:deliverInput({ kind = 'wheelmoved', x = x, y = y, stageX = mx, stageY = my })
    end
end
