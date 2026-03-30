package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')

local Composer = UI.Composer
local Container = UI.Container
local Scene = UI.Scene

local floor = math.floor
local max = math.max
local colors = {
    background = { 0.07, 0.08, 0.10, 1 },
    header = { 0.11, 0.13, 0.16, 0.96 },
    panel = { 0.13, 0.15, 0.19, 0.95 },
    panel_line = { 0.30, 0.35, 0.42, 1 },
    text = { 0.93, 0.95, 0.98, 1 },
    muted = { 0.68, 0.73, 0.80, 1 },
    accent = { 0.97, 0.74, 0.34, 1 },
    success = { 0.46, 0.83, 0.59, 1 },
    danger = { 0.93, 0.42, 0.42, 1 },
    blue_fill = { 0.23, 0.46, 0.82, 0.24 },
    blue_line = { 0.44, 0.70, 1.00, 1 },
    cyan_fill = { 0.15, 0.72, 0.78, 0.24 },
    cyan_line = { 0.42, 0.93, 0.98, 1 },
    green_fill = { 0.25, 0.68, 0.41, 0.24 },
    green_line = { 0.49, 0.90, 0.63, 1 },
    gold_fill = { 0.77, 0.62, 0.21, 0.24 },
    gold_line = { 0.95, 0.81, 0.38, 1 },
    red_fill = { 0.83, 0.32, 0.32, 0.24 },
    red_line = { 0.98, 0.56, 0.56, 1 },
    purple_fill = { 0.55, 0.37, 0.79, 0.24 },
    purple_line = { 0.76, 0.60, 0.96, 1 },
}

local HEADER_HEIGHT = 88
local BUTTON_HEIGHT = 42
local LOG_LIMIT = 18

local screens = {}
local current_index = 1
local current_screen = nil

local function noop()
end

