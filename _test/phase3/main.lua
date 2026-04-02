package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')

local Column = UI.Column
local Container = UI.Container
local Flow = UI.Flow
local Row = UI.Row
local SafeAreaContainer = UI.SafeAreaContainer
local Stack = UI.Stack
local Stage = UI.Stage

local floor = math.floor
local max = math.max
local min = math.min

local colors = {
    background = { 0.05, 0.06, 0.08, 1 },
    chrome = { 0.10, 0.12, 0.15, 0.98 },
    chrome_line = { 0.26, 0.31, 0.37, 1 },
    panel = { 0.11, 0.14, 0.18, 0.96 },
    panel_line = { 0.29, 0.35, 0.42, 1 },
    text = { 0.95, 0.97, 1.00, 1 },
    muted = { 0.70, 0.75, 0.82, 1 },
    accent = { 0.98, 0.74, 0.31, 1 },
    success_fill = { 0.23, 0.73, 0.44, 0.22 },
    success_line = { 0.52, 0.91, 0.67, 1 },
    danger_fill = { 0.87, 0.30, 0.29, 0.24 },
    danger_line = { 0.98, 0.57, 0.56, 1 },
    blue_fill = { 0.26, 0.48, 0.87, 0.22 },
    blue_line = { 0.49, 0.71, 1.00, 1 },
    cyan_fill = { 0.13, 0.68, 0.79, 0.22 },
    cyan_line = { 0.38, 0.90, 0.98, 1 },
    gold_fill = { 0.81, 0.63, 0.19, 0.22 },
    gold_line = { 0.96, 0.82, 0.39, 1 },
    violet_fill = { 0.57, 0.41, 0.83, 0.22 },
    violet_line = { 0.78, 0.63, 0.96, 1 },
    slate_fill = { 0.37, 0.44, 0.56, 0.22 },
    slate_line = { 0.62, 0.69, 0.81, 1 },
}

local HEADER_HEIGHT = 102
local FOOTER_HEIGHT = 142
local CONTENT_TOP = HEADER_HEIGHT + 24
local CONTENT_BOTTOM_MARGIN = FOOTER_HEIGHT + 28
local TITLE_FONT = nil
local BODY_FONT = nil
local SMALL_FONT = nil

local JUSTIFY_OPTIONS = {
    'start',
    'center',
    'end',
    'space-between',
    'space-around',
}

local ALIGN_OPTIONS = {
    'start',
    'center',
    'end',
    'stretch',
}

