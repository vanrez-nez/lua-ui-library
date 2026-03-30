package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')

local Container = UI.Container
local Stage = UI.Stage

local floor = math.floor
local max = math.max
local min = math.min

local HEADER_HEIGHT = 112
local FOOTER_HEIGHT = 176
local OUTER_MARGIN = 18
local CONTENT_GAP = 18
local LOG_WIDTH = 408
local LOG_LIMIT = 20

local TITLE_FONT = nil
local BODY_FONT = nil
local SMALL_FONT = nil

local colors = {
    background = { 0.05, 0.06, 0.08, 1 },
    chrome = { 0.10, 0.12, 0.16, 0.98 },
    chrome_line = { 0.24, 0.31, 0.40, 1 },
    panel = { 0.10, 0.14, 0.18, 0.94 },
    panel_line = { 0.28, 0.36, 0.46, 1 },
    panel_soft = { 0.14, 0.18, 0.23, 0.92 },
    text = { 0.94, 0.97, 1.00, 1 },
    muted = { 0.68, 0.75, 0.83, 1 },
    accent = { 0.98, 0.79, 0.32, 1 },
    accent_fill = { 0.98, 0.79, 0.32, 0.18 },
    success = { 0.47, 0.90, 0.64, 1 },
    success_fill = { 0.20, 0.60, 0.38, 0.18 },
    danger = { 0.98, 0.54, 0.52, 1 },
    danger_fill = { 0.74, 0.28, 0.26, 0.22 },
    blue = { 0.44, 0.70, 1.00, 1 },
    blue_fill = { 0.23, 0.43, 0.82, 0.22 },
    cyan = { 0.39, 0.88, 0.97, 1 },
    cyan_fill = { 0.16, 0.57, 0.64, 0.22 },
    violet = { 0.82, 0.69, 0.99, 1 },
    violet_fill = { 0.49, 0.34, 0.76, 0.22 },
    gold = { 0.96, 0.82, 0.40, 1 },
    gold_fill = { 0.73, 0.54, 0.14, 0.20 },
    slate = { 0.67, 0.73, 0.82, 1 },
    slate_fill = { 0.32, 0.38, 0.48, 0.22 },
    focus = { 1.00, 0.95, 0.66, 1 },
}

local screen_builders = {}
local current_index = 1
local current_screen = nil

local function load_font(path, size)
    local ok, font = pcall(love.graphics.newFont, path, size)

    if ok then
        return font
    end

    return love.graphics.newFont(size)
end

local function round(value)
    return floor(value + 0.5)
end

local function rgba(color, alpha_override)
    love.graphics.setColor(
        color[1],
        color[2],
        color[3],
        alpha_override or color[4] or 1
    )
end

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function point_in_rect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.width and
        y >= rect.y and y <= rect.y + rect.height
end

local function node_label(node)
    if node == nil then
        return 'nil'
    end

    if node.tag ~= nil then
        return tostring(node.tag)
    end

    return '<untagged>'
end