local function rgba(color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

local function round(value)
    return floor(value + 0.5)
end

local function label_of(node)
    if node == nil then
        return 'no target'
    end

    return node.tag or '<unnamed>'
end

local function join_path(path)
    if path == nil or #path == 0 then
        return 'none'
    end

    local labels = {}

    for index = 1, #path do
        labels[index] = label_of(path[index])
    end

    return table.concat(labels, ' -> ')
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

local function format_insets(insets)
    return string.format(
        'top=%d right=%d bottom=%d left=%d',
        round(insets.top),
        round(insets.right),
        round(insets.bottom),
        round(insets.left)
    )
end

local function append_log(log, entry)
    log[#log + 1] = entry
end

local function tail_lines(entries, limit)
    local count = #entries
    local start = max(1, count - limit + 1)
    local lines = {}

    for index = start, count do
        lines[#lines + 1] = entries[index]
    end

    if #lines == 0 then
        lines[1] = '(empty)'
    end

    return lines
end

local function point_in_rect(x, y, rect)
    return x >= rect.x and x <= rect.x + rect.width and
        y >= rect.y and y <= rect.y + rect.height
end

local function make_button(x, y, width, label, action, tone)
    return {
        x = x,
        y = y,
        width = width,
        height = BUTTON_HEIGHT,
        label = label,
        action = action,
        tone = tone or 'default',
    }
end

local function button_colors(tone)
    if tone == 'danger' then
        return colors.red_fill, colors.red_line
    end

    if tone == 'success' then
        return colors.green_fill, colors.green_line
    end

    if tone == 'accent' then
        return colors.gold_fill, colors.gold_line
    end

    return colors.blue_fill, colors.blue_line
end

local function draw_button(button)
    local fill, line = button_colors(button.tone)

    rgba(fill)
    love.graphics.rectangle(
        'fill',
        button.x,
        button.y,
        button.width,
        button.height,
        9,
        9
    )
    rgba(line)
    love.graphics.rectangle(
        'line',
        button.x,
        button.y,
        button.width,
        button.height,
        9,
        9
    )

    rgba(colors.text)
    love.graphics.printf(
        button.label,
        button.x,
        button.y + 12,
        button.width,
        'center'
    )
end

local function draw_panel(x, y, width, height, title, lines)
    rgba(colors.panel)
    love.graphics.rectangle('fill', x, y, width, height, 10, 10)
    rgba(colors.panel_line)
    love.graphics.rectangle('line', x, y, width, height, 10, 10)

    rgba(colors.text)
    love.graphics.print(title, x + 14, y + 12)

    rgba(colors.muted)
    local line_y = y + 34

    for index = 1, #lines do
        love.graphics.print(lines[index], x + 14, line_y)
        line_y = line_y + 18
    end
end

local function draw_header(screen)
    local width = love.graphics.getWidth()

    rgba(colors.header)
    love.graphics.rectangle('fill', 0, 0, width, HEADER_HEIGHT)
    rgba(colors.panel_line)
    love.graphics.line(0, HEADER_HEIGHT, width, HEADER_HEIGHT)

    rgba(colors.text)
    love.graphics.print(
        string.format(
            'Phase 2 Harness  %d/%d  %s',
            current_index,
            #screens,
            screen.title
        ),
        18,
        14
    )

    rgba(colors.muted)
    love.graphics.print(screen.spec, 18, 36)
    love.graphics.print(
        '[Left/Right] switch screen  [R] rebuild  [Esc] quit',
        18,
        58
    )
end

local function resolved_world_bounds(node)
    return rawget(node, '_world_bounds_cache')
end

local function resolved_probe(node, offset_x, offset_y)
    local bounds = resolved_world_bounds(node)

    return {
        x = bounds.x + offset_x,
        y = bounds.y + offset_y,
    }
end

local function draw_runtime_node(node)
    local bounds = resolved_world_bounds(node)

    if bounds == nil then
        return
    end

    local fill = rawget(node, 'demo_fill')
    local line = rawget(node, 'demo_line')
    local radius = rawget(node, 'demo_radius') or 12

    if fill ~= nil then
        rgba(fill)
        love.graphics.rectangle(
            'fill',
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height,
            radius,
            radius
        )
    end

    if line ~= nil then
        rgba(line)
        love.graphics.rectangle(
            'line',
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height,
            radius,
            radius
        )
    end

    local text = rawget(node, 'demo_text')

    if type(text) == 'function' then
        text = text(node)
    end

    if text ~= nil and text ~= '' then
        rgba(rawget(node, 'demo_text_color') or colors.text)
        love.graphics.printf(
            text,
            bounds.x + 18,
            bounds.y + (rawget(node, 'demo_text_offset_y') or 18),
            max(0, bounds.width - 36),
            rawget(node, 'demo_text_align') or 'left'
        )
    end
end

local function add_demo_box(parent, opts, fill, line, text)
    local node = Container.new(opts)
    node.demo_fill = fill
    node.demo_line = line
    node.demo_text = text
    parent:addChild(node)
    return node
end

local function composer_current_scene(composer)
    return rawget(composer, '_current_scene')
end

local function composer_current_scene_name(composer)
    return rawget(composer, '_current_scene_name')
end

local function count_forbidden_hooks(log)
    local forbidden = {}

    for index = 1, #log do
        local entry = log[index]

        if entry == 'B enter-after' or entry == 'B leave-before' or
            entry == 'B leave-after' then
            forbidden[#forbidden + 1] = entry
        end
    end

    return forbidden
end

local function build_scene_shell(scene, title, subtitle, background_fill, panel_fill)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    add_demo_box(scene, {
        tag = title .. ' background',
        width = 'fill',
        height = 'fill',
    }, background_fill, nil, nil)

    local card = add_demo_box(scene, {
        tag = title .. ' panel',
        x = 120,
        y = HEADER_HEIGHT + 86,
        width = max(360, width - 240),
        height = max(240, height - HEADER_HEIGHT - 220),
    }, panel_fill, colors.panel_line, function()
        return title .. '\n\n' .. subtitle()
    end)
    card.demo_text_align = 'center'
    card.demo_text_offset_y = 38
end

local function make_lifecycle_scene(name, background_fill, panel_fill, ctx)
    return function()
        local scene = Scene.new()

        function scene:onCreate()
            build_scene_shell(
                scene,
                'Scene ' .. name,
                function()
                    return 'Stable lifecycle demo scene.'
                end,
                background_fill,
                panel_fill
            )
        end

        function scene:onEnterBefore()
            append_log(ctx.log, name .. ' enter-before')
        end

        function scene:onEnterAfter()
            append_log(ctx.log, name .. ' enter-after')
        end

        function scene:onLeaveBefore()
            append_log(ctx.log, name .. ' leave-before')
        end

        function scene:onLeaveAfter()
            append_log(ctx.log, name .. ' leave-after')
        end

        return scene
    end
end

local function build_lifecycle_screen()
    local ctx = {
        composer = Composer.new(),
        log = {},
        buttons = {},
    }

    ctx.composer:register('A', make_lifecycle_scene(
        'A',
        colors.blue_fill,
        colors.blue_line,
        ctx
    ))
    ctx.composer:register('B', make_lifecycle_scene(
        'B',
        colors.green_fill,
        colors.green_line,
        ctx
    ))
    ctx.composer:register('C', make_lifecycle_scene(
        'C',
        colors.purple_fill,
        colors.purple_line,
        ctx
    ))

    ctx.composer:gotoScene('A', { duration = 0 })
    ctx.composer:update(0)

    local left = 26
    local top = HEADER_HEIGHT + 18
    local width = 190

    ctx.buttons = {
        make_button(left, top, width, 'Go A', function()
            ctx.composer:gotoScene('A', { duration = 0 })
        end, 'default'),
        make_button(left, top + 54, width, 'Go B', function()
            ctx.composer:gotoScene('B', { duration = 0 })
        end, 'default'),
        make_button(left, top + 108, width, 'Go C', function()
            ctx.composer:gotoScene('C', { duration = 0 })
        end, 'default'),
        make_button(left, top + 162, width, 'Clear Log', function()
            ctx.log = {}
        end, 'accent'),
    }

    return ctx
end

local function build_transition_screen()
    local ctx = {
        composer = Composer.new(),
        log = {},
        buttons = {},
    }

    local function make_scene(name, background_fill, panel_fill, note)
        return function()
            local scene = Scene.new()

            function scene:onCreate()
                build_scene_shell(
                    scene,
                    'Scene ' .. name,
                    function()
                        return note
                    end,
                    background_fill,
                    panel_fill
                )
            end

            function scene:onEnterBefore()
                append_log(ctx.log, name .. ' enter-before')
            end

            function scene:onEnterAfter()
                append_log(ctx.log, name .. ' enter-after')
            end

            function scene:onLeaveBefore()
                append_log(ctx.log, name .. ' leave-before')
            end

            function scene:onLeaveAfter()
                append_log(ctx.log, name .. ' leave-after')
            end

            return scene
        end
    end

    ctx.composer:register('A', make_scene(
        'A',
        colors.blue_fill,
        colors.blue_line,
        'Outgoing stable scene.'
    ))
    ctx.composer:register('B', make_scene(
        'B',
        colors.gold_fill,
        colors.gold_line,
        'Intermediate scene. It must not reach enter-after or any leave hook when interrupted.'
    ))
    ctx.composer:register('C', make_scene(
        'C',
        colors.green_fill,
        colors.green_line,
        'Final committed scene after interruption.'
    ))

    ctx.composer:gotoScene('A', { duration = 0 })
    ctx.composer:update(0)

    local left = 26
    local top = HEADER_HEIGHT + 18
    local width = 250

    ctx.buttons = {
        make_button(left, top, width, 'Go B (slow fade)', function()
            ctx.composer:gotoScene('B', {
                transition = 'fade',
                duration = 2,
            })
        end, 'default'),
        make_button(left, top + 54, width, 'Go C (interrupt)', function()
            ctx.composer:gotoScene('C', {
                transition = 'fade',
                duration = 0,
            })
        end, 'danger'),
        make_button(left, top + 108, width, 'Reset To A', function()
            ctx.log = {}
            ctx.composer:gotoScene('A', { duration = 0 })
        end, 'accent'),
        make_button(left, top + 162, width, 'Clear Log', function()
            ctx.log = {}
        end, 'success'),
    }

    return ctx
end

local function build_overlay_screen()
    local ctx = {
        composer = Composer.new(),
        buttons = {},
        overlay = nil,
        probe = nil,
    }

    ctx.composer:register('base', function()
        local scene = Scene.new()

        function scene:onCreate()
            local width = love.graphics.getWidth()
            local height = love.graphics.getHeight()

            add_demo_box(scene, {
                tag = 'overlay background',
                width = 'fill',
                height = 'fill',
            }, colors.cyan_fill, nil, nil)

            local card = add_demo_box(scene, {
                tag = 'overlay base card',
                x = 130,
                y = HEADER_HEIGHT + 94,
                width = max(360, width - 260),
                height = max(260, height - HEADER_HEIGHT - 250),
            }, colors.blue_fill, colors.blue_line, function()
                return 'Base scene content.\n\nThe overlap probe below should resolve through the overlay layer first.'
            end)
            card.demo_text_align = 'center'
            card.demo_text_offset_y = 36

            ctx.base_target = add_demo_box(scene, {
                tag = 'base probe target',
                interactive = true,
                x = width * 0.47,
                y = HEADER_HEIGHT + 250,
                width = 260,
                height = 140,
                zIndex = 240,
            }, colors.green_fill, colors.green_line, function()
                return 'Base target\nzIndex = 240'
            end)
            ctx.base_target.demo_text_align = 'center'
            ctx.base_target.demo_text_offset_y = 44
        end

        return scene
    end)

    ctx.composer:gotoScene('base', { duration = 0 })
    ctx.composer:update(0)

    local base_probe = resolved_probe(ctx.base_target, 130, 70)
    ctx.probe = {
        x = base_probe.x,
        y = base_probe.y,
    }

    local overlay = add_demo_box(ctx.composer.stage.overlayLayer, {
        tag = 'overlay probe target',
        interactive = true,
        visible = false,
        x = ctx.probe.x - 110,
        y = ctx.probe.y - 70,
        width = 280,
        height = 160,
        zIndex = -240,
    }, colors.red_fill, colors.red_line, function()
        return 'Overlay target\nzIndex = -240'
    end)
    overlay.demo_text_align = 'center'
    overlay.demo_text_offset_y = 46
    ctx.overlay = overlay

    local left = 26
    local top = HEADER_HEIGHT + 18
    local width = 220

    ctx.buttons = {
        make_button(left, top, width, 'Toggle Overlay', function()
            ctx.overlay.visible = not ctx.overlay.visible
        end, 'default'),
        make_button(left, top + 54, width, 'Hide Overlay', function()
            ctx.overlay.visible = false
        end, 'accent'),
    }

    return ctx
end

local function build_cache_screen()
    local ctx = {
        composer = Composer.new(),
        buttons = {},
        scene_b_creations = 0,
    }

    ctx.composer:register('A', function()
        local scene = Scene.new()

        function scene:onCreate()
            build_scene_shell(
                scene,
                'Scene A',
                function()
                    return 'Navigate away from B, then back to B.\nIts counter and instance id should persist.'
                end,
                colors.purple_fill,
                colors.purple_line
            )
        end

        return scene
    end)

    ctx.composer:register('B', function()
        local scene = Scene.new()

        ctx.scene_b_creations = ctx.scene_b_creations + 1
        scene.cache_instance_id = ctx.scene_b_creations
        scene.cache_counter = 0

        function scene:onCreate()
            build_scene_shell(
                scene,
                'Scene B',
                function()
                    return string.format(
                        'Cached instance id: %d\nCounter (active only): %.1f s',
                        scene.cache_instance_id,
                        scene.cache_counter
                    )
                end,
                colors.gold_fill,
                colors.gold_line
            )
        end

        return scene
    end)

    ctx.composer:gotoScene('B', { duration = 0 })
    ctx.composer:update(0)

    local left = 26
    local top = HEADER_HEIGHT + 18
    local width = 200

    ctx.buttons = {
        make_button(left, top, width, 'Go A', function()
            ctx.composer:gotoScene('A', { duration = 0 })
        end, 'default'),
        make_button(left, top + 54, width, 'Go B', function()
            ctx.composer:gotoScene('B', { duration = 0 })
        end, 'default'),
    }

    return ctx
end

local function build_failure_screen()
    local ctx = {
        composer = Composer.new(),
        buttons = {},
        unknown_scene_error = nil,
        hook_error = nil,
        two_pass_error = nil,
        stable_probe = nil,
    }

    ctx.composer:register('stable', function()
        local scene = Scene.new()

        function scene:onCreate()
            add_demo_box(scene, {
                tag = 'failure background',
                width = 'fill',
                height = 'fill',
            }, colors.green_fill, nil, nil)

            local card = add_demo_box(scene, {
                tag = 'failure stable card',
                x = 110,
                y = HEADER_HEIGHT + 98,
                width = max(360, love.graphics.getWidth() - 220),
                height = max(260, love.graphics.getHeight() - HEADER_HEIGHT - 250),
            }, colors.blue_fill, colors.blue_line, function()
                return 'Stable scene.\n\nFailure probes should leave this scene valid after the error is caught.'
            end)
            card.demo_text_align = 'center'
            card.demo_text_offset_y = 38

            ctx.stable_target = add_demo_box(scene, {
                tag = 'stable probe target',
                interactive = true,
                x = love.graphics.getWidth() * 0.48,
                y = HEADER_HEIGHT + 258,
                width = 260,
                height = 140,
            }, colors.green_fill, colors.green_line, function()
                return 'Stable probe target'
            end)
            ctx.stable_target.demo_text_align = 'center'
            ctx.stable_target.demo_text_offset_y = 50
        end

        return scene
    end)

    ctx.composer:register('broken', function()
        local scene = Scene.new()

        function scene:onEnterBefore()
            error('broken scene enter-before failure')
        end

        return scene
    end)

    ctx.composer:gotoScene('stable', { duration = 0 })
    ctx.composer:update(0)

    local probe = resolved_probe(ctx.stable_target, 130, 70)
    ctx.stable_probe = {
        x = probe.x,
        y = probe.y,
    }

    local left = 26
    local top = HEADER_HEIGHT + 18
    local width = 250

    ctx.buttons = {
        make_button(left, top, width, 'Unknown Scene Failure', function()
            local ok, err = pcall(function()
                ctx.composer:gotoScene('missing', { duration = 0 })
                ctx.composer:update(0)
            end)

            ctx.unknown_scene_error = ok and 'unexpectedly succeeded' or tostring(err)
        end, 'danger'),
        make_button(left, top + 54, width, 'Hook Error Failure', function()
            local ok, err = pcall(function()
                ctx.composer:gotoScene('broken', { duration = 0 })
                ctx.composer:update(0)
            end)

            ctx.hook_error = ok and 'unexpectedly succeeded' or tostring(err)
        end, 'danger'),
        make_button(left, top + 108, width, 'Two-Pass Failure', function()
            local stage = ctx.composer.stage

            stage:update(0)
            stage:draw({}, noop)

            local ok, err = pcall(function()
                stage:draw({}, noop)
            end)

            ctx.two_pass_error = ok and 'unexpectedly succeeded' or tostring(err)
        end, 'danger'),
    }

    return ctx
end

screens = {
    {
        title = 'Lifecycle Order',
        spec = 'Scene §6.4.2 stable enter/leave hooks only',
        build = build_lifecycle_screen,
        draw_overlay = function(ctx)
            local width = love.graphics.getWidth()

            draw_panel(
                18,
                love.graphics.getHeight() - 122,
                640,
                100,
                'Acceptance Notes',
                {
                    'Only enter-before, enter-after, leave-before, and leave-after are shown.',
                    'Use Go A / Go B / Go C to verify Composer-managed activation order.',
                    'No public "running" lifecycle phase is implied.',
                }
            )

            draw_panel(
                width - 448,
                HEADER_HEIGHT + 18,
                430,
                380,
                'Lifecycle Log',
                tail_lines(ctx.log, LOG_LIMIT)
            )

            draw_panel(
                width - 448,
                HEADER_HEIGHT + 412,
                430,
                94,
                'Current Stable Scene',
                {
                    composer_current_scene_name(ctx.composer) or 'none',
                    'Navigation to the active scene remains a full request, not a no-op.',
                }
            )
        end,
    },
    {
        title = 'Transition Interruption',
        spec = 'Composer §6.4.3 interruption commits the final scene with no intermediate hook residue',
        build = build_transition_screen,
        draw_overlay = function(ctx)
            local width = love.graphics.getWidth()
            local forbidden = count_forbidden_hooks(ctx.log)

            draw_panel(
                18,
                love.graphics.getHeight() - 122,
                700,
                100,
                'Acceptance Notes',
                {
                    'Start B, then interrupt with C while the fade is still active.',
                    'Intermediate B must not reach enter-after or any leave hook.',
                    'C becomes the final committed scene cleanly.',
                }
            )

            draw_panel(
                width - 470,
                HEADER_HEIGHT + 18,
                452,
                380,
                'Transition Log',
                tail_lines(ctx.log, LOG_LIMIT)
            )

            draw_panel(
                width - 470,
                HEADER_HEIGHT + 412,
                452,
                112,
                'Observed Guarantees',
                {
                    'stable scene: ' .. (composer_current_scene_name(ctx.composer) or 'none'),
                    'transition active: ' .. tostring(ctx.composer.transitionState ~= nil),
                    'forbidden B hooks seen: ' ..
                        (#forbidden == 0 and 'none' or table.concat(forbidden, ', ')),
                }
            )
        end,
    },
    {
        title = 'Overlay Precedence And Stage Sync',
        spec = 'Stage §6.4.1 overlay-first target resolution + viewport and safe-area synchronization',
        build = build_overlay_screen,
        draw_overlay = function(ctx)
            local width = love.graphics.getWidth()
            local stage = ctx.composer.stage
            local viewport = stage:getViewport()
            local safe_area = stage:getSafeArea()
            local safe_area_bounds = stage:getSafeAreaBounds()
            local delivery = stage:deliverInput({
                kind = 'mousepressed',
                x = ctx.probe.x,
                y = ctx.probe.y,
                button = 1,
            })

            rgba(colors.accent)
            love.graphics.circle('line', ctx.probe.x, ctx.probe.y, 8)
            love.graphics.line(ctx.probe.x - 10, ctx.probe.y, ctx.probe.x + 10, ctx.probe.y)
            love.graphics.line(ctx.probe.x, ctx.probe.y - 10, ctx.probe.x, ctx.probe.y + 10)

            draw_panel(
                18,
                love.graphics.getHeight() - 122,
                720,
                100,
                'Acceptance Notes',
                {
                    'The overlap probe resolves through overlayLayer before baseSceneLayer.',
                    'Overlay precedence is structural and independent of child zIndex.',
                    'Resize the window to watch viewport and safe-area values update together.',
                }
            )

            draw_panel(
                width - 430,
                HEADER_HEIGHT + 18,
                412,
                128,
                'Probe Result',
                {
                    'overlay visible: ' .. tostring(ctx.overlay.visible),
                    'target: ' .. label_of(delivery.target),
                    'path: ' .. join_path(delivery.path),
                    'intent: ' .. tostring(delivery.intent),
                }
            )

            draw_panel(
                width - 430,
                HEADER_HEIGHT + 160,
                412,
                128,
                'Viewport',
                {
                    format_rect(viewport),
                    'safeAreaInsets: ' .. format_insets(safe_area),
                    'safeAreaBounds: ' .. format_rect(safe_area_bounds),
                }
            )
        end,
    },
    {
        title = 'Scene Cache Persistence',
        spec = 'Composer §6.4.3 scene caching remains within Composer ownership',
        build = build_cache_screen,
        update = function(ctx, dt)
            local scene = composer_current_scene(ctx.composer)

            if scene ~= nil and composer_current_scene_name(ctx.composer) == 'B' and
                scene.cache_counter ~= nil then
                scene.cache_counter = scene.cache_counter + dt
            end
        end,
        draw_overlay = function(ctx)
            local width = love.graphics.getWidth()
            local stable_scene = composer_current_scene(ctx.composer)
            local current_name = composer_current_scene_name(ctx.composer) or 'none'
            local current_counter = 'n/a'
            local current_instance = 'n/a'

            if stable_scene ~= nil and stable_scene.cache_counter ~= nil then
                current_counter = string.format('%.1f s', stable_scene.cache_counter)
                current_instance = tostring(stable_scene.cache_instance_id)
            end

            draw_panel(
                18,
                love.graphics.getHeight() - 122,
                680,
                100,
                'Acceptance Notes',
                {
                    'Scene B increments only while active.',
                    'Go A, then return to B: the counter and instance id should persist.',
                    'The harness demonstrates persistence without inventing a public cache-eviction API.',
                }
            )

            draw_panel(
                width - 420,
                HEADER_HEIGHT + 18,
                402,
                112,
                'Observed Cache State',
                {
                    'stable scene: ' .. current_name,
                    'B creations this screen: ' .. tostring(ctx.scene_b_creations),
                    'current B instance id: ' .. current_instance,
                    'current B counter: ' .. current_counter,
                }
            )
        end,
    },
    {
        title = 'Deterministic Failures',
        spec = 'Foundation §3G hard failures + Stage two-pass enforcement',
        build = build_failure_screen,
        draw_overlay = function(ctx)
            local width = love.graphics.getWidth()
            local stage = ctx.composer.stage
            local target = stage:resolveTarget(ctx.stable_probe.x, ctx.stable_probe.y)
            local delivery = stage:deliverInput({
                kind = 'mousepressed',
                x = ctx.stable_probe.x,
                y = ctx.stable_probe.y,
                button = 1,
            })

            rgba(colors.accent)
            love.graphics.circle('line', ctx.stable_probe.x, ctx.stable_probe.y, 8)

            draw_panel(
                18,
                love.graphics.getHeight() - 122,
                720,
                100,
                'Acceptance Notes',
                {
                    'Unknown-scene navigation and hook errors are caught deterministically with pcall.',
                    'Two-pass draw failure is caught without leaving the stage unusable.',
                    'The stable probe should still resolve after each failure is caught.',
                }
            )

            draw_panel(
                width - 460,
                HEADER_HEIGHT + 18,
                442,
                164,
                'Failure Results',
                {
                    'unknown scene: ' .. tostring(ctx.unknown_scene_error or 'not run'),
                    'hook error: ' .. tostring(ctx.hook_error or 'not run'),
                    'two-pass: ' .. tostring(ctx.two_pass_error or 'not run'),
                }
            )

            draw_panel(
                width - 460,
                HEADER_HEIGHT + 196,
                442,
                112,
                'Graceful Degradation Check',
                {
                    'stable scene: ' .. (composer_current_scene_name(ctx.composer) or 'none'),
                    'probe target: ' .. label_of(target),
                    'delivery path: ' .. join_path(delivery.path),
                }
            )
        end,
    },
}

local function destroy_current()
    if current_screen == nil or current_screen.ctx == nil then
        return
    end

    local composer = current_screen.ctx.composer

    if composer ~= nil then
        composer:destroy()
    end

    current_screen = nil
end

local function rebuild_current()
    destroy_current()

    local definition = screens[current_index]

    current_screen = {
        definition = definition,
        ctx = definition.build(),
    }
end

local function each_button(ctx, callback)
    if ctx.buttons == nil then
        return
    end

    for index = 1, #ctx.buttons do
        callback(ctx.buttons[index])
    end
end

function love.load()
    love.graphics.setBackgroundColor(
        colors.background[1],
        colors.background[2],
        colors.background[3],
        colors.background[4]
    )
    rebuild_current()
end

function love.update(dt)
    local definition = current_screen.definition
    local ctx = current_screen.ctx

    if definition.update ~= nil then
        definition.update(ctx, dt)
    end

    ctx.composer:update(dt)
end

function love.draw()
    local definition = current_screen.definition
    local ctx = current_screen.ctx

    ctx.composer:draw(love.graphics, draw_runtime_node)

    draw_header(definition)

    each_button(ctx, draw_button)

    if definition.draw_overlay ~= nil then
        definition.draw_overlay(ctx)
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    local ctx = current_screen.ctx

    each_button(ctx, function(entry)
        if point_in_rect(x, y, entry) then
            entry.action()
        end
    end)
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
        return
    end

    if key == 'right' then
        current_index = current_index + 1

        if current_index > #screens then
            current_index = 1
        end

        rebuild_current()
        return
    end

    if key == 'left' then
        current_index = current_index - 1

        if current_index < 1 then
            current_index = #screens
        end

        rebuild_current()
        return
    end

    if key == 'r' then
        rebuild_current()
    end
end

function love.resize(_, _)
    rebuild_current()
end

function love.quit()
    destroy_current()
end