local screens = {}
local screen_states = {}
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

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function rgba(color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

local function point_in_rect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.width and
        y >= rect.y and y <= rect.y + rect.height
end

local function format_rect(rect)
    return string.format(
        'x=%d y=%d w=%d h=%d',
        round(rect.x),
        round(rect.y),
        round(rect.width),
        round(rect.height)
    )
end

local function format_size(node)
    local bounds = node:getLocalBounds()
    return string.format('%d x %d', round(bounds.width), round(bounds.height))
end

local function tail_lines(lines, limit)
    local count = #lines
    local start_index = max(1, count - limit + 1)
    local sliced = {}

    for index = start_index, count do
        sliced[#sliced + 1] = lines[index]
    end

    if #sliced == 0 then
        sliced[1] = '(empty)'
    end

    return sliced
end

local function push_log(lines, entry)
    lines[#lines + 1] = entry
end

local function active_orientation(viewport)
    if viewport.width >= viewport.height then
        return 'landscape'
    end

    return 'portrait'
end

local function new_stage(width, height)
    return Stage.new({
        width = width,
        height = height,
    })
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
    local node = Container.new(opts)
    return set_demo(node, label, fill, line)
end

local function snapshot_subtree(node, bounds_by_node)
    bounds_by_node[node] = node:getWorldBounds()

    local children = node:getChildren()

    for index = 1, #children do
        snapshot_subtree(children[index], bounds_by_node)
    end
end

local function snapshot_stage(stage)
    local bounds_by_node = {}

    snapshot_subtree(stage.baseSceneLayer, bounds_by_node)
    snapshot_subtree(stage.overlayLayer, bounds_by_node)

    return bounds_by_node
end

local function draw_demo_node(bounds, demo, is_hovered)
    if demo.fill ~= nil then
        rgba(demo.fill)
        love.graphics.rectangle(
            'fill',
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height,
            12,
            12
        )
    end

    if demo.line ~= nil then
        love.graphics.setLineWidth(is_hovered and 3 or 2)
        rgba(demo.line)
        love.graphics.rectangle(
            'line',
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height,
            12,
            12
        )
    end

    if demo.label ~= nil and bounds.width >= 44 and bounds.height >= 18 then
        rgba(colors.text)
        love.graphics.setFont(SMALL_FONT)
        love.graphics.printf(
            demo.label,
            bounds.x + 6,
            bounds.y + 6,
            max(0, bounds.width - 12),
            'left'
        )
    end
end

local function draw_header(screen)
    local width = love.graphics.getWidth()

    rgba(colors.chrome)
    love.graphics.rectangle('fill', 0, 0, width, HEADER_HEIGHT)
    rgba(colors.chrome_line)
    love.graphics.line(0, HEADER_HEIGHT, width, HEADER_HEIGHT)

    love.graphics.setFont(TITLE_FONT)
    rgba(colors.text)
    love.graphics.print(
        string.format(
            'Phase 3 Harness  %d/%d  %s',
            current_index,
            #screens,
            screen.title
        ),
        18,
        16
    )

    love.graphics.setFont(BODY_FONT)
    rgba(colors.muted)
    love.graphics.print(screen.spec, 18, 48)
    love.graphics.print(
        '[Left/Right] switch screen  [R] rebuild  [Esc] quit',
        18,
        72
    )
end

local function draw_footer(screen)
    local width = love.graphics.getWidth()
    local top = love.graphics.getHeight() - FOOTER_HEIGHT

    rgba(colors.chrome)
    love.graphics.rectangle('fill', 0, top, width, FOOTER_HEIGHT)
    rgba(colors.chrome_line)
    love.graphics.line(0, top, width, top)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.text)
    love.graphics.print('Screen Controls', 18, top + 12)

    rgba(colors.muted)

    for index = 1, #screen.help_lines do
        love.graphics.print(screen.help_lines[index], 18, top + 36 + ((index - 1) * 18))
    end
end

local function draw_panel(x, y, width, height, title, lines)
    rgba(colors.panel)
    love.graphics.rectangle('fill', x, y, width, height, 12, 12)
    rgba(colors.panel_line)
    love.graphics.rectangle('line', x, y, width, height, 12, 12)

    love.graphics.setFont(BODY_FONT)
    rgba(colors.text)
    love.graphics.print(title, x + 14, y + 12)

    love.graphics.setFont(SMALL_FONT)
    rgba(colors.muted)

    for index = 1, #lines do
        love.graphics.print(lines[index], x + 14, y + 38 + ((index - 1) * 16))
    end
end

local function build_stack_screen(state, width, height)
    state.preset = state.preset or 1

    local stage = new_stage(width, height)
    local left = set_demo(Stack.new({
        tag = 'left stack',
        x = 60,
        y = CONTENT_TOP + 24,
        width = 260,
        height = 260,
        padding = { 18, 18, 18, 18 },
        gap = 0,
        wrap = false,
        justify = 'start',
        align = 'start',
    }), 'stack', nil, colors.panel_line)
    local right = set_demo(Stack.new({
        tag = 'clipped stack',
        x = 360,
        y = CONTENT_TOP + 24,
        width = 260,
        height = 260,
        padding = { 18, 18, 18, 18 },
        gap = 0,
        wrap = false,
        justify = 'start',
        align = 'start',
        clipChildren = true,
    }), 'clipChildren', nil, colors.panel_line)
    local palette = {
        { fill = colors.blue_fill, line = colors.blue_line },
        { fill = colors.cyan_fill, line = colors.cyan_line },
        { fill = colors.gold_fill, line = colors.gold_line },
        { fill = colors.violet_fill, line = colors.violet_line },
    }
    local left_children = {}
    local right_children = {}
    local presets = {
        { 0, 1, 2, 3 },
        { 3, 0, 2, 1 },
        { 1, 3, 0, 2 },
        { 2, 1, 3, 0 },
    }
    local left_specs = {
        { tag = 'A', x = 0, y = 0, width = 120, height = 74 },
        { tag = 'B', x = 42, y = 36, width = 124, height = 80 },
        { tag = 'C', x = 94, y = 84, width = 118, height = 72 },
        { tag = 'D', x = 132, y = 130, width = 102, height = 84 },
    }
    local right_specs = {
        { tag = 'A', x = -26, y = 10, width = 116, height = 66 },
        { tag = 'B', x = 58, y = -18, width = 112, height = 82 },
        { tag = 'C', x = 126, y = 66, width = 124, height = 78 },
        { tag = 'D', x = 96, y = 164, width = 134, height = 84 },
    }

    for index = 1, #left_specs do
        local palette_entry = palette[index]
        local left_spec = left_specs[index]
        local right_spec = right_specs[index]
        local left_child = new_box(left_spec.tag, {
            tag = 'left ' .. left_spec.tag,
            interactive = true,
            x = left_spec.x,
            y = left_spec.y,
            width = left_spec.width,
            height = left_spec.height,
        }, palette_entry.fill, palette_entry.line)
        local right_child = new_box(right_spec.tag, {
            tag = 'right ' .. right_spec.tag,
            interactive = true,
            x = right_spec.x,
            y = right_spec.y,
            width = right_spec.width,
            height = right_spec.height,
        }, palette_entry.fill, palette_entry.line)

        left_children[index] = left_child
        right_children[index] = right_child

        left:addChild(left_child)
        right:addChild(right_child)
    end

    stage.baseSceneLayer:addChild(left)
    stage.baseSceneLayer:addChild(right)

    local screen = {
        title = 'Stack',
        spec = 'Spec anchors: ui-foundation-spec.md §6.2.4 Stack, §3G Failure Semantics',
        help_lines = {
            '[1-4] switch z-order preset',
            'Move the pointer across overlapping tiles to inspect reverse-draw hit targeting',
            'Left panel shows free overflow; right panel keeps the same children but clips draw + hit regions',
        },
        stage = stage,
        left = left,
        right = right,
        left_children = left_children,
        right_children = right_children,
        presets = presets,
        state = state,
    }

    function screen:apply_preset(index)
        self.state.preset = index

        local z_values = self.presets[index]

        for child_index = 1, #self.left_children do
            self.left_children[child_index].zIndex = z_values[child_index]
            self.right_children[child_index].zIndex = z_values[child_index]
        end
    end

    function screen:keypressed(key)
        local numeric = tonumber(key)

        if numeric ~= nil and numeric >= 1 and numeric <= #self.presets then
            self:apply_preset(numeric)
        end
    end

    function screen:prepare()
        local mouse_x, mouse_y = love.mouse.getPosition()
        local target = self.stage:resolveTarget(mouse_x, mouse_y)
        local snapshot = snapshot_stage(self.stage)
        local lines = {
            'Current preset: ' .. tostring(self.state.preset),
            'Hovered target: ' .. (target and target.tag or 'none'),
            'Stack does not impose a sequential axis; each child keeps its own x/y and anchor',
        }

        return {
            snapshot = snapshot,
            hovered = target,
            info_lines = lines,
        }
    end

    function screen:draw(frame)
        self.stage:draw(love.graphics, function(node)
            local demo = node.demo

            if demo == nil then
                return
            end

            draw_demo_node(frame.snapshot[node], demo, node == frame.hovered)
        end)

        local left_bounds = frame.snapshot[self.left]
        local right_bounds = frame.snapshot[self.right]

        draw_panel(
            650,
            CONTENT_TOP + 24,
            love.graphics.getWidth() - 674,
            152,
            'Behavior',
            frame.info_lines
        )
        draw_panel(
            650,
            CONTENT_TOP + 194,
            love.graphics.getWidth() - 674,
            116,
            'Observed Bounds',
            {
                'Left stack:  ' .. format_rect(left_bounds),
                'Right stack: ' .. format_rect(right_bounds),
                'The clipped panel uses the same public Stack contract with clipChildren = true',
            }
        )
    end

    screen:apply_preset(state.preset)
    stage:update(0)

    return screen
end

local function build_row_column_screen(state, width, height)
    state.justify_index = state.justify_index or 1
    state.align_index = state.align_index or 1
    state.gap = state.gap or 12
    state.wrap = state.wrap == nil and true or state.wrap
    state.direction = state.direction or 'ltr'

    local stage = new_stage(width, height)
    local panel_width = floor((width - 170) / 2)
    local row = set_demo(Row.new({
        tag = 'row demo',
        x = 60,
        y = CONTENT_TOP + 34,
        width = panel_width,
        height = 210,
        padding = { 16, 16, 16, 16 },
        gap = state.gap,
        wrap = state.wrap,
        justify = JUSTIFY_OPTIONS[state.justify_index],
        align = ALIGN_OPTIONS[state.align_index],
        direction = state.direction,
    }), 'Row', nil, colors.panel_line)
    local column = set_demo(Column.new({
        tag = 'column demo',
        x = width - panel_width - 60,
        y = CONTENT_TOP + 34,
        width = panel_width,
        height = 260,
        padding = { 16, 16, 16, 16 },
        gap = state.gap,
        wrap = state.wrap,
        justify = JUSTIFY_OPTIONS[state.justify_index],
        align = ALIGN_OPTIONS[state.align_index],
    }), 'Column', nil, colors.panel_line)
    local sizes = {
        { 60, 40, colors.blue_fill, colors.blue_line },
        { 92, 50, colors.cyan_fill, colors.cyan_line },
        { 74, 30, colors.gold_fill, colors.gold_line },
        { 104, 60, colors.violet_fill, colors.violet_line },
        { 58, 44, colors.slate_fill, colors.slate_line },
    }
    local row_children = {}
    local column_children = {}

    for index = 1, #sizes do
        local entry = sizes[index]
        local label = string.format('%dx%d', entry[1], entry[2])

        row_children[index] = new_box(label, {
            tag = 'row child ' .. index,
            width = entry[1],
            height = entry[2],
        }, entry[3], entry[4])
        column_children[index] = new_box(label, {
            tag = 'column child ' .. index,
            width = entry[1],
            height = entry[2],
        }, entry[3], entry[4])

        row:addChild(row_children[index])
        column:addChild(column_children[index])
    end

    stage.baseSceneLayer:addChild(row)
    stage.baseSceneLayer:addChild(column)

    local screen = {
        title = 'Row And Column',
        spec = 'Spec anchors: ui-foundation-spec.md §6.2.5 Row, §6.2.6 Column',
        help_lines = {
            '[1-5] justify  [Q/W/E/R] align start/center/end/stretch',
            '[+/-] gap  [T] wrap  [D] Row direction ltr/rtl',
            'This harness avoids fill-allocation claims because sibling fill policy is not spec-stabilized',
        },
        stage = stage,
        row = row,
        column = column,
        row_children = row_children,
        column_children = column_children,
        state = state,
    }

    function screen:apply_state()
        local justify = JUSTIFY_OPTIONS[self.state.justify_index]
        local align = ALIGN_OPTIONS[self.state.align_index]

        self.row.justify = justify
        self.column.justify = justify
        self.row.align = align
        self.column.align = align
        self.row.gap = self.state.gap
        self.column.gap = self.state.gap
        self.row.wrap = self.state.wrap
        self.column.wrap = self.state.wrap
        self.row.direction = self.state.direction
    end

    function screen:keypressed(key)
        local numeric = tonumber(key)

        if numeric ~= nil and numeric >= 1 and numeric <= #JUSTIFY_OPTIONS then
            self.state.justify_index = numeric
            self:apply_state()
            return
        end

        if key == 'q' then
            self.state.align_index = 1
        elseif key == 'w' then
            self.state.align_index = 2
        elseif key == 'e' then
            self.state.align_index = 3
        elseif key == 'r' then
            self.state.align_index = 4
        elseif key == '-' or key == 'kp-' then
            self.state.gap = max(0, self.state.gap - 2)
        elseif key == '=' or key == 'kp+' then
            self.state.gap = self.state.gap + 2
        elseif key == 't' then
            self.state.wrap = not self.state.wrap
        elseif key == 'd' then
            if self.state.direction == 'ltr' then
                self.state.direction = 'rtl'
            else
                self.state.direction = 'ltr'
            end
        else
            return
        end

        self:apply_state()
    end

    function screen:prepare()
        local snapshot = snapshot_stage(self.stage)
        local row_last = self.row_children[#self.row_children]
        local column_last = self.column_children[#self.column_children]

        return {
            snapshot = snapshot,
            row_lines = {
                'justify = ' .. self.row.justify,
                'align = ' .. self.row.align,
                'gap = ' .. tostring(self.row.gap) .. '  wrap = ' .. tostring(self.row.wrap),
                'direction = ' .. self.row.direction,
                'last child world origin = ' ..
                    format_rect(snapshot[row_last]),
            },
            column_lines = {
                'justify = ' .. self.column.justify,
                'align = ' .. self.column.align,
                'gap = ' .. tostring(self.column.gap) .. '  wrap = ' .. tostring(self.column.wrap),
                'first child local size = ' .. format_size(self.column_children[1]),
                'last child world origin = ' ..
                    format_rect(snapshot[column_last]),
            },
        }
    end

    function screen:draw(frame)
        self.stage:draw(love.graphics, function(node)
            local demo = node.demo

            if demo == nil then
                return
            end

            draw_demo_node(frame.snapshot[node], demo, false)
        end)

        draw_panel(60, CONTENT_TOP + 320, 300, 116, 'Row State', frame.row_lines)
        draw_panel(
            love.graphics.getWidth() - 360,
            CONTENT_TOP + 320,
            300,
            116,
            'Column State',
            frame.column_lines
        )
    end

    screen:apply_state()
    stage:update(0)

    return screen
end

local function build_flow_screen(state, width, height)
    state.gap = state.gap or 10
    state.wrap = state.wrap == nil and true or state.wrap
    state.frame_width = clamp(
        state.frame_width or floor(width * 0.52),
        180,
        width - 160
    )
    state.dragging = false

    local stage = new_stage(width, height)
    local frame = set_demo(Stack.new({
        tag = 'flow frame',
        x = 70,
        y = CONTENT_TOP + 34,
        width = state.frame_width,
        height = 308,
        padding = { 14, 14, 14, 14 },
        gap = 0,
        wrap = false,
        justify = 'start',
        align = 'start',
    }), 'Parent width', nil, colors.panel_line)
    local flow = set_demo(Flow.new({
        tag = 'flow demo',
        width = '100%',
        height = 'content',
        gap = state.gap,
        wrap = state.wrap,
        justify = 'start',
        align = 'center',
        padding = 0,
    }), 'Flow', nil, colors.slate_line)
    local sizes = {
        72, 124, 88, 96, 58, 132, 74, 102, 86, 116,
        66, 140, 78, 90, 108, 70, 120, 84, 64, 112,
    }

    for index = 1, #sizes do
        local fill
        local line

        if index % 4 == 1 then
            fill = colors.blue_fill
            line = colors.blue_line
        elseif index % 4 == 2 then
            fill = colors.cyan_fill
            line = colors.cyan_line
        elseif index % 4 == 3 then
            fill = colors.gold_fill
            line = colors.gold_line
        else
            fill = colors.violet_fill
            line = colors.violet_line
        end

        flow:addChild(new_box(tostring(index), {
            tag = 'tile ' .. index,
            width = sizes[index],
            height = 38 + ((index % 3) * 4),
        }, fill, line))
    end

    frame:addChild(flow)
    stage.baseSceneLayer:addChild(frame)

    local screen = {
        title = 'Flow',
        spec = 'Spec anchors: ui-foundation-spec.md §6.2.7 Flow, phase-03 compliance note on common gap prop',
        help_lines = {
            '[+/-] common gap  [W] wrap on/off',
            'Drag the bottom handle to resize the Flow parent width live',
            'This demo uses the common layout gap surface only; there is no public gapX/gapY contract',
        },
        stage = stage,
        frame = frame,
        flow = flow,
        state = state,
        handle_rect = nil,
    }

    function screen:apply_state()
        self.frame.width = self.state.frame_width
        self.flow.gap = self.state.gap
        self.flow.wrap = self.state.wrap
    end

    function screen:keypressed(key)
        if key == 'w' then
            self.state.wrap = not self.state.wrap
        elseif key == '-' or key == 'kp-' then
            self.state.gap = max(0, self.state.gap - 2)
        elseif key == '=' or key == 'kp+' then
            self.state.gap = self.state.gap + 2
        else
            return
        end

        self:apply_state()
    end

    function screen:update_drag(mouse_x)
        self.state.frame_width = clamp(mouse_x - self.frame.x, 180, love.graphics.getWidth() - 140)
        self:apply_state()
    end

    function screen:mousepressed(x, y, button)
        if button ~= 1 or self.handle_rect == nil then
            return
        end

        if point_in_rect(x, y, self.handle_rect) then
            self.state.dragging = true
            self:update_drag(x)
        end
    end

    function screen:mousereleased(_, _, button)
        if button == 1 then
            self.state.dragging = false
        end
    end

    function screen:mousemoved(x, _, _, _)
        if self.state.dragging then
            self:update_drag(x)
        end
    end

    function screen:prepare()
        local snapshot = snapshot_stage(self.stage)
        local frame_bounds = snapshot[self.frame]
        local track_y = frame_bounds.y + frame_bounds.height + 26

        self.handle_rect = {
            x = frame_bounds.x + frame_bounds.width - 18,
            y = track_y - 8,
            width = 36,
            height = 18,
        }

        return {
            snapshot = snapshot,
            frame_bounds = frame_bounds,
            track_y = track_y,
            info_lines = {
                'gap = ' .. tostring(self.flow.gap) ..
                    '  wrap = ' .. tostring(self.flow.wrap),
                'Parent width = ' .. tostring(round(frame_bounds.width)),
                'Flow bounds = ' .. format_rect(snapshot[self.flow]),
            },
        }
    end

    function screen:draw(frame)
        self.stage:draw(love.graphics, function(node)
            local demo = node.demo

            if demo == nil then
                return
            end

            draw_demo_node(frame.snapshot[node], demo, false)
        end)

        rgba(colors.panel_line)
        love.graphics.setLineWidth(2)
        love.graphics.line(
            self.frame.x,
            frame.track_y,
            love.graphics.getWidth() - 70,
            frame.track_y
        )

        rgba(colors.accent)
        love.graphics.rectangle(
            'fill',
            self.handle_rect.x,
            self.handle_rect.y,
            self.handle_rect.width,
            self.handle_rect.height,
            9,
            9
        )

        draw_panel(
            70,
            CONTENT_TOP + 372,
            320,
            100,
            'Flow State',
            frame.info_lines
        )
    end

    screen:apply_state()
    stage:update(0)

    return screen
end

local function draw_excluded_safe_area(container_bounds, content_bounds)
    if content_bounds.y > container_bounds.y then
        rgba(colors.danger_fill)
        love.graphics.rectangle(
            'fill',
            container_bounds.x,
            container_bounds.y,
            container_bounds.width,
            content_bounds.y - container_bounds.y
        )
    end

    if content_bounds.x > container_bounds.x then
        rgba(colors.danger_fill)
        love.graphics.rectangle(
            'fill',
            container_bounds.x,
            content_bounds.y,
            content_bounds.x - container_bounds.x,
            content_bounds.height
        )
    end

    local right_start = content_bounds.x + content_bounds.width
    local container_right = container_bounds.x + container_bounds.width

    if right_start < container_right then
        rgba(colors.danger_fill)
        love.graphics.rectangle(
            'fill',
            right_start,
            content_bounds.y,
            container_right - right_start,
            content_bounds.height
        )
    end

    local bottom_start = content_bounds.y + content_bounds.height
    local container_bottom = container_bounds.y + container_bounds.height

    if bottom_start < container_bottom then
        rgba(colors.danger_fill)
        love.graphics.rectangle(
            'fill',
            container_bounds.x,
            bottom_start,
            container_bounds.width,
            container_bottom - bottom_start
        )
    end
end

local function build_safe_area_screen(state, width, height)
    state.apply_top = state.apply_top == nil and true or state.apply_top
    state.apply_bottom = state.apply_bottom == nil and true or state.apply_bottom
    state.apply_left = state.apply_left == nil and true or state.apply_left
    state.apply_right = state.apply_right == nil and true or state.apply_right

    local stage = new_stage(width, height)
    local safe = set_demo(SafeAreaContainer.new({
        tag = 'safe area demo',
        x = 80,
        y = CONTENT_TOP + 24,
        width = width - 160,
        height = height - CONTENT_BOTTOM_MARGIN - CONTENT_TOP - 12,
        applyTop = state.apply_top,
        applyBottom = state.apply_bottom,
        applyLeft = state.apply_left,
        applyRight = state.apply_right,
        gap = 0,
        padding = 0,
        wrap = false,
        justify = 'start',
        align = 'start',
    }), 'SafeAreaContainer', nil, colors.panel_line)
    local content = new_box('content', {
        tag = 'safe content',
        width = '100%',
        height = '100%',
    }, colors.success_fill, colors.success_line)

    safe:addChild(content)
    stage.baseSceneLayer:addChild(safe)

    local screen = {
        title = 'Safe Area Container',
        spec = 'Spec anchors: ui-foundation-spec.md §6.2.8 SafeAreaContainer, §7.3 Responsive Rules',
        help_lines = {
            '[T/B/L/R] toggle applyTop/applyBottom/applyLeft/applyRight',
            'Green is the effective content region; red strips are the excluded edges',
            'Most desktop environments report zero safe-area insets; the contract is still bounds-based, not inset-API-based',
        },
        stage = stage,
        safe = safe,
        content = content,
        state = state,
    }

    function screen:apply_state()
        self.safe.applyTop = self.state.apply_top
        self.safe.applyBottom = self.state.apply_bottom
        self.safe.applyLeft = self.state.apply_left
        self.safe.applyRight = self.state.apply_right
    end

    function screen:keypressed(key)
        if key == 't' then
            self.state.apply_top = not self.state.apply_top
        elseif key == 'b' then
            self.state.apply_bottom = not self.state.apply_bottom
        elseif key == 'l' then
            self.state.apply_left = not self.state.apply_left
        elseif key == 'r' then
            self.state.apply_right = not self.state.apply_right
        else
            return
        end

        self:apply_state()
    end

    function screen:prepare()
        local snapshot = snapshot_stage(self.stage)
        local viewport = self.stage:getViewport()
        local safe_area_bounds = self.stage:getSafeAreaBounds()

        return {
            snapshot = snapshot,
            viewport = viewport,
            safe_area_bounds = safe_area_bounds,
            container_bounds = snapshot[self.safe],
            content_bounds = snapshot[self.content],
            info_lines = {
                'viewport = ' .. format_rect(viewport),
                'stage safe-area bounds = ' .. format_rect(safe_area_bounds),
                'content bounds = ' .. format_rect(snapshot[self.content]),
                string.format(
                    'apply flags: top=%s bottom=%s left=%s right=%s',
                    tostring(self.safe.applyTop),
                    tostring(self.safe.applyBottom),
                    tostring(self.safe.applyLeft),
                    tostring(self.safe.applyRight)
                ),
            },
        }
    end

    function screen:draw(frame)
        draw_excluded_safe_area(frame.container_bounds, frame.content_bounds)

        self.stage:draw(love.graphics, function(node)
            local demo = node.demo

            if demo == nil then
                return
            end

            draw_demo_node(frame.snapshot[node], demo, false)
        end)

        draw_panel(
            90,
            CONTENT_TOP + 36,
            360,
            116,
            'Safe-Area State',
            frame.info_lines
        )
    end

    screen:apply_state()
    stage:update(0)

    return screen
end

local function add_nested_flow(column, seed)
    local header = new_box('header', {
        tag = 'nested header ' .. seed,
        width = '100%',
        height = 24,
    }, colors.slate_fill, colors.slate_line)
    local flow = set_demo(Flow.new({
        tag = 'nested flow ' .. seed,
        width = '100%',
        height = 'content',
        gap = 4,
        wrap = true,
        justify = 'start',
        align = 'start',
        padding = 0,
    }), 'flow', nil, colors.slate_line)

    for index = 1, 8 do
        local width_offset = ((index + seed) % 3) * 14

        flow:addChild(new_box(tostring(index), {
            tag = 'nested tile ' .. seed .. '-' .. index,
            width = 34 + width_offset,
            height = 24,
        }, colors.blue_fill, colors.blue_line))
    end

    column:addChild(header)
    column:addChild(flow)
end

local function make_nested_column(tag, width_mode, seed)
    local column = set_demo(Column.new({
        tag = tag,
        width = width_mode,
        height = '100%',
        padding = { 8, 8, 8, 8 },
        gap = 8,
        wrap = false,
        justify = 'start',
        align = 'stretch',
    }), tag, nil, colors.panel_line)

    add_nested_flow(column, seed)

    return column
end

local function build_nested_screen(state, width, height)
    local stage = new_stage(width, height)
    local root = set_demo(Column.new({
        tag = 'nested root',
        x = 60,
        y = CONTENT_TOP + 24,
        width = width - 120,
        height = height - CONTENT_BOTTOM_MARGIN - CONTENT_TOP - 12,
        padding = { 16, 18, 22, 12 },
        gap = 14,
        wrap = false,
        justify = 'start',
        align = 'stretch',
    }), 'root Column', nil, colors.panel_line)
    local row1 = set_demo(Row.new({
        tag = 'row 33',
        width = '100%',
        height = 112,
        padding = 0,
        gap = 0,
        wrap = false,
        justify = 'start',
        align = 'stretch',
        direction = 'ltr',
    }), '33%', nil, colors.slate_line)
    local row2 = set_demo(Row.new({
        tag = 'row 50',
        width = '100%',
        height = 112,
        padding = 0,
        gap = 0,
        wrap = false,
        justify = 'start',
        align = 'stretch',
        direction = 'ltr',
    }), '50%', nil, colors.slate_line)
    local row3 = set_demo(Row.new({
        tag = 'row 100',
        width = '100%',
        height = 112,
        padding = 0,
        gap = 0,
        wrap = false,
        justify = 'start',
        align = 'stretch',
        direction = 'ltr',
    }), '100%', nil, colors.slate_line)

    local row1_columns = {
        make_nested_column('33%-A', '33%', 1),
        make_nested_column('33%-B', '33%', 2),
        make_nested_column('33%-C', '33%', 3),
    }
    local row2_columns = {
        make_nested_column('50%-A', '50%', 4),
        make_nested_column('50%-B', '50%', 5),
    }
    local row3_columns = {
        make_nested_column('100%-A', '100%', 6),
    }

    for index = 1, #row1_columns do
        row1:addChild(row1_columns[index])
    end

    for index = 1, #row2_columns do
        row2:addChild(row2_columns[index])
    end

    row3:addChild(row3_columns[1])
    root:addChild(row1)
    root:addChild(row2)
    root:addChild(row3)
    stage.baseSceneLayer:addChild(root)

    local screen = {
        title = 'Nested Layouts',
        spec = 'Spec anchors: ui-foundation-spec.md §6.2 Layout Family, §7.3 Responsive Rules',
        help_lines = {
            'Resize the window to reflow percentage widths across Column -> Row -> Column -> Flow nesting',
            'Percentages here resolve against the padded parent content region, not raw viewport width',
            'The screen uses explicit 33%, 50%, and 100% child widths to match the task scope',
        },
        stage = stage,
        root = root,
        row1_columns = row1_columns,
        row2_columns = row2_columns,
        row3_columns = row3_columns,
    }

    function screen:prepare()
        local snapshot = snapshot_stage(self.stage)

        return {
            snapshot = snapshot,
            lines = {
                'root content host = ' .. format_rect(snapshot[self.root]),
                '33% column width = ' .. tostring(round(snapshot[self.row1_columns[1]].width)),
                '50% column width = ' .. tostring(round(snapshot[self.row2_columns[1]].width)),
                '100% column width = ' .. tostring(round(snapshot[self.row3_columns[1]].width)),
            },
        }
    end

    function screen:draw(frame)
        self.stage:draw(love.graphics, function(node)
            local demo = node.demo

            if demo == nil then
                return
            end

            draw_demo_node(frame.snapshot[node], demo, false)
        end)

        draw_panel(
            74,
            CONTENT_TOP + 28,
            360,
            100,
            'Nested Metrics',
            frame.lines
        )
    end

    stage:update(0)

    return screen
end

local function responsive_rule_examples()
    return {
        {
            maxWidth = 960,
            props = {
                width = '100%',
                height = 62,
                x = 0,
                y = 24,
            },
        },
        {
            minWidth = 961,
            props = {
                width = '55%',
                height = 96,
                x = 24,
                y = 46,
            },
        },
    }
end

local function build_responsive_screen(state, width, height)
    state.logs = state.logs or {}

    local stage = new_stage(width, height)
    local root = set_demo(Column.new({
        tag = 'responsive root',
        x = 60,
        y = CONTENT_TOP + 26,
        width = width - 120,
        height = height - CONTENT_BOTTOM_MARGIN - CONTENT_TOP - 20,
        padding = { 12, 12, 12, 12 },
        gap = 16,
        wrap = false,
        justify = 'start',
        align = 'stretch',
    }), 'root', nil, colors.panel_line)
    local hosts = set_demo(Row.new({
        tag = 'responsive hosts',
        width = '100%',
        height = 190,
        padding = 0,
        gap = 18,
        wrap = false,
        justify = 'start',
        align = 'stretch',
        direction = 'ltr',
    }), 'entry points', nil, colors.slate_line)
    local breakpoint_host = set_demo(Stack.new({
        tag = 'breakpoint host',
        width = '50%',
        height = '100%',
        padding = { 12, 12, 12, 12 },
        gap = 0,
        wrap = false,
        justify = 'start',
        align = 'start',
    }), 'breakpoints', nil, colors.panel_line)
    local responsive_host = set_demo(Stack.new({
        tag = 'responsive host',
        width = '50%',
        height = '100%',
        padding = { 12, 12, 12, 12 },
        gap = 0,
        wrap = false,
        justify = 'start',
        align = 'start',
    }), 'responsive', nil, colors.panel_line)
    local breakpoint_card = new_box('breakpoints', {
        tag = 'breakpoint card',
        width = 150,
        height = 50,
        breakpoints = responsive_rule_examples(),
    }, colors.gold_fill, colors.gold_line)
    local responsive_card = new_box('responsive', {
        tag = 'responsive card',
        width = 150,
        height = 50,
        responsive = responsive_rule_examples(),
    }, colors.cyan_fill, colors.cyan_line)
    local parent_host = set_demo(Stack.new({
        tag = 'parent host',
        width = '100%',
        height = 150,
        padding = { 12, 12, 12, 12 },
        gap = 0,
        wrap = false,
        justify = 'start',
        align = 'start',
    }), 'parent-width responsive', nil, colors.panel_line)
    local parent_card = new_box('parent function', {
        tag = 'parent card',
        width = 90,
        height = 46,
        responsive = function(context)
            if context.parent.width >= 680 then
                return {
                    width = '50%',
                    x = 18,
                    y = 56,
                }, 'wide-parent'
            end

            return {
                width = '100%',
                x = 0,
                y = 18,
            }, 'narrow-parent'
        end,
    }, colors.blue_fill, colors.blue_line)

    breakpoint_host:addChild(breakpoint_card)
    responsive_host:addChild(responsive_card)
    hosts:addChild(breakpoint_host)
    hosts:addChild(responsive_host)
    parent_host:addChild(parent_card)
    root:addChild(hosts)
    root:addChild(parent_host)
    stage.baseSceneLayer:addChild(root)

    local screen = {
        title = 'Responsive And Failures',
        spec = 'Spec anchors: ui-foundation-spec.md §7.3 Responsive Rules, §3G Failure Semantics',
        help_lines = {
            '[E] demo dual-source responsive invalidity  [C] demo circular measurement failure  [X] clear log',
            'Resize the window to move the breakpoint and responsive cards together on the same pre-measure timing',
            'The rule table shape shown here is implementation-local; the spec stabilizes timing + dependency categories, not one schema',
        },
        stage = stage,
        root = root,
        breakpoint_host = breakpoint_host,
        responsive_host = responsive_host,
        breakpoint_card = breakpoint_card,
        responsive_card = responsive_card,
        parent_card = parent_card,
        state = state,
    }

    function screen:run_dual_source_demo()
        local ok, err = pcall(function()
            Row.new({
                width = 100,
                height = 40,
                breakpoints = responsive_rule_examples(),
                responsive = responsive_rule_examples(),
            })
        end)

        if ok then
            push_log(self.state.logs, 'dual-source demo: unexpected success')
            return
        end

        push_log(self.state.logs, 'dual-source demo: ' .. tostring(err))
    end

    function screen:run_cycle_demo()
        local probe = Row.new({
            width = 'content',
            height = 40,
            padding = 0,
            gap = 0,
            wrap = false,
            justify = 'start',
            align = 'start',
            direction = 'ltr',
        })

        probe:addChild(Container.new({
            width = 'fill',
            height = 20,
        }))
        self.root:addChild(probe)

        local ok, err = pcall(function()
            self.stage:update(0)
        end)

        self.root:removeChild(probe)
        probe:destroy()

        local recover_ok, recover_err = pcall(function()
            self.stage:update(0)
        end)

        if ok then
            push_log(self.state.logs, 'cycle demo: unexpected success')
        else
            push_log(self.state.logs, 'cycle demo: ' .. tostring(err))
        end

        if recover_ok then
            push_log(self.state.logs, 'recovery: harness remained usable after pcall')
        else
            push_log(self.state.logs, 'recovery: ' .. tostring(recover_err))
        end
    end

    function screen:keypressed(key)
        if key == 'e' then
            self:run_dual_source_demo()
        elseif key == 'c' then
            self:run_cycle_demo()
        elseif key == 'x' then
            self.state.logs = {}
        end
    end

    function screen:prepare()
        local snapshot = snapshot_stage(self.stage)
        local viewport = self.stage:getViewport()
        local logs = tail_lines(self.state.logs, 5)

        return {
            snapshot = snapshot,
            info_lines = {
                'viewport = ' .. format_rect(viewport),
                'orientation = ' .. active_orientation(viewport),
                'breakpoint card = ' .. format_rect(snapshot[self.breakpoint_card]),
                'responsive card = ' .. format_rect(snapshot[self.responsive_card]),
                'parent-width card = ' .. format_rect(snapshot[self.parent_card]),
            },
            logs = logs,
        }
    end

    function screen:draw(frame)
        self.stage:draw(love.graphics, function(node)
            local demo = node.demo

            if demo == nil then
                return
            end

            draw_demo_node(frame.snapshot[node], demo, false)
        end)

        draw_panel(
            74,
            CONTENT_TOP + 28,
            410,
            132,
            'Responsive State',
            frame.info_lines
        )
        draw_panel(
            74,
            CONTENT_TOP + 370,
            love.graphics.getWidth() - 148,
            124,
            'Failure Log',
            frame.logs
        )
    end

    stage:update(0)

    return screen
end

screens = {
    {
        create = build_stack_screen,
    },
    {
        create = build_row_column_screen,
    },
    {
        create = build_flow_screen,
    },
    {
        create = build_safe_area_screen,
    },
    {
        create = build_nested_screen,
    },
    {
        create = build_responsive_screen,
    },
}

local function destroy_screen(screen)
    if screen == nil then
        return
    end

    if screen.stage ~= nil then
        screen.stage:destroy()
    end
end

local function rebuild_current_screen()
    local definition = screens[current_index]
    local state = screen_states[current_index]

    if state == nil then
        state = {}
        screen_states[current_index] = state
    end

    destroy_screen(current_screen)
    current_screen = definition.create(
        state,
        love.graphics.getWidth(),
        love.graphics.getHeight()
    )
end

local function switch_screen(next_index)
    if next_index < 1 then
        next_index = #screens
    elseif next_index > #screens then
        next_index = 1
    end

    current_index = next_index
    rebuild_current_screen()
end

function love.load()
    love.graphics.setBackgroundColor(colors.background)

    TITLE_FONT = load_font('assets/fonts/DynaPuff-Regular.ttf', 24)
    BODY_FONT = load_font('assets/fonts/DynaPuff-Regular.ttf', 16)
    SMALL_FONT = load_font('assets/fonts/DynaPuff-Regular.ttf', 12)

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

    draw_header(current_screen)
    draw_footer(current_screen)

    local frame = current_screen:prepare()
    current_screen:draw(frame)
end

function love.resize(_, _)
    rebuild_current_screen()
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
        return
    end

    if key == 'left' then
        switch_screen(current_index - 1)
        return
    end

    if key == 'right' then
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