local function push_log(log, entry)
    log[#log + 1] = entry

    if #log > 120 then
        table.remove(log, 1)
    end
end

local function tail_entries(entries, limit)
    local count = #entries
    local start_index = max(1, count - limit + 1)
    local sliced = {}

    for index = start_index, count do
        sliced[#sliced + 1] = entries[index]
    end

    if #sliced == 0 then
        sliced[1] = '(empty)'
    end

    return sliced
end

local function content_rect(width, height)
    local x = OUTER_MARGIN
    local y = HEADER_HEIGHT + OUTER_MARGIN
    local footer_top = height - FOOTER_HEIGHT - OUTER_MARGIN
    local content_height = max(160, footer_top - y)
    local content_width = width - OUTER_MARGIN * 2 - LOG_WIDTH - CONTENT_GAP

    return {
        x = x,
        y = y,
        width = max(320, content_width),
        height = content_height,
    }
end

local function log_rect(width, height)
    local demo = content_rect(width, height)

    return {
        x = demo.x + demo.width + CONTENT_GAP,
        y = demo.y,
        width = LOG_WIDTH,
        height = demo.height,
    }
end

local function footer_rect(width, height)
    return {
        x = OUTER_MARGIN,
        y = height - FOOTER_HEIGHT - OUTER_MARGIN,
        width = width - OUTER_MARGIN * 2,
        height = FOOTER_HEIGHT,
    }
end

local function nav_button_rects(width)
    local button_width = 122
    local button_height = 38
    local top = 34

    return {
        prev = {
            x = width - button_width * 2 - 24,
            y = top,
            width = button_width,
            height = button_height,
        },
        next = {
            x = width - button_width - 18,
            y = top,
            width = button_width,
            height = button_height,
        },
    }
end

local function draw_rounded_panel(rect, fill, line)
    rgba(fill)
    love.graphics.rectangle(
        'fill',
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        16,
        16
    )

    rgba(line)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle(
        'line',
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        16,
        16
    )
end

local function draw_button(rect, label, accent)
    local fill = accent and colors.accent_fill or colors.panel_soft
    local line = accent and colors.accent or colors.panel_line

    draw_rounded_panel(rect, fill, line)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.text)
    love.graphics.printf(
        label,
        rect.x,
        rect.y + 9,
        rect.width,
        'center'
    )
end

local function draw_checkbox(rect, label, checked)
    local box = {
        x = rect.x,
        y = rect.y + 2,
        width = 24,
        height = 24,
    }

    draw_rounded_panel(box, colors.panel_soft, checked and colors.accent or colors.panel_line)

    if checked then
        rgba(colors.accent)
        love.graphics.setLineWidth(3)
        love.graphics.line(
            box.x + 5,
            box.y + 13,
            box.x + 10,
            box.y + 18,
            box.x + 19,
            box.y + 7
        )
    end

    love.graphics.setFont(BODY_FONT)
    rgba(colors.text)
    love.graphics.print(label, rect.x + 34, rect.y + 3)
end

local function draw_panel_text(rect, title, lines)
    draw_rounded_panel(rect, colors.panel, colors.panel_line)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.accent)
    love.graphics.print(title, rect.x + 16, rect.y + 12)

    love.graphics.setFont(SMALL_FONT)
    rgba(colors.muted)

    local y = rect.y + 42

    for index = 1, #lines do
        love.graphics.printf(
            lines[index],
            rect.x + 16,
            y,
            rect.width - 32,
            'left'
        )
        y = y + 18
    end
end

local function new_stage(width, height)
    return Stage.new({
        width = width,
        height = height,
    })
end

local function sync_stage(stage)
    stage:update(0)
end

local function set_demo(node, label, fill, line)
    node.demo = {
        label = label,
        fill = fill,
        line = line,
    }

    return node
end

local function new_box(label, opts, fill, line)
    return set_demo(Container.new(opts), label, fill, line)
end

local function draw_demo_node(node)
    local demo = rawget(node, 'demo')

    if demo == nil then
        return
    end

    local bounds = node:getWorldBounds()
    local hovered = rawget(node, '_hovered') == true

    rgba(demo.fill)
    love.graphics.rectangle(
        'fill',
        bounds.x,
        bounds.y,
        bounds.width,
        bounds.height,
        14,
        14
    )

    love.graphics.setLineWidth(hovered and 4 or 2)
    rgba(hovered and colors.focus or demo.line)
    love.graphics.rectangle(
        'line',
        bounds.x,
        bounds.y,
        bounds.width,
        bounds.height,
        14,
        14
    )

    if bounds.width >= 64 and bounds.height >= 28 then
        love.graphics.setFont(BODY_FONT)
        rgba(colors.text)
        love.graphics.printf(
            demo.label,
            bounds.x + 8,
            bounds.y + max(10, bounds.height * 0.5 - 11),
            max(0, bounds.width - 16),
            'center'
        )
    end
end

local function seed_focus(stage, node)
    rawset(stage, '_focused_node', node)
end

local function dispatch_stage_input(screen, raw_event, catch_errors)
    local function run_delivery()
        local delivery = screen.stage:deliverInput(raw_event)
        sync_stage(screen.stage)
        return delivery
    end

    if not catch_errors then
        local delivery = run_delivery()

        if screen.after_delivery ~= nil then
            screen:after_delivery(raw_event, delivery)
        end

        return true, delivery
    end

    local ok, result = pcall(run_delivery)

    if ok then
        if screen.after_delivery ~= nil then
            screen:after_delivery(raw_event, result)
        end

        return true, result
    end

    if screen.on_dispatch_error ~= nil then
        screen:on_dispatch_error(raw_event, result)
    else
        push_log(screen.log, 'caught dispatch error: ' .. tostring(result))
    end

    local sync_ok, sync_err = pcall(sync_stage, screen.stage)

    if not sync_ok then
        push_log(screen.log, 'post-error update failed: ' .. tostring(sync_err))
    end

    return false, result
end

