package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')

local Container = UI.Container
local Drawable = UI.Drawable
local Stage = UI.Stage

local floor = math.floor
local max = math.max
local min = math.min

local HEADER_HEIGHT = 112
local FOOTER_HEIGHT = 180
local OUTER_MARGIN = 18
local CONTENT_GAP = 18
local LOG_WIDTH = 420
local LOG_LIMIT = 20

local TITLE_FONT = nil
local BODY_FONT = nil
local SMALL_FONT = nil

local colors = {
    background = { 0.05, 0.06, 0.08, 1 },
    background_soft = { 0.10, 0.11, 0.14, 0.40 },
    chrome = { 0.10, 0.12, 0.16, 0.98 },
    chrome_line = { 0.23, 0.30, 0.39, 1 },
    panel = { 0.10, 0.14, 0.18, 0.95 },
    panel_line = { 0.28, 0.36, 0.46, 1 },
    panel_soft = { 0.13, 0.17, 0.22, 0.94 },
    panel_warm = { 0.18, 0.17, 0.13, 0.94 },
    text = { 0.94, 0.97, 1.00, 1 },
    muted = { 0.68, 0.75, 0.83, 1 },
    accent = { 0.97, 0.79, 0.34, 1 },
    accent_fill = { 0.97, 0.79, 0.34, 0.16 },
    success = { 0.48, 0.90, 0.65, 1 },
    success_fill = { 0.20, 0.59, 0.39, 0.20 },
    danger = { 0.99, 0.55, 0.53, 1 },
    danger_fill = { 0.74, 0.27, 0.27, 0.22 },
    blue = { 0.42, 0.70, 1.00, 1 },
    blue_fill = { 0.22, 0.43, 0.82, 0.22 },
    cyan = { 0.39, 0.88, 0.97, 1 },
    cyan_fill = { 0.15, 0.58, 0.66, 0.22 },
    gold = { 0.96, 0.83, 0.40, 1 },
    gold_fill = { 0.74, 0.55, 0.15, 0.22 },
    slate = { 0.70, 0.75, 0.84, 1 },
    slate_fill = { 0.33, 0.39, 0.49, 0.22 },
    violet = { 0.82, 0.69, 0.98, 1 },
    violet_fill = { 0.50, 0.36, 0.77, 0.22 },
    overlay = { 0.03, 0.04, 0.06, 0.76 },
    focus = { 1.00, 0.95, 0.68, 1 },
}