local function draw_screen_frame(screen)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local demo = content_rect(width, height)
    local log = log_rect(width, height)

    draw_rounded_panel(demo, colors.panel, colors.panel_line)
    draw_rounded_panel(log, colors.panel, colors.panel_line)

    screen.stage:draw(love.graphics, function(node)
        draw_demo_node(node)
    end)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.accent)
    love.graphics.print('Demo Area', demo.x + 16, demo.y + 12)
    love.graphics.print('Event Log', log.x + 16, log.y + 12)

    love.graphics.setFont(SMALL_FONT)
    rgba(colors.muted)
    love.graphics.printf(
        screen.summary,
        demo.x + 16,
        demo.y + 40,
        demo.width - 32,
        'left'
    )

    local entries = tail_entries(screen.log, LOG_LIMIT)
    local y = log.y + 46

    for index = 1, #entries do
        rgba(index == #entries and colors.text or colors.muted)
        love.graphics.printf(
            entries[index],
            log.x + 16,
            y,
            log.width - 32,
            'left'
        )
        y = y + 18
    end

    if screen.draw_overlay ~= nil then
        screen:draw_overlay(demo, log)
    end
end

local function draw_header(screen)
    local width = love.graphics.getWidth()
    local nav = nav_button_rects(width)

    rgba(colors.chrome)
    love.graphics.rectangle('fill', 0, 0, width, HEADER_HEIGHT)
    rgba(colors.chrome_line)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, HEADER_HEIGHT, width, HEADER_HEIGHT)

    love.graphics.setFont(TITLE_FONT)
    rgba(colors.text)
    love.graphics.print(
        string.format('Phase 4 Harness  %d/%d', current_index, #screen_builders),
        18,
        22
    )

    love.graphics.setFont(BODY_FONT)
    rgba(colors.accent)
    love.graphics.print(screen.title, 18, 60)

    love.graphics.setFont(SMALL_FONT)
    rgba(colors.muted)
    love.graphics.print(
        'Screen switch: [ and ] or the buttons on the right',
        18,
        88
    )

    draw_button(nav.prev, 'Prev [', false)
    draw_button(nav.next, 'Next ]', true)
end

local function draw_footer(screen)
    local rect = footer_rect(love.graphics.getWidth(), love.graphics.getHeight())

    draw_rounded_panel(rect, colors.chrome, colors.chrome_line)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.accent)
    love.graphics.print('Acceptance Notes', rect.x + 16, rect.y + 12)

    love.graphics.setFont(SMALL_FONT)
    rgba(colors.muted)

    local y = rect.y + 42

    for index = 1, #screen.instructions do
        love.graphics.printf(
            screen.instructions[index],
            rect.x + 16,
            y,
            rect.width - 32,
            'left'
        )
        y = y + 18
    end

    if screen.draw_footer_controls ~= nil then
        screen:draw_footer_controls(rect)
    end
end

local function make_capture_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local center_x = demo.x + demo.width * 0.44
    local center_y = demo.y + demo.height * 0.56

    local outer = new_box('Outer', {
        tag = 'outer',
        x = center_x - 130,
        y = center_y - 130,
        width = 260,
        height = 260,
    }, colors.blue_fill, colors.blue)
    local middle = new_box('Middle', {
        tag = 'middle',
        x = 46,
        y = 46,
        width = 168,
        height = 168,
    }, colors.cyan_fill, colors.cyan)
    local inner = new_box('Inner', {
        tag = 'inner',
        interactive = true,
        x = 44,
        y = 44,
        width = 80,
        height = 80,
    }, colors.gold_fill, colors.gold)

    local screen = {
        title = 'Capture, Target, Bubble',
        summary = 'Nested target path logging with optional stopPropagation at the middle bubble phase and a guarded failure probe that keeps the harness alive after pcall catches the error.',
        instructions = {
            'Click inside Inner to log capture, target, and bubble order.',
            'Toggle "Stop at Middle bubble" to truncate later bubbling without cancelling the default path itself.',
            'Use "Guard next inner tap" to catch a thrown listener with pcall and confirm the harness still resolves targets afterward.',
        },
        stage = stage,
        log = {},
        stop_middle_bubble = false,
        fail_next_tap = false,
        outer = outer,
        middle = middle,
        inner = inner,
    }

    stage.baseSceneLayer:addChild(outer)
    outer:addChild(middle)
    middle:addChild(inner)

    outer:_add_event_listener('ui.activate', function()
        push_log(screen.log, 'outer capture')
    end, 'capture')
    middle:_add_event_listener('ui.activate', function()
        push_log(screen.log, 'middle capture')
    end, 'capture')
    inner:_add_event_listener('ui.activate', function()
        push_log(screen.log, 'inner capture')
    end, 'capture')
    inner:_add_event_listener('ui.activate', function()
        push_log(screen.log, 'inner target')

        if screen.fail_next_tap then
            screen.fail_next_tap = false
            error('phase4 guarded listener boom', 0)
        end
    end, 'bubble')
    middle:_add_event_listener('ui.activate', function(event)
        push_log(screen.log, 'middle bubble')

        if screen.stop_middle_bubble then
            event:stopPropagation()
            push_log(screen.log, 'middle bubble called stopPropagation()')
        end
    end, 'bubble')
    outer:_add_event_listener('ui.activate', function()
        push_log(screen.log, 'outer bubble')
    end, 'bubble')

    function screen:footer_controls_rects(rect)
        return {
            stop = {
                x = rect.x + 16,
                y = rect.y + 106,
                width = 320,
                height = 28,
            },
            guard = {
                x = rect.x + 364,
                y = rect.y + 98,
                width = 236,
                height = 42,
            },
        }
    end

    function screen:draw_footer_controls(rect)
        local controls = self:footer_controls_rects(rect)
        draw_checkbox(
            controls.stop,
            'Stop at Middle bubble',
            self.stop_middle_bubble
        )
        draw_button(
            controls.guard,
            self.fail_next_tap and 'Guard Armed' or 'Guard Next Inner Tap',
            self.fail_next_tap
        )
    end

    function screen:on_dispatch_error(_, err)
        push_log(self.log, 'caught error: ' .. tostring(err))
        local inner_bounds = self.inner:getWorldBounds()
        local probe_x = inner_bounds.x + inner_bounds.width * 0.5
        local probe_y = inner_bounds.y + inner_bounds.height * 0.5
        local target = self.stage:resolveTarget(probe_x, probe_y)

        push_log(self.log, 'post-error target probe: ' .. node_label(target))
    end

    function screen:mousepressed(x, y, button)
        if button ~= 1 then
            return
        end

        local controls = self:footer_controls_rects(
            footer_rect(love.graphics.getWidth(), love.graphics.getHeight())
        )

        if point_in_rect(x, y, controls.stop) then
            self.stop_middle_bubble = not self.stop_middle_bubble
            return
        end

        if point_in_rect(x, y, controls.guard) then
            self.fail_next_tap = not self.fail_next_tap
            push_log(
                self.log,
                self.fail_next_tap and 'guard armed for next tap' or
                    'guard disarmed'
            )
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousepressed',
            x = x,
            y = y,
            button = button,
        }, self.fail_next_tap)
    end

    function screen:mousereleased(x, y, button)
        if button ~= 1 then
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousereleased',
            x = x,
            y = y,
            button = button,
        }, self.fail_next_tap)
    end

    sync_stage(stage)

    return screen
end

local function make_prevent_default_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local shell = new_box('Shell', {
        tag = 'shell',
        x = demo.x + 84,
        y = demo.y + 110,
        width = demo.width * 0.52,
        height = demo.height * 0.52,
    }, colors.slate_fill, colors.slate)
    local target = new_box('Color Changer', {
        tag = 'color-changer',
        interactive = true,
        x = 46,
        y = 54,
        width = shell.width - 92,
        height = shell.height - 108,
    }, colors.success_fill, colors.success)

    local screen = {
        title = 'preventDefault',
        summary = 'The listeners still run through the full propagation path, but the target default action only flips color when preventDefault() has not been called.',
        instructions = {
            'Click the Color Changer to dispatch ui.activate.',
            'Toggle "Prevent default" to block only the default action, not propagation.',
            'The log shows capture, target, bubble, and default-action entries separately.',
        },
        stage = stage,
        log = {},
        prevent_default = false,
        shell = shell,
        target = target,
        color_state = 1,
    }

    stage.baseSceneLayer:addChild(shell)
    shell:addChild(target)

    local fills = {
        { fill = colors.success_fill, line = colors.success },
        { fill = colors.violet_fill, line = colors.violet },
    }

    local function apply_target_palette(index)
        screen.color_state = index
        screen.target.demo.fill = fills[index].fill
        screen.target.demo.line = fills[index].line
    end

    apply_target_palette(1)

    shell:_add_event_listener('ui.activate', function()
        push_log(screen.log, 'shell capture')
    end, 'capture')
    target:_add_event_listener('ui.activate', function()
        push_log(screen.log, 'target capture')
    end, 'capture')
    target:_add_event_listener('ui.activate', function(event)
        push_log(screen.log, 'target bubble')

        if screen.prevent_default then
            event:preventDefault()
            push_log(screen.log, 'target bubble called preventDefault()')
        end
    end, 'bubble')
    shell:_add_event_listener('ui.activate', function()
        push_log(screen.log, 'shell bubble')
    end, 'bubble')
    target:_set_event_default_action('ui.activate', function()
        local next_state = screen.color_state == 1 and 2 or 1
        apply_target_palette(next_state)
        push_log(screen.log, 'default action: color flipped')
    end)

    function screen:footer_controls_rects(rect)
        return {
            prevent = {
                x = rect.x + 16,
                y = rect.y + 104,
                width = 280,
                height = 28,
            },
        }
    end

    function screen:draw_footer_controls(rect)
        local controls = self:footer_controls_rects(rect)
        draw_checkbox(controls.prevent, 'Prevent default', self.prevent_default)
    end

    function screen:mousepressed(x, y, button)
        if button ~= 1 then
            return
        end

        local controls = self:footer_controls_rects(
            footer_rect(love.graphics.getWidth(), love.graphics.getHeight())
        )

        if point_in_rect(x, y, controls.prevent) then
            self.prevent_default = not self.prevent_default
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousepressed',
            x = x,
            y = y,
            button = button,
        }, false)
    end

    function screen:mousereleased(x, y, button)
        if button ~= 1 then
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousereleased',
            x = x,
            y = y,
            button = button,
        }, false)
    end

    sync_stage(stage)

    return screen