local screen_builders = {}
local current_index = 1
local current_screen = nil
local forward_mouse_release_to_stage = false

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

    if #log > 140 then
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
    local content_height = max(220, footer_top - y)
    local content_width = width - OUTER_MARGIN * 2 - LOG_WIDTH - CONTENT_GAP

    return {
        x = x,
        y = y,
        width = max(360, content_width),
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
    local button_width = 128
    local button_height = 40
    local top = 34

    return {
        previous = {
            x = width - button_width * 2 - 26,
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

local function draw_rounded_panel(rect, fill, line, radius)
    radius = radius or 16

    rgba(fill)
    love.graphics.rectangle(
        'fill',
        rect.x,
        rect.y,
        rect.width,
        rect.height,
        radius,
        radius
    )

    if line ~= nil then
        rgba(line)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle(
            'line',
            rect.x,
            rect.y,
            rect.width,
            rect.height,
            radius,
            radius
        )
    end
end

local function draw_button(rect, label, accent)
    local fill = accent and colors.accent_fill or colors.panel_soft
    local line = accent and colors.accent or colors.panel_line

    draw_rounded_panel(rect, fill, line, 14)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.text)
    love.graphics.printf(
        label,
        rect.x,
        rect.y + 10,
        rect.width,
        'center'
    )
end

local function draw_panel_text(rect, title, lines, fill)
    draw_rounded_panel(rect, fill or colors.panel_soft, colors.panel_line, 14)

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

local function draw_background(width, height)
    rgba(colors.background)
    love.graphics.rectangle('fill', 0, 0, width, height)

    rgba(colors.background_soft)

    for index = 1, 6 do
        local size = 180 + index * 34
        local x = (index * 212) % width
        local y = 48 + index * 110

        love.graphics.circle('fill', x, y, size)
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

local function set_demo(node, label, fill, line, note)
    node.demo = {
        label = label,
        fill = fill,
        line = line,
        note = note,
        active = false,
        active_fill = colors.success_fill,
        active_line = colors.success,
    }

    return node
end

local function new_box(label, opts, fill, line, note)
    local node = Drawable.new(opts)
    return set_demo(node, label, fill, line, note)
end

local function draw_demo_node(node)
    local demo = rawget(node, 'demo')

    if demo == nil then
        return
    end

    local bounds = node:getWorldBounds()
    local fill = demo.active and demo.active_fill or demo.fill
    local line = demo.active and demo.active_line or demo.line

    if fill ~= nil then
        rgba(fill)
        love.graphics.rectangle(
            'fill',
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height,
            14,
            14
        )
    end

    if line ~= nil then
        rgba(line)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle(
            'line',
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height,
            14,
            14
        )
    end

    if demo.label ~= nil then
        love.graphics.setFont(BODY_FONT)
        rgba(colors.text)
        love.graphics.printf(
            demo.label,
            bounds.x + 10,
            bounds.y + max(14, bounds.height * 0.50 - 15),
            max(0, bounds.width - 20),
            'center'
        )
    end

    if demo.note ~= nil then
        love.graphics.setFont(SMALL_FONT)
        rgba(colors.muted)
        love.graphics.printf(
            demo.note,
            bounds.x + 8,
            bounds.y + bounds.height - 24,
            max(0, bounds.width - 16),
            'center'
        )
    end
end

local function active_focus_label(stage)
    return node_label(stage:_get_focus_owner_internal())
end

local function focus_chain_label(stage)
    local chain = stage:_get_active_focus_scope_chain_internal()
    local labels = {}

    for index = 1, #chain do
        labels[index] = node_label(chain[index])
    end

    return table.concat(labels, ' -> ')
end

local function set_pending_focus_source(screen, source)
    screen.pending_focus_source = source
end

local function with_focus_source(screen, source, action, catch_errors)
    local previous_source = screen.pending_focus_source
    set_pending_focus_source(screen, source)

    if catch_errors then
        local ok, result = pcall(action)
        set_pending_focus_source(screen, previous_source)
        return ok, result
    end

    local result = action()
    set_pending_focus_source(screen, previous_source)
    return true, result
end

local function dispatch_stage_input(screen, raw_event, source, catch_errors)
    local function run_delivery()
        local delivery = screen.stage:deliverInput(raw_event)
        sync_stage(screen.stage)
        return delivery
    end

    return with_focus_source(screen, source, function()
        if not catch_errors then
            return run_delivery()
        end

        local ok, result = pcall(run_delivery)

        if ok then
            return result
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

        return nil
    end, false)
end

local function attach_focus_log(screen, nodes)
    for index = 1, #nodes do
        nodes[index]:_add_event_listener('ui.focus.change', function(event)
            local source = screen.pending_focus_source or 'focus change'

            push_log(
                screen.log,
                string.format(
                    '%s: %s -> %s',
                    source,
                    node_label(event.previousTarget),
                    node_label(event.nextTarget)
                )
            )

            if screen.on_focus_change ~= nil then
                screen:on_focus_change(source, event)
            end
        end, 'bubble')
    end
end

local function replace_current_screen(index)
    if current_screen ~= nil and current_screen.stage ~= nil then
        current_screen.stage:destroy()
    end

    current_index = index
    current_screen = screen_builders[current_index](
        love.graphics.getWidth(),
        love.graphics.getHeight()
    )
    forward_mouse_release_to_stage = false
end

local function change_screen(delta)
    local next_index = current_index + delta

    if next_index < 1 then
        next_index = #screen_builders
    elseif next_index > #screen_builders then
        next_index = 1
    end

    replace_current_screen(next_index)
end

local function draw_header(screen)
    local width = love.graphics.getWidth()
    local nav = nav_button_rects(width)

    rgba(colors.chrome)
    love.graphics.rectangle('fill', 0, 0, width, HEADER_HEIGHT)
    rgba(colors.chrome_line)
    love.graphics.line(0, HEADER_HEIGHT, width, HEADER_HEIGHT)

    love.graphics.setFont(TITLE_FONT)
    rgba(colors.text)
    love.graphics.print('Phase 5 Focus Harness', OUTER_MARGIN, 26)

    love.graphics.setFont(SMALL_FONT)
    rgba(colors.accent)
    love.graphics.print(
        string.format('Screen %d / %d', current_index, #screen_builders),
        OUTER_MARGIN,
        66
    )
    rgba(colors.muted)
    love.graphics.print(screen.title, OUTER_MARGIN + 114, 66)
    love.graphics.print(screen.spec, OUTER_MARGIN, 86)

    draw_button(nav.previous, 'Prev  [', false)
    draw_button(nav.next, 'Next  ]', true)
end

local function draw_log_panel(rect, log_entries)
    draw_rounded_panel(rect, colors.panel, colors.panel_line)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.accent)
    love.graphics.print('Focus / Event Log', rect.x + 16, rect.y + 12)

    love.graphics.setFont(SMALL_FONT)
    local y = rect.y + 48

    for index = 1, #log_entries do
        rgba(index == #log_entries and colors.text or colors.muted)
        love.graphics.printf(
            log_entries[index],
            rect.x + 16,
            y,
            rect.width - 32,
            'left'
        )
        y = y + 18
    end
end

local function draw_footer(screen, rect)
    draw_rounded_panel(rect, colors.panel_warm, colors.panel_line)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.accent)
    love.graphics.print('Summary', rect.x + 16, rect.y + 12)

    love.graphics.setFont(SMALL_FONT)
    rgba(colors.text)
    love.graphics.printf(
        screen.summary,
        rect.x + 16,
        rect.y + 42,
        rect.width - 32,
        'left'
    )

    rgba(colors.muted)
    local y = rect.y + 100

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
end

local function draw_screen_frame(screen)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local demo = content_rect(width, height)
    local log = log_rect(width, height)
    local footer = footer_rect(width, height)

    draw_background(width, height)
    draw_header(screen)
    draw_rounded_panel(demo, colors.panel, colors.panel_line)

    screen.stage:draw(love.graphics, function(node)
        draw_demo_node(node)
    end)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.accent)
    love.graphics.print('Demo Area', demo.x + 16, demo.y + 12)

    love.graphics.setFont(SMALL_FONT)
    rgba(colors.muted)
    love.graphics.printf(
        screen.caption,
        demo.x + 16,
        demo.y + 40,
        demo.width - 32,
        'left'
    )

    if screen.draw_overlay ~= nil then
        screen:draw_overlay(demo, log, footer)
    end

    draw_log_panel(log, tail_entries(screen.log, LOG_LIMIT))
    draw_footer(screen, footer)
end

local function focus_index(nodes, owner)
    for index = 1, #nodes do
        if nodes[index] == owner then
            return index
        end
    end

    return 0
end

local function make_sequential_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local root = Container.new({
        tag = 'sequential-root',
        width = demo.width,
        height = demo.height,
    })
    local groups = {}
    local boxes = {}
    local labels = {
        'A1', 'A2',
        'B1', 'B2',
        'C1', 'C2',
        'D1', 'D2',
    }
    local group_width = 164
    local group_gap = 20
    local box_width = 142
    local box_height = 88
    local box_gap = 18
    local start_x = demo.x + 42
    local start_y = demo.y + 118

    for column = 1, 4 do
        local group = Container.new({
            tag = 'group-' .. tostring(column),
            x = start_x + (column - 1) * (group_width + group_gap),
            y = start_y,
            width = group_width,
            height = box_height * 2 + box_gap,
        })

        groups[#groups + 1] = group
        root:addChild(group)

        for row = 1, 2 do
            local index = (column - 1) * 2 + row
            local box = new_box(
                labels[index],
                {
                    tag = labels[index],
                    focusable = true,
                    x = 10,
                    y = (row - 1) * (box_height + box_gap),
                    width = box_width,
                    height = box_height,
                },
                colors.blue_fill,
                colors.blue,
                tostring(index)
            )

            boxes[#boxes + 1] = box
            group:addChild(box)
        end
    end

    stage.baseSceneLayer:addChild(root)
    sync_stage(stage)

    local screen = {
        title = 'Sequential Traversal',
        spec = 'Spec anchors: ui-foundation-spec.md §7.2.3 and §3D.4',
        caption = 'Depth-first pre-order traversal is visualized with four wrapper groups. The focus order follows tree order inside the active focus scope.',
        summary = 'This screen demonstrates the settled sequential traversal rule from the foundation spec. The harness uses only runtime keyboard delivery and does not present any public focus helper surface.',
        instructions = {
            'Tab moves to the next focusable drawable. Shift+Tab moves to the previous one.',
            'The order card shows the expected depth-first pre-order sequence for this subtree.',
            'R clears focus through an internal harness reset so the next Tab re-enters at A1.',
        },
        stage = stage,
        log = {},
        boxes = boxes,
    }

    attach_focus_log(screen, boxes)

    function screen:keypressed(key)
        if key == 'tab' then
            local source = love.keyboard.isDown('lshift', 'rshift') and
                'sequential previous' or
                'sequential next'

            dispatch_stage_input(self, {
                kind = 'keypressed',
                key = 'tab',
                shift = love.keyboard.isDown('lshift', 'rshift'),
            }, source, false)
        elseif key == 'r' then
            with_focus_source(self, 'sequential reset', function()
                self.stage:_request_focus_internal(nil)
                sync_stage(self.stage)
            end, false)
            push_log(self.log, 'sequential reset: focus cleared')
        end
    end

    function screen:draw_overlay(demo_rect)
        local owner = self.stage:_get_focus_owner_internal()
        local index = focus_index(self.boxes, owner)
        local info = {
            x = demo_rect.x + demo_rect.width - 280,
            y = demo_rect.y + 88,
            width = 248,
            height = 192,
        }

        draw_panel_text(info, 'Traversal Order', {
            'expected = A1 A2 B1 B2 C1 C2 D1 D2',
            'current focus = ' .. active_focus_label(self.stage),
            string.format('focus index = %d / %d', index, #self.boxes),
            'scope chain = ' .. focus_chain_label(self.stage),
            'order follows tree order, not a separate visual-order API.',
        })
    end

    return screen
end

local function make_directional_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local hub = new_box('Hub', {
        tag = 'hub',
        focusable = true,
        x = demo.x + 230,
        y = demo.y + 232,
        width = 160,
        height = 92,
    }, colors.gold_fill, colors.gold)
    local north = new_box('North', {
        tag = 'north',
        focusable = true,
        x = demo.x + 258,
        y = demo.y + 78,
        width = 136,
        height = 76,
    }, colors.violet_fill, colors.violet)
    local east_near = new_box('East Near', {
        tag = 'east-near',
        focusable = true,
        x = demo.x + 470,
        y = demo.y + 224,
        width = 150,
        height = 86,
    }, colors.cyan_fill, colors.cyan)
    local east_far = new_box('East Far', {
        tag = 'east-far',
        focusable = true,
        x = demo.x + 560,
        y = demo.y + 86,
        width = 150,
        height = 86,
    }, colors.blue_fill, colors.blue)
    local west = new_box('West', {
        tag = 'west',
        focusable = true,
        x = demo.x + 60,
        y = demo.y + 230,
        width = 142,
        height = 82,
    }, colors.slate_fill, colors.slate)
    local south = new_box('South', {
        tag = 'south',
        focusable = true,
        x = demo.x + 272,
        y = demo.y + 386,
        width = 136,
        height = 82,
    }, colors.success_fill, colors.success)

    stage.baseSceneLayer:addChild(hub)
    stage.baseSceneLayer:addChild(north)
    stage.baseSceneLayer:addChild(east_near)
    stage.baseSceneLayer:addChild(east_far)
    stage.baseSceneLayer:addChild(west)
    stage.baseSceneLayer:addChild(south)

    stage:_request_focus_internal(hub)
    sync_stage(stage)

    local screen = {
        title = 'Directional Traversal',
        spec = 'Spec anchors: ui-foundation-spec.md §7.2.4 and §3D.4',
        caption = 'Directional focus movement uses the nearest eligible candidate in the requested direction inside the active focus scope.',
        summary = 'This screen demonstrates directional acquisition without introducing any extra public API. The layout intentionally offers multiple right-side candidates so the nearest eligible one wins.',
        instructions = {
            'Arrow keys dispatch ui.navigate using directional mode.',
            'From Hub, Right should land on East Near instead of East Far because it is the nearer eligible candidate.',
            'R resets focus to Hub through an internal harness-only focus request.',
        },
        stage = stage,
        log = {},
        nodes = { hub, north, east_near, east_far, west, south },
        hub = hub,
    }

    attach_focus_log(screen, screen.nodes)

    function screen:keypressed(key)
        if key == 'up' or key == 'down' or key == 'left' or key == 'right' then
            dispatch_stage_input(self, {
                kind = 'keypressed',
                key = key,
            }, 'directional ' .. key, false)
        elseif key == 'r' then
            with_focus_source(self, 'directional reset', function()
                self.stage:_request_focus_internal(self.hub)
                sync_stage(self.stage)
            end, false)
        end
    end

    function screen:draw_overlay(demo_rect)
        local info = {
            x = demo_rect.x + demo_rect.width - 286,
            y = demo_rect.y + 88,
            width = 254,
            height = 192,
        }

        draw_panel_text(info, 'Nearest Candidate', {
            'current focus = ' .. active_focus_label(self.stage),
            'scope chain = ' .. focus_chain_label(self.stage),
            'Hub + Right => East Near',
            'Hub + Up => North',
            'Hub + Left => West',
            'Hub + Down => South',
        })
    end

    return screen
end

local function make_overlay_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local base_boxes = {}
    local overlay_boxes = {}
    local base_positions = {
        { 'scene-a', demo.x + 72, demo.y + 140 },
        { 'scene-b', demo.x + 276, demo.y + 140 },
        { 'scene-c', demo.x + 72, demo.y + 294 },
        { 'scene-d', demo.x + 276, demo.y + 294 },
    }

    for index = 1, #base_positions do
        local position = base_positions[index]
        local box = new_box(
            string.upper(position[1]),
            {
                tag = position[1],
                focusable = true,
                x = position[2],
                y = position[3],
                width = 160,
                height = 92,
            },
            colors.slate_fill,
            colors.slate
        )

        base_boxes[#base_boxes + 1] = box
        stage.baseSceneLayer:addChild(box)
    end

    local overlay = Container.new({
        tag = 'overlay-scope',
        visible = false,
        width = width,
        height = height,
    })
    local backdrop = new_box(nil, {
        tag = 'overlay-backdrop',
        interactive = true,
        width = width,
        height = height,
    }, colors.overlay, nil)
    local surface = new_box('Overlay Scope', {
        tag = 'overlay-surface',
        x = demo.x + 430,
        y = demo.y + 116,
        width = 310,
        height = 270,
    }, colors.panel_soft, colors.panel_line, 'trap active')
    local overlay_a = new_box('Overlay 1', {
        tag = 'overlay-1',
        focusable = true,
        x = 26,
        y = 74,
        width = 258,
        height = 62,
    }, colors.accent_fill, colors.accent)
    local overlay_b = new_box('Overlay 2', {
        tag = 'overlay-2',
        focusable = true,
        x = 26,
        y = 148,
        width = 258,
        height = 62,
    }, colors.blue_fill, colors.blue)
    local overlay_c = new_box('Overlay 3', {
        tag = 'overlay-3',
        focusable = true,
        x = 26,
        y = 222,
        width = 258,
        height = 62,
    }, colors.violet_fill, colors.violet)

    surface:addChild(overlay_a)
    surface:addChild(overlay_b)
    surface:addChild(overlay_c)
    overlay:addChild(backdrop)
    overlay:addChild(surface)

    stage.overlayLayer:addChild(overlay)
    stage:_set_focus_contract_internal(overlay, {
        scope = true,
        trap = true,
    })
    stage:_request_focus_internal(base_boxes[3])
    sync_stage(stage)

    local screen = {
        title = 'Overlay Restoration',
        spec = 'Spec anchors: ui-foundation-spec.md §7.2.5 and §3D.4',
        caption = 'The overlay subtree is a harness-owned runtime scope. It demonstrates trapping and restoration behavior without claiming a generic public trap prop.',
        summary = 'This screen focuses on overlay behavior only: opening records the previous owner, traversal is bounded to the overlay scope, and closing restores the prior eligible target.',
        instructions = {
            'O opens or closes the overlay scope. Escape closes it when open.',
            'While open, Tab and arrow keys stay inside the overlay subtree.',
            'Click the backdrop to confirm focus does not escape back to the scene content.',
        },
        stage = stage,
        log = {},
        overlay = overlay,
        backdrop = backdrop,
        base_boxes = base_boxes,
        overlay_boxes = { overlay_a, overlay_b, overlay_c },
        expected_restore_target = base_boxes[3],
    }

    backdrop:_add_event_listener('ui.activate', function()
        push_log(
            screen.log,
            'backdrop activate: focus stayed on ' .. active_focus_label(screen.stage)
        )
    end, 'bubble')

    attach_focus_log(screen, {
        base_boxes[1],
        base_boxes[2],
        base_boxes[3],
        base_boxes[4],
        overlay_a,
        overlay_b,
        overlay_c,
    })

    function screen:toggle_overlay(visible)
        if visible == self.overlay.visible then
            return
        end

        if visible then
            self.expected_restore_target = self.stage:_get_focus_owner_internal()
        end

        with_focus_source(self, visible and 'overlay open' or 'overlay restore', function()
            self.overlay.visible = visible
            sync_stage(self.stage)
        end, false)
    end

    function screen:keypressed(key)
        if key == 'o' then
            self:toggle_overlay(not self.overlay.visible)
        elseif key == 'escape' and self.overlay.visible then
            self:toggle_overlay(false)
        elseif key == 'tab' then
            local source = love.keyboard.isDown('lshift', 'rshift') and
                'overlay sequential previous' or
                'overlay sequential next'

            dispatch_stage_input(self, {
                kind = 'keypressed',
                key = 'tab',
                shift = love.keyboard.isDown('lshift', 'rshift'),
            }, source, false)
        elseif key == 'up' or key == 'down' or key == 'left' or key == 'right' then
            dispatch_stage_input(self, {
                kind = 'keypressed',
                key = key,
            }, 'overlay directional ' .. key, false)
        elseif key == 'r' and not self.overlay.visible then
            with_focus_source(self, 'overlay base reset', function()
                self.stage:_request_focus_internal(self.base_boxes[3])
                sync_stage(self.stage)
            end, false)
        end
    end

    function screen:mousepressed(x, y, button)
        if button ~= 1 then
            return false
        end

        dispatch_stage_input(self, {
            kind = 'mousepressed',
            x = x,
            y = y,
            button = button,
        }, 'overlay pointer press', false)

        return true
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
        }, 'overlay pointer release', false)
    end

    function screen:draw_overlay(demo_rect)
        local info = {
            x = demo_rect.x + demo_rect.width - 292,
            y = demo_rect.y + 88,
            width = 260,
            height = 214,
        }

        draw_panel_text(info, 'Trap State', {
            'overlay open = ' .. tostring(self.overlay.visible),
            'current focus = ' .. active_focus_label(self.stage),
            'restore target = ' .. node_label(self.expected_restore_target),
            'scope chain = ' .. focus_chain_label(self.stage),
            'backdrop clicks do not move focus into scene content.',
        })
    end

    return screen
end

local function make_pointer_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local screen = nil
    local boxes = {}
    local tags = {
        'top-1', 'top-2', 'top-3',
        'bottom-1', 'bottom-2', 'bottom-3',
    }
    local start_x = demo.x + 72
    local start_y = demo.y + 160
    local box_width = 176
    local box_height = 92
    local gap = 28

    for row = 1, 2 do
        for column = 1, 3 do
            local index = (row - 1) * 3 + column
            local coupled = row == 1
            local box = new_box(
                coupled and ('Coupled ' .. tostring(column)) or
                    ('Static ' .. tostring(column)),
                {
                    tag = tags[index],
                    interactive = true,
                    focusable = true,
                    x = start_x + (column - 1) * (box_width + gap),
                    y = start_y + (row - 1) * (box_height + 72),
                    width = box_width,
                    height = box_height,
                },
                coupled and colors.accent_fill or colors.slate_fill,
                coupled and colors.accent or colors.slate,
                coupled and 'focuses before action' or 'activation only'
            )

            stage.baseSceneLayer:addChild(box)
            boxes[#boxes + 1] = box

            if coupled then
                stage:_set_focus_contract_internal(box, {
                    pointerFocusCoupling = 'before',
                })
            else
                stage:_set_focus_contract_internal(box, {
                    pointerFocusCoupling = 'none',
                })
            end

            box:_set_event_default_action('ui.activate', function(event)
                local demo_state = rawget(box, 'demo')
                demo_state.active = not demo_state.active
                push_log(
                    screen.log,
                    string.format(
                        'activate %s focus_at_action=%s',
                        node_label(event.target),
                        active_focus_label(stage)
                    )
                )
            end)
        end
    end

    stage:_request_focus_internal(boxes[2])
    sync_stage(stage)

    screen = {
        title = 'Pointer / Focus Coupling',
        spec = 'Spec anchors: ui-foundation-spec.md §7.2.6 and ui-controls-spec.md §4D.2',
        caption = 'The top row models control contracts that focus before activation. The bottom row models contracts that activate without changing focus.',
        summary = 'Pointer-focus coupling is demonstrated here as control behavior, not as a generic foundation prop promise. The harness uses internal metadata only to encode those two contract shapes.',
        instructions = {
            'Click a top-row tile to move focus before its activate default action runs.',
            'Click a bottom-row tile to toggle it without moving the focus ring.',
            'Tab can still move focus by sequential traversal. R resets the focus ring to top-2.',
        },
        stage = stage,
        log = {},
        boxes = boxes,
    }

    attach_focus_log(screen, boxes)

    function screen:keypressed(key)
        if key == 'tab' then
            local source = love.keyboard.isDown('lshift', 'rshift') and
                'pointer sequential previous' or
                'pointer sequential next'

            dispatch_stage_input(self, {
                kind = 'keypressed',
                key = 'tab',
                shift = love.keyboard.isDown('lshift', 'rshift'),
            }, source, false)
        elseif key == 'r' then
            with_focus_source(self, 'pointer reset', function()
                self.stage:_request_focus_internal(self.boxes[2])
                sync_stage(self.stage)
            end, false)
        end
    end

    function screen:mousepressed(x, y, button)
        if button ~= 1 then
            return false
        end

        dispatch_stage_input(self, {
            kind = 'mousepressed',
            x = x,
            y = y,
            button = button,
        }, 'pointer press', false)

        return true
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
        }, 'pointer activate', false)
    end

    function screen:draw_overlay(demo_rect)
        local info = {
            x = demo_rect.x + demo_rect.width - 292,
            y = demo_rect.y + 88,
            width = 260,
            height = 192,
        }

        draw_panel_text(info, 'Contract Split', {
            'current focus = ' .. active_focus_label(self.stage),
            'top row => focus before default action',
            'bottom row => no focus change on pointer activation',
            'activated tiles hold their toggled fill until clicked again.',
        })
    end

    return screen
end

local function make_logging_screen(width, height)
    local stage = new_stage(width, height)
    local demo = content_rect(width, height)
    local hub = new_box('Hub', {
        tag = 'log-hub',
        focusable = true,
        x = demo.x + 264,
        y = demo.y + 218,
        width = 148,
        height = 86,
    }, colors.gold_fill, colors.gold)
    local left = new_box('Left', {
        tag = 'log-left',
        focusable = true,
        x = demo.x + 104,
        y = demo.y + 222,
        width = 136,
        height = 80,
    }, colors.slate_fill, colors.slate)
    local right = new_box('Right', {
        tag = 'log-right',
        focusable = true,
        x = demo.x + 436,
        y = demo.y + 222,
        width = 136,
        height = 80,
    }, colors.blue_fill, colors.blue)
    local north = new_box('North', {
        tag = 'log-north',
        focusable = true,
        x = demo.x + 278,
        y = demo.y + 100,
        width = 126,
        height = 72,
    }, colors.violet_fill, colors.violet)
    local explicit_target = new_box('Manual', {
        tag = 'log-manual',
        focusable = true,
        x = demo.x + 620,
        y = demo.y + 166,
        width = 150,
        height = 80,
    }, colors.accent_fill, colors.accent, 'internal focus probe')
    local pointer_target = new_box('Pointer', {
        tag = 'log-pointer',
        interactive = true,
        focusable = true,
        x = demo.x + 620,
        y = demo.y + 280,
        width = 150,
        height = 80,
    }, colors.cyan_fill, colors.cyan, 'focuses before action')
    local overlay = Container.new({
        tag = 'log-overlay-scope',
        visible = false,
        width = width,
        height = height,
    })
    local overlay_backdrop = new_box(nil, {
        tag = 'log-overlay-backdrop',
        interactive = true,
        width = width,
        height = height,
    }, colors.overlay, nil)
    local overlay_surface = new_box('Overlay Log Scope', {
        tag = 'log-overlay-surface',
        x = demo.x + 472,
        y = demo.y + 88,
        width = 280,
        height = 248,
    }, colors.panel_soft, colors.panel_line, 'open with O')
    local overlay_focus = new_box('Overlay Focus', {
        tag = 'log-overlay-focus',
        focusable = true,
        x = 24,
        y = 82,
        width = 232,
        height = 68,
    }, colors.success_fill, colors.success)
    local overlay_next = new_box('Overlay Next', {
        tag = 'log-overlay-next',
        focusable = true,
        x = 24,
        y = 164,
        width = 232,
        height = 68,
    }, colors.blue_fill, colors.blue)

    stage.baseSceneLayer:addChild(left)
    stage.baseSceneLayer:addChild(hub)
    stage.baseSceneLayer:addChild(right)
    stage.baseSceneLayer:addChild(north)
    stage.baseSceneLayer:addChild(explicit_target)
    stage.baseSceneLayer:addChild(pointer_target)

    overlay_surface:addChild(overlay_focus)
    overlay_surface:addChild(overlay_next)
    overlay:addChild(overlay_backdrop)
    overlay:addChild(overlay_surface)
    stage.overlayLayer:addChild(overlay)
    stage:_set_focus_contract_internal(pointer_target, {
        pointerFocusCoupling = 'before',
    })
    stage:_set_focus_contract_internal(overlay, {
        scope = true,
        trap = true,
    })

    stage:_request_focus_internal(hub)
    sync_stage(stage)

    local screen = {
        title = 'Focus Change Log',
        spec = 'Spec anchors: ui-foundation-spec.md §7.2, §7.2.5, and §3D.4',
        caption = 'This acceptance screen exercises the settled acquisition paths while keeping runtime helpers labeled as harness-only internals.',
        summary = 'The checklist below is the Phase 5 acceptance view: sequential, directional, pointer-coupled acquisition, explicit consumer-requested focus, overlay restoration, and guarded hard-failure recovery.',
        instructions = {
            'Tab = sequential. Arrow keys = directional. F = internal explicit focus request to Manual.',
            'Click Pointer to exercise pointer-coupled focus. O opens the overlay trap. Escape closes it.',
            'B resets focus to Hub. G runs a guarded failure probe with pcall and then verifies the harness still updates.',
        },
        stage = stage,
        log = {},
        overlay = overlay,
        hub = hub,
        explicit_target = explicit_target,
        pointer_target = pointer_target,
        observed = {
            sequential = false,
            directional = false,
            pointer = false,
            explicit = false,
            overlay = false,
            recovery = false,
        },
    }

    pointer_target:_set_event_default_action('ui.activate', function()
        local demo_state = rawget(pointer_target, 'demo')
        demo_state.active = not demo_state.active
        push_log(
            screen.log,
            'pointer default action: focus=' .. active_focus_label(stage)
        )
    end)

    overlay_backdrop:_add_event_listener('ui.activate', function()
        push_log(screen.log, 'overlay backdrop activate: focus unchanged')
    end, 'bubble')

    attach_focus_log(screen, {
        left,
        hub,
        right,
        north,
        explicit_target,
        pointer_target,
        overlay_focus,
        overlay_next,
    })

    function screen:on_focus_change(source, _)
        if source:find('sequential', 1, true) ~= nil then
            self.observed.sequential = true
        end

        if source:find('directional', 1, true) ~= nil then
            self.observed.directional = true
        end

        if source:find('pointer', 1, true) ~= nil then
            self.observed.pointer = true
        end

        if source:find('explicit', 1, true) ~= nil then
            self.observed.explicit = true
        end

        if source:find('overlay', 1, true) ~= nil then
            self.observed.overlay = true
        end
    end

    function screen:toggle_overlay(visible)
        if visible == self.overlay.visible then
            return
        end

        with_focus_source(self, visible and 'overlay open' or 'overlay restore', function()
            self.overlay.visible = visible
            sync_stage(self.stage)
        end, false)
    end

    function screen:run_failure_probe()
        local ok, err = pcall(function()
            self.stage:_set_focus_contract_internal(self.pointer_target, {
                pointerFocusCoupling = 'sideways',
            })
        end)

        if ok then
            push_log(self.log, 'guarded failure probe: unexpected success')
        else
            push_log(self.log, 'guarded failure probe: ' .. tostring(err))
        end

        local recover_ok, recover_err = pcall(function()
            sync_stage(self.stage)
        end)

        if recover_ok then
            self.observed.recovery = true
            push_log(self.log, 'recovery: harness remained usable after pcall')
        else
            push_log(self.log, 'recovery failed: ' .. tostring(recover_err))
        end
    end

    function screen:keypressed(key)
        if key == 'tab' then
            local source = love.keyboard.isDown('lshift', 'rshift') and
                'sequential previous' or
                'sequential next'

            dispatch_stage_input(self, {
                kind = 'keypressed',
                key = 'tab',
                shift = love.keyboard.isDown('lshift', 'rshift'),
            }, source, false)
        elseif key == 'up' or key == 'down' or key == 'left' or key == 'right' then
            dispatch_stage_input(self, {
                kind = 'keypressed',
                key = key,
            }, 'directional ' .. key, false)
        elseif key == 'f' then
            with_focus_source(self, 'explicit runtime request', function()
                self.stage:_request_focus_internal(self.explicit_target)
                sync_stage(self.stage)
            end, false)
        elseif key == 'o' then
            self:toggle_overlay(not self.overlay.visible)
        elseif key == 'escape' and self.overlay.visible then
            self:toggle_overlay(false)
        elseif key == 'b' then
            with_focus_source(self, 'explicit hub reset', function()
                self.stage:_request_focus_internal(self.hub)
                sync_stage(self.stage)
            end, false)
        elseif key == 'g' then
            self:run_failure_probe()
        end
    end

    function screen:mousepressed(x, y, button)
        if button ~= 1 then
            return false
        end

        dispatch_stage_input(self, {
            kind = 'mousepressed',
            x = x,
            y = y,
            button = button,
        }, 'pointer press', false)

        return true
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
        }, 'pointer activate', false)
    end

    function screen:draw_overlay(demo_rect)
        local acceptance = {
            x = demo_rect.x + 26,
            y = demo_rect.y + 88,
            width = 228,
            height = 206,
        }

        local function mark(value)
            if value then
                return 'yes'
            end

            return 'no'
        end

        draw_panel_text(acceptance, 'Acceptance Paths', {
            'sequential = ' .. mark(self.observed.sequential),
            'directional = ' .. mark(self.observed.directional),
            'pointer = ' .. mark(self.observed.pointer),
            'explicit request = ' .. mark(self.observed.explicit),
            'overlay restore = ' .. mark(self.observed.overlay),
            'pcall recovery = ' .. mark(self.observed.recovery),
        })

        local state = {
            x = demo_rect.x + demo_rect.width - 292,
            y = demo_rect.y + 88,
            width = 260,
            height = 206,
        }

        draw_panel_text(state, 'Current State', {
            'current focus = ' .. active_focus_label(self.stage),
            'overlay open = ' .. tostring(self.overlay.visible),
            'scope chain = ' .. focus_chain_label(self.stage),
            'Manual and Hub resets are internal harness probes only.',
        })
    end

    return screen