end

local function make_overlay_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local base_y = demo.y + demo.height * 0.42
    local box_width = 140
    local box_height = 120
    local gap = 66
    local start_x = demo.x + 46

    local base_left = new_box('Base A', {
        tag = 'base-a',
        interactive = true,
        x = start_x,
        y = base_y,
        width = box_width,
        height = box_height,
    }, colors.blue_fill, colors.blue)
    local base_mid = new_box('Base B', {
        tag = 'base-b',
        interactive = true,
        x = start_x + box_width + gap,
        y = base_y,
        width = box_width,
        height = box_height,
    }, colors.cyan_fill, colors.cyan)
    local base_right = new_box('Base C', {
        tag = 'base-c',
        interactive = true,
        x = start_x + (box_width + gap) * 2,
        y = base_y,
        width = box_width,
        height = box_height,
    }, colors.violet_fill, colors.violet)

    local overlay_left = new_box('Overlay L', {
        tag = 'overlay-left',
        interactive = true,
        x = base_left.x + 64,
        y = base_left.y - 48,
        width = 156,
        height = 96,
    }, colors.gold_fill, colors.gold)
    local overlay_right = new_box('Overlay R', {
        tag = 'overlay-right',
        interactive = true,
        x = base_right.x - 82,
        y = base_right.y + 52,
        width = 156,
        height = 96,
    }, colors.danger_fill, colors.danger)

    local screen = {
        title = 'Overlay Precedence',
        summary = 'Spatial targeting prefers the active overlay layer before the base scene layer. Toggling overlay visibility exposes the base targets in the same overlap regions.',
        instructions = {
            'Click the overlap regions to confirm overlay targets win over base-scene targets.',
            'Press H to toggle overlay visibility; hidden overlays stop participating in hit testing.',
            'The same overlap region should resolve to the base node once the overlay is hidden.',
        },
        stage = stage,
        log = {},
        overlay_visible = true,
        base_nodes = { base_left, base_mid, base_right },
        overlay_nodes = { overlay_left, overlay_right },
    }

    stage.baseSceneLayer:addChild(base_left)
    stage.baseSceneLayer:addChild(base_mid)
    stage.baseSceneLayer:addChild(base_right)
    stage.overlayLayer:addChild(overlay_left)
    stage.overlayLayer:addChild(overlay_right)

    local function attach_activation_log(node)
        node:_add_event_listener('ui.activate', function(event)
            push_log(
                screen.log,
                string.format(
                    'target %s via %s',
                    node_label(event.target),
                    node_label(event.currentTarget)
                )
            )
        end, 'bubble')
    end

    for index = 1, #screen.base_nodes do
        attach_activation_log(screen.base_nodes[index])
    end

    for index = 1, #screen.overlay_nodes do
        attach_activation_log(screen.overlay_nodes[index])
    end

    function screen:set_overlay_visible(visible)
        self.overlay_visible = visible

        for index = 1, #self.overlay_nodes do
            self.overlay_nodes[index].visible = visible
        end

        sync_stage(self.stage)
        push_log(
            self.log,
            visible and 'overlay visible=true' or 'overlay visible=false'
        )
    end

    function screen:after_delivery(_, delivery)
        if delivery.event == nil then
            push_log(
                self.log,
                'no dispatch, target=' .. node_label(delivery.target)
            )
        end
    end

    function screen:keypressed(key)
        if key == 'h' then
            self:set_overlay_visible(not self.overlay_visible)
        end
    end

    function screen:mousepressed(x, y, button)
        if button ~= 1 then
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousepressed',
            x = x,
            y = y,
            button = button,
        }, false)
    end

    function screen:mousereleased(x, y, button)
        if button ~= 1 then
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousereleased',
            x = x,
            y = y,
            button = button,
        }, false)
    end

    sync_stage(stage)

    return screen
end

local function make_z_order_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local origin_x = demo.x + demo.width * 0.34
    local origin_y = demo.y + demo.height * 0.34
    local base_size = 220

    local node_specs = {
        { tag = 'stack-1', label = 'z=1', fill = colors.blue_fill, line = colors.blue, z = 1 },
        { tag = 'stack-2', label = 'z=2', fill = colors.cyan_fill, line = colors.cyan, z = 2 },
        { tag = 'stack-3', label = 'z=3', fill = colors.violet_fill, line = colors.violet, z = 3 },
        { tag = 'stack-4', label = 'z=4', fill = colors.gold_fill, line = colors.gold, z = 4 },
    }
    local nodes = {}

    local screen = {
        title = 'Hit Test Z-Order',
        summary = 'Sibling hit testing follows reverse draw order. The highest zIndex wins until a number key lowers that node to the bottom of the stack.',
        instructions = {
            'Click the stack to log the resolved target and its current zIndex.',
            'Press keys 1-4 to lower that node to zIndex 0 and renormalize the others above it.',
            'Equal-size overlap keeps target selection stable while z-order changes.',
        },
        stage = stage,
        log = {},
        nodes = nodes,
    }

    for index = 1, #node_specs do
        local spec = node_specs[index]
        local node = new_box(spec.label, {
            tag = spec.tag,
            interactive = true,
            x = origin_x + (index - 1) * 14,
            y = origin_y + (index - 1) * 10,
            width = base_size,
            height = base_size,
            zIndex = spec.z,
        }, spec.fill, spec.line)

        stage.baseSceneLayer:addChild(node)
        nodes[index] = node

        node:_add_event_listener('ui.activate', function(event)
            push_log(
                screen.log,
                string.format(
                    'target %s z=%d',
                    node_label(event.target),
                    event.target.zIndex
                )
            )
        end, 'bubble')
    end

    function screen:lower_to_bottom(index)
        local chosen = self.nodes[index]

        if chosen == nil then
            return
        end

        local ordering = {}

        for node_index = 1, #self.nodes do
            if node_index ~= index then
                ordering[#ordering + 1] = self.nodes[node_index]
            end
        end

        table.sort(ordering, function(a, b)
            if a.zIndex == b.zIndex then
                return tostring(a.tag) < tostring(b.tag)
            end

            return a.zIndex < b.zIndex
        end)

        chosen.zIndex = 0

        for order_index = 1, #ordering do
            ordering[order_index].zIndex = order_index
        end

        push_log(self.log, string.format('moved %s to z=0', chosen.tag))
        sync_stage(self.stage)
    end

    function screen:keypressed(key)
        local index = tonumber(key)

        if index ~= nil then
            self:lower_to_bottom(index)
        end
    end

    function screen:mousepressed(x, y, button)
        if button ~= 1 then
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousepressed',
            x = x,
            y = y,
            button = button,
        }, false)
    end

    function screen:mousereleased(x, y, button)
        if button ~= 1 then
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousereleased',
            x = x,
            y = y,
            button = button,
        }, false)
    end

    function screen:draw_overlay(demo_rect)
        local info = {
            x = demo_rect.x + demo_rect.width - 232,
            y = demo_rect.y + 78,
            width = 214,
            height = 132,
        }
        local lines = {}

        for index = 1, #self.nodes do
            lines[#lines + 1] = string.format(
                '%d: %s => z=%d',
                index,
                self.nodes[index].tag,
                self.nodes[index].zIndex
            )
        end

        draw_panel_text(info, 'Current zIndex', lines)
    end

    sync_stage(stage)

    return screen
end