end

screen_builders = {
    make_sequential_screen,
    make_directional_screen,
    make_overlay_screen,
    make_pointer_screen,
    make_logging_screen,
}

function love.load()
    TITLE_FONT = load_font('assets/fonts/DynaPuff-Regular.ttf', 28)
    BODY_FONT = load_font('assets/fonts/DynaPuff-Regular.ttf', 16)
    SMALL_FONT = load_font('assets/fonts/DynaPuff-Regular.ttf', 12)

    replace_current_screen(1)
end

function love.update(dt)
    if current_screen ~= nil and current_screen.update ~= nil then
        current_screen:update(dt)
    end

    if current_screen ~= nil and current_screen.stage ~= nil then
        current_screen.stage:update(dt)
    end
end

function love.draw()
    if current_screen == nil then
        return
    end

    draw_screen_frame(current_screen)
end

function love.keypressed(key)
    if key == 'pageup' or key == '[' then
        change_screen(-1)
        return
    end

    if key == 'pagedown' or key == ']' then
        change_screen(1)
        return
    end

    if current_screen ~= nil and current_screen.keypressed ~= nil then
        current_screen:keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    local nav = nav_button_rects(love.graphics.getWidth())

    if point_in_rect(x, y, nav.previous) then
        change_screen(-1)
        return
    end

    if point_in_rect(x, y, nav.next) then
        change_screen(1)
        return
    end

    if current_screen ~= nil and current_screen.mousepressed ~= nil then
        forward_mouse_release_to_stage = current_screen:mousepressed(x, y, button) == true
    else
        forward_mouse_release_to_stage = false
    end
end

function love.mousereleased(x, y, button)
    if not forward_mouse_release_to_stage then
        return
    end

    forward_mouse_release_to_stage = false

    if current_screen ~= nil and current_screen.mousereleased ~= nil then
        current_screen:mousereleased(x, y, button)
    end
end

function love.resize(_, _)
    replace_current_screen(current_index)
end