local function make_navigate_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local target = new_box('Focus Anchor', {
        tag = 'focus-anchor',
        interactive = true,
        x = demo.x + demo.width * 0.32,
        y = demo.y + demo.height * 0.34,
        width = 240,
        height = 140,
    }, colors.accent_fill, colors.accent)

    local screen = {
        title = 'Navigate And Dismiss',
        summary = 'A Phase 4-local focus anchor seeds the focused target without naming a spec-backed imperative focus helper. Navigate and dismiss events then route through ordinary Stage dispatch.',
        instructions = {
            'Arrow keys and Tab route ui.navigate to the seeded focus anchor.',
            'Escape routes ui.dismiss. Its default action hides the anchor and clears the local focus seed.',
            'Use the Reopen button to restore visibility and reseed the same internal focus fixture.',
        },
        stage = stage,
        log = {},
        target = target,
    }

    stage.baseSceneLayer:addChild(target)

    target:_add_event_listener('ui.navigate', function(event)
        push_log(
            screen.log,
            string.format(
                'navigate %s mode=%s target=%s',
                tostring(event.direction),
                tostring(event.navigationMode),
                node_label(event.target)
            )
        )
    end, 'bubble')
    target:_add_event_listener('ui.dismiss', function(event)
        push_log(
            screen.log,
            'dismiss target=' .. node_label(event.target)
        )
    end, 'bubble')
    target:_set_event_default_action('ui.dismiss', function()
        screen.target.visible = false
        seed_focus(screen.stage, nil)
        push_log(screen.log, 'default action: anchor hidden')
    end)

    function screen:reopen()
        self.target.visible = true
        seed_focus(self.stage, self.target)
        sync_stage(self.stage)
        push_log(self.log, 'reopened and re-seeded local focus anchor')
    end

    function screen:footer_controls_rects(rect)
        return {
            reopen = {
                x = rect.x + 16,
                y = rect.y + 98,
                width = 174,
                height = 42,
            },
        }
    end

    function screen:draw_footer_controls(rect)
        local controls = self:footer_controls_rects(rect)
        draw_button(controls.reopen, 'Reopen', true)
    end

    function screen:keypressed(key)
        if key == 'escape' or key == 'tab' or key == 'up' or key == 'down' or
            key == 'left' or key == 'right' then
            dispatch_stage_input(self, {
                kind = 'keypressed',
                key = key,
                shift = love.keyboard.isDown('lshift', 'rshift'),
            }, false)
        end
    end

    function screen:mousepressed(x, y, button)
        if button ~= 1 then
            return
        end

        local controls = self:footer_controls_rects(
            footer_rect(love.graphics.getWidth(), love.graphics.getHeight())
        )

        if point_in_rect(x, y, controls.reopen) then
            self:reopen()
        end
    end

    screen:reopen()

    return screen
end

local function make_scroll_drag_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local scroll_target = new_box('Scroll Target', {
        tag = 'scroll-target',
        interactive = true,
        x = demo.x + 48,
        y = demo.y + 142,
        width = demo.width * 0.36,
        height = 220,
    }, colors.blue_fill, colors.blue)
    local drag_target = new_box('Drag Target', {
        tag = 'drag-target',
        interactive = true,
        x = demo.x + demo.width * 0.60,
        y = demo.y + 164,
        width = 170,
        height = 120,
    }, colors.gold_fill, colors.gold)

    local screen = {
        title = 'Scroll And Drag',
        summary = 'Scroll events are spatially targeted by wheel position and drag events preserve gesture ownership after the threshold is crossed, including start, move, and end phases.',
        instructions = {
            'Use the mouse wheel over the left box to dispatch ui.scroll with normalized pixel deltas.',
            'Press and drag the right box past the internal 4px threshold to begin ui.drag delivery.',
            'The drag target moves using the drag event payload, while the log shows phase, origin, and cumulative delta.',
        },
        stage = stage,
        log = {},
        scroll_target = scroll_target,
        drag_target = drag_target,
        drag_origin_node_x = drag_target.x,
        drag_origin_node_y = drag_target.y,
    }

    stage.baseSceneLayer:addChild(scroll_target)
    stage.baseSceneLayer:addChild(drag_target)

    scroll_target:_add_event_listener('ui.scroll', function(event)
        push_log(
            screen.log,
            string.format(
                'scroll dx=%d dy=%d axis=%s',
                round(event.deltaX or 0),
                round(event.deltaY or 0),
                tostring(event.axis)
            )
        )
    end, 'bubble')
    drag_target:_add_event_listener('ui.drag', function(event)
        if event.dragPhase == 'start' then
            screen.drag_origin_node_x = screen.drag_target.x
            screen.drag_origin_node_y = screen.drag_target.y
        end

        screen.drag_target.x = screen.drag_origin_node_x + (event.deltaX or 0)
        screen.drag_target.y = screen.drag_origin_node_y + (event.deltaY or 0)

        push_log(
            screen.log,
            string.format(
                'drag %s origin=(%d,%d) delta=(%d,%d)',
                tostring(event.dragPhase),
                round(event.originX or 0),
                round(event.originY or 0),
                round(event.deltaX or 0),
                round(event.deltaY or 0)
            )
        )
    end, 'bubble')

    function screen:mousepressed(x, y, button)
        if button ~= 1 then
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousepressed',
            x = x,
            y = y,
            button = button,
        }, false)
    end

    function screen:mousereleased(x, y, button)
        if button ~= 1 then
            return
        end

        dispatch_stage_input(self, {
            kind = 'mousereleased',
            x = x,
            y = y,
            button = button,
        }, false)
    end

    function screen:mousemoved(x, y)
        dispatch_stage_input(self, {
            kind = 'mousemoved',
            x = x,
            y = y,
        }, false)
    end

    function screen:wheelmoved(dx, dy)
        local x, y = love.mouse.getPosition()

        dispatch_stage_input(self, {
            kind = 'wheelmoved',
            x = dx,
            y = dy,
            stageX = x,
            stageY = y,
        }, false)
    end

    function screen:after_delivery(raw_event, delivery)
        if raw_event.kind == 'wheelmoved' and delivery.event == nil then
            push_log(
                self.log,
                'wheel outside target, target=' .. node_label(delivery.target)
            )
        end
    end

    sync_stage(stage)

    return screen
end

local function destroy_current_screen()
    if current_screen ~= nil and current_screen.stage ~= nil then
        current_screen.stage:destroy()
    end

    current_screen = nil
end

local function rebuild_current_screen()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    destroy_current_screen()

    if current_index > #screen_builders then
        current_index = #screen_builders
    end

    if current_index < 1 then
        current_index = 1
    end

    current_screen = screen_builders[current_index](width, height)
end

local function switch_screen(next_index)
    if #screen_builders == 0 then
        return
    end

    if next_index < 1 then
        next_index = #screen_builders
    elseif next_index > #screen_builders then
        next_index = 1
    end

    current_index = next_index
    rebuild_current_screen()
end

local function maybe_handle_nav_click(x, y)
    local nav = nav_button_rects(love.graphics.getWidth())

    if point_in_rect(x, y, nav.prev) then
        switch_screen(current_index - 1)
        return true
    end

    if point_in_rect(x, y, nav.next) then
        switch_screen(current_index + 1)
        return true
    end

    return false
end

function love.load()
    love.graphics.setBackgroundColor(colors.background)

    TITLE_FONT = load_font('assets/fonts/DynaPuff-Regular.ttf', 24)
    BODY_FONT = load_font('assets/fonts/DynaPuff-Regular.ttf', 16)
    SMALL_FONT = load_font('assets/fonts/DynaPuff-Regular.ttf', 12)
    screen_builders = {
        make_capture_screen,
        make_prevent_default_screen,
        make_overlay_screen,
        make_z_order_screen,
        make_navigate_screen,
        make_scroll_drag_screen,
    }

    rebuild_current_screen()
end

function love.update(dt)
    if current_screen == nil then
        return
    end

    if current_screen.update ~= nil then
        current_screen:update(dt)
    end

    current_screen.stage:update(dt)
end

function love.draw()
    if current_screen == nil then
        return
    end

    draw_screen_frame(current_screen)
    draw_header(current_screen)
    draw_footer(current_screen)
end

function love.resize(_, _)
    rebuild_current_screen()
end

function love.keypressed(key)
    if key == '[' then
        switch_screen(current_index - 1)
        return
    end

    if key == ']' then
        switch_screen(current_index + 1)
        return
    end

    if key == 'r' then
        rebuild_current_screen()
        return
    end

    if current_screen ~= nil and current_screen.keypressed ~= nil then
        current_screen:keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if maybe_handle_nav_click(x, y) then
        return
    end

    if current_screen ~= nil and current_screen.mousepressed ~= nil then
        current_screen:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if current_screen ~= nil and current_screen.mousereleased ~= nil then
        current_screen:mousereleased(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if current_screen ~= nil and current_screen.mousemoved ~= nil then
        current_screen:mousemoved(x, y, dx, dy)
    end
end

function love.wheelmoved(dx, dy)
    if current_screen ~= nil and current_screen.wheelmoved ~= nil then
        current_screen:wheelmoved(dx, dy)
    end
end
