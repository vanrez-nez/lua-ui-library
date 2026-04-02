package.path = '?.lua;?/init.lua;' .. package.path

local UI = require('lib.ui')

local Container = UI.Container
local Drawable = UI.Drawable
local Rectangle = UI.Rectangle
local Stage = UI.Stage

local floor = math.floor
local min = math.min

local colors = {
    background = { 0.07, 0.08, 0.10, 1 },
    header = { 0.11, 0.13, 0.16, 0.96 },
    panel = { 0.13, 0.15, 0.19, 0.94 },
    panel_line = { 0.32, 0.36, 0.43, 1 },
    text = { 0.92, 0.94, 0.97, 1 },
    muted = { 0.67, 0.72, 0.79, 1 },
    accent = { 0.96, 0.73, 0.33, 1 },
    success = { 0.46, 0.82, 0.58, 1 },
    danger = { 0.92, 0.42, 0.42, 1 },
    probe = { 0.99, 0.96, 0.78, 1 },
    blue_fill = { 0.25, 0.52, 0.86, 0.24 },
    blue_line = { 0.44, 0.71, 1.00, 1 },
    cyan_fill = { 0.15, 0.72, 0.78, 0.22 },
    cyan_line = { 0.42, 0.93, 0.98, 1 },
    green_fill = { 0.26, 0.69, 0.41, 0.22 },
    green_line = { 0.49, 0.90, 0.63, 1 },
    gold_fill = { 0.77, 0.62, 0.21, 0.24 },
    gold_line = { 0.95, 0.80, 0.37, 1 },
    red_fill = { 0.83, 0.32, 0.32, 0.24 },
    red_line = { 0.98, 0.56, 0.56, 1 },
    purple_fill = { 0.56, 0.37, 0.79, 0.22 },
    purple_line = { 0.76, 0.60, 0.96, 1 },
}

local screens = {}
local current_index = 1
local current_screen = nil

local HEADER_HEIGHT = 88

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
            'Phase 1 Harness  %d/%d  %s',
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

local function draw_probe(x, y, label)
    rgba(colors.probe)
    love.graphics.line(x - 8, y, x + 8, y)
    love.graphics.line(x, y - 8, x, y + 8)
    love.graphics.circle('line', x, y, 5)
    love.graphics.print(label, x + 10, y - 8)
end

local function get_local_rect_points(node, rect)
    local x1, y1 = node:localToWorld(rect.x, rect.y)
    local x2, y2 = node:localToWorld(rect.x + rect.width, rect.y)
    local x3, y3 = node:localToWorld(rect.x + rect.width, rect.y + rect.height)
    local x4, y4 = node:localToWorld(rect.x, rect.y + rect.height)

    return {
        x1, y1,
        x2, y2,
        x3, y3,
        x4, y4,
    }
end

local function draw_local_rect(node, rect, fill_color, line_color)
    local points = get_local_rect_points(node, rect)

    if fill_color ~= nil then
        rgba(fill_color)
        love.graphics.polygon('fill', points)
    end

    if line_color ~= nil then
        rgba(line_color)
        love.graphics.polygon('line', points)
    end
end

local function draw_node_bounds(node, fill_color, line_color)
    draw_local_rect(node, node:getLocalBounds(), fill_color, line_color)
end

local function draw_node_tag(node, text, color)
    local bounds = node:getWorldBounds()

    rgba(color or colors.text)
    love.graphics.print(text, bounds.x + 8, bounds.y + 8)
end

local function make_probe_graphics()
    local graphics = {
        calls = {},
        current_scissor = nil,
        stencil_compare = nil,
        stencil_value = nil,
    }

    function graphics.getScissor()
        local rect = graphics.current_scissor

        if rect == nil then
            return nil
        end

        return rect.x, rect.y, rect.width, rect.height
    end

    function graphics.setScissor(x, y, width, height)
        if x == nil then
            graphics.current_scissor = nil
            graphics.calls[#graphics.calls + 1] = 'scissor:nil'
            return
        end

        graphics.current_scissor = {
            x = x,
            y = y,
            width = width,
            height = height,
        }
        graphics.calls[#graphics.calls + 1] = string.format(
            'scissor:%d:%d:%d:%d',
            round(x),
            round(y),
            round(width),
            round(height)
        )
    end

    function graphics.getStencilTest()
        return graphics.stencil_compare, graphics.stencil_value
    end

    function graphics.setStencilTest(compare, value)
        graphics.stencil_compare = compare
        graphics.stencil_value = value

        if compare == nil then
            graphics.calls[#graphics.calls + 1] = 'stencil_test:nil'
            return
        end

        graphics.calls[#graphics.calls + 1] =
            'stencil_test:' .. tostring(compare) .. ':' .. tostring(value)
    end

    function graphics.stencil(callback, action, value, keepvalues)
        graphics.calls[#graphics.calls + 1] =
            'stencil:' .. tostring(action) .. ':' .. tostring(value) ..
            ':' .. tostring(keepvalues)
        callback()
    end

    function graphics.polygon(mode, points)
        graphics.calls[#graphics.calls + 1] =
            'polygon:' .. tostring(mode) .. ':' .. tostring(#points)
    end

    return graphics
end

local function inspect_clip_draw(stage)
    local graphics = make_probe_graphics()
    local metrics = {
        scissor_calls = 0,
        stencil_increments = 0,
        stencil_decrements = 0,
        restored_scissor = false,
        restored_stencil = false,
    }

    stage:update(0)
    stage:draw(graphics, function()
    end)

    for index = 1, #graphics.calls do
        local call = graphics.calls[index]

        if call:find('scissor:', 1, true) == 1 then
            metrics.scissor_calls = metrics.scissor_calls + 1
        end

        if call == 'stencil:increment:1:true' then
            metrics.stencil_increments = metrics.stencil_increments + 1
        end

        if call == 'stencil:decrement:1:true' then
            metrics.stencil_decrements = metrics.stencil_decrements + 1
        end

        if call == 'scissor:nil' then
            metrics.restored_scissor = true
        end

        if call == 'stencil_test:nil' then
            metrics.restored_stencil = true
        end
    end

    return metrics
end

local function make_stage()
    return Stage.new({
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
    })
end

local function destroy_current()
    if current_screen ~= nil and current_screen.ctx ~= nil and
        current_screen.ctx.stage ~= nil then
        current_screen.ctx.stage:destroy()
    end

    current_screen = nil
end

local function add_container(parent, opts, fill_color, line_color)
    local node = Container.new(opts)
    node.demo_fill = fill_color
    node.demo_line = line_color
    parent:addChild(node)
    return node
end

local function add_drawable(parent, opts, fill_color, line_color)
    local node = Drawable.new(opts)
    node.demo_fill = fill_color
    node.demo_line = line_color
    parent:addChild(node)
    return node
end

local function draw_demo_node(node)
    if node.demo_fill ~= nil or node.demo_line ~= nil then
        draw_node_bounds(node, node.demo_fill, node.demo_line)
    end

    if node.demo_draw ~= nil then
        node.demo_draw(node)
    end

    if node.demo_label ~= nil then
        draw_node_tag(node, node.demo_label, colors.text)
    end
end

local function two_columns(width, top, height)
    local gap = 42
    local column_width = floor((width - gap * 3) / 2)

    return {
        { x = gap, y = top, width = column_width, height = height },
        {
            x = gap * 2 + column_width,
            y = top,
            width = column_width,
            height = height,
        },
    }
end

local function three_columns(width, top, height)
    local gap = 28
    local column_width = floor((width - gap * 4) / 3)

    return {
        { x = gap, y = top, width = column_width, height = height },
        {
            x = gap * 2 + column_width,
            y = top,
            width = column_width,
            height = height,
        },
        {
            x = gap * 3 + column_width * 2,
            y = top,
            width = column_width,
            height = height,
        },
    }
end

local function make_ordering_screen(width, height)
    local stage = make_stage()
    local layout = two_columns(width, HEADER_HEIGHT + 36, height - HEADER_HEIGHT - 190)
    local ctx = {
        stage = stage,
        groups = {},
        last_draw_order = {},
    }

    for index = 1, #layout do
        local region = layout[index]
        local shell = add_container(stage.baseSceneLayer, {
            tag = index == 1 and 'equal-z shell' or 'raised-z shell',
            x = region.x + 26,
            y = region.y + 30,
            width = region.width - 52,
            height = region.height - 72,
        }, nil, nil)

        local low = add_container(shell, {
            tag = index == 1 and 'equal-low' or 'raised-low',
            interactive = true,
            x = 22,
            y = 18,
            width = 160,
            height = 130,
            zIndex = 0,
        }, colors.blue_fill, colors.blue_line)
        low.demo_label = 'low z=0'

        local mid = add_container(shell, {
            tag = index == 1 and 'equal-mid' or 'raised-mid',
            interactive = true,
            x = 58,
            y = 46,
            width = 160,
            height = 130,
            zIndex = index == 1 and 1 or 3,
        }, colors.gold_fill, colors.gold_line)
        mid.demo_label = index == 1 and 'mid z=1' or 'mid z=3'

        local high = add_container(shell, {
            tag = index == 1 and 'equal-high' or 'raised-high',
            interactive = true,
            x = 94,
            y = 74,
            width = 160,
            height = 130,
            zIndex = 1,
        }, colors.red_fill, colors.red_line)
        high.demo_label = 'high z=1'

        local probe_x, probe_y = shell:localToWorld(118, 98)

        ctx.groups[index] = {
            title = index == 1 and 'Equal zIndex, stable draw order'
                or 'Raised zIndex wins draw and hit order',
            shell = shell,
            nodes = { low, mid, high },
            probe = {
                x = probe_x,
                y = probe_y,
                expected = index == 1 and 'equal-high' or 'raised-mid',
            },
            frame = region,
        }
    end

    return ctx
end

local function make_clipping_screen(width, height)
    local stage = make_stage()
    local layout = two_columns(width, HEADER_HEIGHT + 36, height - HEADER_HEIGHT - 190)
    local ctx = {
        stage = stage,
        probes = {},
        metrics = nil,
    }

    do
        local region = layout[1]
        local root = add_container(stage.baseSceneLayer, {
            tag = 'axis root',
            x = region.x + 34,
            y = region.y + 46,
            width = region.width - 68,
            height = region.height - 100,
            clipChildren = true,
        }, colors.blue_fill, colors.blue_line)
        root.demo_label = 'axis clip'

        local nested = add_container(root, {
            tag = 'axis nested',
            x = 42,
            y = 34,
            width = root:getLocalBounds().width - 84,
            height = root:getLocalBounds().height - 68,
            clipChildren = true,
        }, colors.green_fill, colors.green_line)
        nested.demo_label = 'nested scissor'

        local overflow = add_container(nested, {
            tag = 'axis-overflow',
            interactive = true,
            x = -38,
            y = 20,
            width = 220,
            height = 88,
            zIndex = 0,
        }, colors.red_fill, colors.red_line)
        overflow.demo_label = 'overflow leaf'

        local inside = add_container(nested, {
            tag = 'axis-inside',
            interactive = true,
            x = 28,
            y = 58,
            width = 132,
            height = 68,
            zIndex = 1,
        }, colors.gold_fill, colors.gold_line)
        inside.demo_label = 'inside leaf'

        local inside_x, inside_y = inside:localToWorld(24, 24)
        local overflow_x, overflow_y = overflow:localToWorld(14, 24)

        ctx.probes[#ctx.probes + 1] = {
            title = 'axis inside',
            x = inside_x,
            y = inside_y,
            expected = 'axis-inside',
        }
        ctx.probes[#ctx.probes + 1] = {
            title = 'axis overflow',
            x = overflow_x,
            y = overflow_y,
            expected = 'no target',
        }
    end

    do
        local region = layout[2]
        local root = add_container(stage.baseSceneLayer, {
            tag = 'rotated root',
            x = region.x + region.width * 0.52,
            y = region.y + region.height * 0.45,
            width = region.width * 0.42,
            height = region.height * 0.38,
            pivotX = 0.5,
            pivotY = 0.5,
            rotation = math.rad(18),
            clipChildren = true,
        }, colors.purple_fill, colors.purple_line)
        root.demo_label = 'rotated clip'

        local nested = add_container(root, {
            tag = 'rotated nested',
            x = 26,
            y = 12,
            width = root:getLocalBounds().width * 0.62,
            height = root:getLocalBounds().height * 0.62,
            pivotX = 0.5,
            pivotY = 0.5,
            rotation = math.rad(-21),
            clipChildren = true,
        }, colors.cyan_fill, colors.cyan_line)
        nested.demo_label = 'nested stencil'

        local overflow = add_container(nested, {
            tag = 'rotated-overflow',
            interactive = true,
            x = -26,
            y = 18,
            width = 164,
            height = 76,
        }, colors.red_fill, colors.red_line)
        overflow.demo_label = 'rotated leaf'

        local inside_x, inside_y = overflow:localToWorld(78, 30)
        local overflow_x, overflow_y = overflow:localToWorld(8, 26)

        ctx.probes[#ctx.probes + 1] = {
            title = 'rotated inside',
            x = inside_x,
            y = inside_y,
            expected = 'rotated-overflow',
        }
        ctx.probes[#ctx.probes + 1] = {
            title = 'rotated overflow',
            x = overflow_x,
            y = overflow_y,
            expected = 'no target',
        }
    end

    return ctx
end

local function make_clamp_screen(width, height)
    local stage = make_stage()
    local columns = two_columns(width, HEADER_HEIGHT + 36, height - HEADER_HEIGHT - 190)
    local row_height = floor((columns[1].height - 24) / 2)
    local ctx = {
        stage = stage,
        cases = {},
    }

    local function add_case(region, top_offset, title, child_opts)
        local shell = add_container(stage.baseSceneLayer, {
            x = region.x + 30,
            y = region.y + top_offset + 28,
            width = region.width - 60,
            height = row_height - 44,
        }, nil, nil)
        local parent = add_container(shell, {
            tag = title .. ' parent',
            width = shell:getLocalBounds().width,
            height = shell:getLocalBounds().height,
        }, nil, colors.panel_line)
        local child = add_container(parent, child_opts, colors.green_fill, colors.green_line)

        ctx.cases[#ctx.cases + 1] = {
            title = title,
            parent = parent,
            child = child,
            frame = {
                x = region.x + 14,
                y = region.y + top_offset,
                width = region.width - 28,
                height = row_height - 8,
            },
        }
    end

    add_case(columns[1], 0, 'fill width + maxWidth clamp', {
        tag = 'fill-max',
        x = 16,
        y = 24,
        width = 'fill',
        maxWidth = 140,
        height = 48,
    })
    add_case(columns[1], row_height + 16, 'percent width + minWidth clamp', {
        tag = 'percent-min',
        x = 16,
        y = 24,
        width = '20%',
        minWidth = 96,
        height = 48,
    })
    add_case(columns[2], 0, 'fill height + maxHeight clamp', {
        tag = 'fill-max-height',
        x = 24,
        y = 16,
        width = 72,
        height = 'fill',
        maxHeight = 86,
    })
    add_case(columns[2], row_height + 16, 'percent height + minHeight clamp', {
        tag = 'percent-min-height',
        x = 24,
        y = 16,
        width = 72,
        height = '10%',
        minHeight = 54,
    })

    return ctx
end

local function make_drawable_screen(width, height)
    local stage = make_stage()
    local layout = three_columns(width, HEADER_HEIGHT + 44, height - HEADER_HEIGHT - 208)
    local ctx = {
        stage = stage,
        cases = {},
    }

    local specs = {
        {
            title = 'center / end alignment',
            opts = {
                tag = 'drawable-center',
                x = layout[1].x + 28,
                y = layout[1].y + 54,
                width = layout[1].width - 56,
                height = layout[1].height - 132,
                padding = { 18, 24, 26, 32 },
                alignX = 'center',
                alignY = 'end',
            },
            fill = colors.blue_fill,
            line = colors.blue_line,
            content_width = 88,
            content_height = 42,
        },
        {
            title = 'stretch alignment',
            opts = {
                tag = 'drawable-stretch',
                x = layout[2].x + 28,
                y = layout[2].y + 54,
                width = layout[2].width - 56,
                height = layout[2].height - 132,
                padding = { 20, 24, 20, 24 },
                alignX = 'stretch',
                alignY = 'stretch',
            },
            fill = colors.green_fill,
            line = colors.green_line,
            content_width = 96,
            content_height = 44,
        },
        {
            title = 'collapsed content box',
            opts = {
                tag = 'drawable-collapsed',
                x = layout[3].x + 40,
                y = layout[3].y + 94,
                width = layout[3].width - 80,
                height = 118,
                padding = 70,
                alignX = 'end',
                alignY = 'center',
            },
            fill = colors.purple_fill,
            line = colors.purple_line,
            content_width = 72,
            content_height = 30,
        },
    }

    for index = 1, #specs do
        local spec = specs[index]
        local node = add_drawable(stage.baseSceneLayer, spec.opts, spec.fill, spec.line)

        ctx.cases[index] = {
            title = spec.title,
            node = node,
            frame = layout[index],
            content_width = spec.content_width,
            content_height = spec.content_height,
        }
    end

    return ctx
end

local function make_stage_screen(width, height)
    local stage = make_stage()
    local layout = three_columns(width, HEADER_HEIGHT + 34, height - HEADER_HEIGHT - 216)
    local ctx = {
        stage = stage,
        probes = {},
    }

    do
        local region = layout[1]
        local base = add_container(stage.baseSceneLayer, {
            tag = 'precedence-base',
            interactive = true,
            x = region.x + 54,
            y = region.y + 72,
            width = region.width - 108,
            height = region.height - 148,
            zIndex = 240,
        }, colors.blue_fill, colors.blue_line)
        base.demo_label = 'base z=240'

        local overlay = add_container(stage.overlayLayer, {
            tag = 'precedence-overlay',
            interactive = true,
            x = region.x + 80,
            y = region.y + 96,
            width = region.width - 108,
            height = region.height - 148,
            zIndex = -240,
        }, colors.red_fill, colors.red_line)
        overlay.demo_label = 'overlay z=-240'

        ctx.probes[#ctx.probes + 1] = {
            title = 'overlay precedence',
            x = region.x + region.width * 0.56,
            y = region.y + region.height * 0.54,
            expected = 'precedence-overlay',
            frame = region,
        }
    end

    do
        local region = layout[2]
        local base = add_container(stage.baseSceneLayer, {
            tag = 'fallthrough-base',
            interactive = true,
            x = region.x + 54,
            y = region.y + 72,
            width = region.width - 108,
            height = region.height - 148,
            zIndex = 40,
        }, colors.green_fill, colors.green_line)
        base.demo_label = 'base target'

        local overlay = add_container(stage.overlayLayer, {
            tag = 'fallthrough-overlay',
            interactive = true,
            visible = false,
            x = region.x + 80,
            y = region.y + 96,
            width = region.width - 108,
            height = region.height - 148,
            zIndex = 999,
        }, colors.gold_fill, colors.gold_line)
        overlay.demo_label = 'hidden overlay'

        ctx.probes[#ctx.probes + 1] = {
            title = 'overlay hidden -> base',
            x = region.x + region.width * 0.56,
            y = region.y + region.height * 0.54,
            expected = 'fallthrough-base',
            frame = region,
        }
    end

    do
        local region = layout[3]
        local disabled_shell = add_container(stage.baseSceneLayer, {
            tag = 'disabled-shell',
            enabled = false,
            x = region.x + 48,
            y = region.y + 60,
            width = region.width - 96,
            height = region.height - 132,
        }, nil, colors.panel_line)
        local base_leaf = add_container(disabled_shell, {
            tag = 'disabled-leaf',
            interactive = true,
            x = 18,
            y = 18,
            width = disabled_shell:getLocalBounds().width - 36,
            height = disabled_shell:getLocalBounds().height - 36,
        }, colors.blue_fill, colors.blue_line)
        base_leaf.demo_label = 'disabled base branch'

        local clip = add_container(stage.overlayLayer, {
            tag = 'empty-clip',
            x = region.x + 94,
            y = region.y + 120,
            width = 0,
            height = 120,
            clipChildren = true,
        }, nil, colors.red_line)
        local overlay_leaf = add_container(clip, {
            tag = 'empty-clip-leaf',
            interactive = true,
            x = -38,
            y = 12,
            width = 136,
            height = 68,
        }, colors.red_fill, colors.red_line)
        overlay_leaf.demo_label = 'degenerate overlay clip'

        ctx.probes[#ctx.probes + 1] = {
            title = 'empty effective target',
            x = region.x + region.width * 0.54,
            y = region.y + region.height * 0.54,
            expected = 'no target',
            frame = region,
        }
    end

    return ctx
end

local function make_failure_screen(width, height)
    local stage = make_stage()
    local region = {
        x = 64,
        y = HEADER_HEIGHT + 44,
        width = width - 128,
        height = height - HEADER_HEIGHT - 210,
    }
    local ctx = {
        stage = stage,
        probe = nil,
        startup_failure = nil,
        repeat_failure = 'press T to trigger a second draw in one frame',
    }

    local stable = add_container(stage.baseSceneLayer, {
        tag = 'stable-target',
        interactive = true,
        x = region.x + 120,
        y = region.y + 90,
        width = region.width - 240,
        height = region.height - 180,
    }, colors.green_fill, colors.green_line)
    stable.demo_label = 'stable target after caught error'

    local probe_x, probe_y = stable:localToWorld(32, 32)
    ctx.probe = {
        x = probe_x,
        y = probe_y,
        expected = 'stable-target',
    }

    do
        local ok, err = pcall(function()
            stage:draw(make_probe_graphics(), function()
            end)
        end)

        if ok then
            ctx.startup_failure = 'unexpectedly succeeded'
        else
            ctx.startup_failure = tostring(err)
        end
    end

    return ctx
end

screens = {
    {
        title = 'Ordering And Hit Resolution',
        spec = 'Container §6.1.1 composition + target resolution',
        build = make_ordering_screen,
        draw_overlay = function(ctx)
            local lines = {
                'Two overlap groups use the same Stage-owned resolveTarget probe.',
                'Hits must follow reverse draw order among eligible siblings.',
                'The left group keeps equal zIndex; the right group raises mid.zIndex.',
            }
            draw_panel(18, love.graphics.getHeight() - 122, 660, 100, 'Acceptance Notes', lines)

            local draw_order = {}

            for index = 1, #ctx.last_draw_order do
                local tag = ctx.last_draw_order[index]

                if tag ~= 'base scene layer' and tag ~= 'overlay layer' then
                    draw_order[#draw_order + 1] = tag
                end
            end

            draw_panel(
                love.graphics.getWidth() - 420,
                love.graphics.getHeight() - 160,
                402,
                138,
                'Observed Results',
                {
                    'draw order: ' .. table.concat(draw_order, ', '),
                    'equal-z probe: ' .. label_of(ctx.stage:resolveTarget(
                        ctx.groups[1].probe.x,
                        ctx.groups[1].probe.y
                    )),
                    'raised-z probe: ' .. label_of(ctx.stage:resolveTarget(
                        ctx.groups[2].probe.x,
                        ctx.groups[2].probe.y
                    )),
                    'Both probes should match the top-most visible draw order.',
                }
            )

            for index = 1, #ctx.groups do
                local group = ctx.groups[index]

                rgba(colors.panel_line)
                love.graphics.rectangle(
                    'line',
                    group.frame.x,
                    group.frame.y,
                    group.frame.width,
                    group.frame.height,
                    10,
                    10
                )
                rgba(colors.text)
                love.graphics.print(group.title, group.frame.x + 12, group.frame.y + 12)
                draw_probe(group.probe.x, group.probe.y, group.probe.expected)
            end
        end,
    },
    {
        title = 'Clipping And Nested Composition',
        spec = 'Container §6.1.1 clipping + degenerate clip semantics',
        build = make_clipping_screen,
        after_draw = function(ctx)
            ctx.metrics = inspect_clip_draw(ctx.stage)
        end,
        draw_overlay = function(ctx)
            local left = {
                'Axis-aligned nested clips should clip draw and hit regions.',
                'The inside probe should resolve to axis-inside.',
                'The overflow probe should resolve to no target.',
            }
            draw_panel(18, love.graphics.getHeight() - 122, 480, 100, 'Scissor Branch', left)

            local right = {
                'Rotated nested clips should use stencil composition.',
                'The inside probe should resolve to rotated-overflow.',
                'The overflow probe should resolve to no target.',
            }
            draw_panel(512, love.graphics.getHeight() - 122, 480, 100, 'Stencil Branch', right)

            local metric_lines = {
                'scissor calls: ' .. tostring(ctx.metrics.scissor_calls),
                'stencil increments: ' .. tostring(ctx.metrics.stencil_increments),
                'stencil decrements: ' .. tostring(ctx.metrics.stencil_decrements),
                'restore scissor: ' .. tostring(ctx.metrics.restored_scissor),
                'restore stencil: ' .. tostring(ctx.metrics.restored_stencil),
            }
            draw_panel(
                love.graphics.getWidth() - 272,
                HEADER_HEIGHT + 16,
                254,
                128,
                'Clip Probe',
                metric_lines
            )

            for index = 1, #ctx.probes do
                local probe = ctx.probes[index]
                draw_probe(probe.x, probe.y, probe.title)
            end
        end,
    },
    {
        title = 'Measurement And Clamp Resolution',
        spec = 'Container §6.1.1 width/height surface + min/max clamps',
        build = make_clamp_screen,
        draw_overlay = function(ctx)
            local lines = {
                'These cases use number, fill, and percentage sizing with min/max clamps.',
                'The harness reports resolved local bounds, not undocumented cache values.',
            }
            draw_panel(18, love.graphics.getHeight() - 100, 760, 78, 'Acceptance Notes', lines)

            for index = 1, #ctx.cases do
                local case = ctx.cases[index]
                local parent_bounds = case.parent:getLocalBounds()
                local child_bounds = case.child:getLocalBounds()

                rgba(colors.panel_line)
                love.graphics.rectangle(
                    'line',
                    case.frame.x,
                    case.frame.y,
                    case.frame.width,
                    case.frame.height,
                    10,
                    10
                )
                draw_panel(
                    case.frame.x + 10,
                    case.frame.y + 10,
                    case.frame.width - 20,
                    78,
                    case.title,
                    {
                        'parent: ' .. format_rect(parent_bounds),
                        'child: ' .. format_rect(child_bounds),
                    }
                )
            end
        end,
    },
    {
        title = 'Drawable Content Box And Alignment',
        spec = 'Drawable §6.1.2 content box, alignment, and zero-area clamp',
        build = make_drawable_screen,
        draw_stage = function(ctx, node)
            if node.demo_fill ~= nil or node.demo_line ~= nil then
                draw_node_bounds(node, node.demo_fill, node.demo_line)
            end

            for index = 1, #ctx.cases do
                local case = ctx.cases[index]

                if node == case.node then
                    local content_rect = node:getContentRect()
                    local resolved_rect = node:resolveContentRect(
                        case.content_width,
                        case.content_height
                    )

                    draw_local_rect(node, content_rect, nil, colors.gold_line)
                    draw_local_rect(node, resolved_rect, colors.red_fill, colors.red_line)
                    draw_node_tag(node, case.title, colors.text)
                end
            end
        end,
        draw_overlay = function(ctx)
            draw_panel(
                18,
                love.graphics.getHeight() - 118,
                860,
                96,
                'Legend',
                {
                    'outer outline = Drawable local bounds',
                    'gold outline = content box after padding',
                    'red fill = resolveContentRect(contentWidth, contentHeight)',
                }
            )

            for index = 1, #ctx.cases do
                local case = ctx.cases[index]
                local node = case.node

                draw_panel(
                    case.frame.x + 12,
                    case.frame.y + case.frame.height - 84,
                    case.frame.width - 24,
                    72,
                    case.title,
                    {
                        'content: ' .. format_rect(node:getContentRect()),
                        'resolved: ' .. format_rect(node:resolveContentRect(
                            case.content_width,
                            case.content_height
                        )),
                    }
                )
            end
        end,
    },
    {
        title = 'Stage Layer Precedence And Empty Target States',
        spec = 'Stage §6.4.1 layering + target probes + no-target observability',
        build = make_stage_screen,
        draw_overlay = function(ctx)
            draw_panel(
                18,
                love.graphics.getHeight() - 120,
                820,
                98,
                'Acceptance Notes',
                {
                    'Each card uses Stage-owned resolveTarget/deliverInput probes.',
                    'Overlay precedence is determined by Stage layers, not cross-layer zIndex.',
                    'The third card demonstrates an explicit no-target result.',
                }
            )

            for index = 1, #ctx.probes do
                local probe = ctx.probes[index]
                local delivery = ctx.stage:deliverInput({
                    kind = 'mousepressed',
                    x = probe.x,
                    y = probe.y,
                    button = 1,
                })

                rgba(colors.panel_line)
                love.graphics.rectangle(
                    'line',
                    probe.frame.x,
                    probe.frame.y,
                    probe.frame.width,
                    probe.frame.height,
                    10,
                    10
                )
                draw_probe(probe.x, probe.y, probe.title)
                draw_panel(
                    probe.frame.x + 10,
                    probe.frame.y + 10,
                    probe.frame.width - 20,
                    94,
                    probe.title,
                    {
                        'target: ' .. label_of(delivery.target),
                        'intent: ' .. tostring(delivery.intent),
                        'path: ' .. join_path(delivery.path),
                    }
                )
            end
        end,
    },
    {
        title = 'Two-Pass Failure Semantics',
        spec = 'Stage §6.4.1 two-pass contract + Foundation §3G hard failure',
        build = make_failure_screen,
        keypressed = function(ctx, key)
            if key ~= 't' then
                return
            end

            local ok, err

            ctx.stage:update(0)
            ctx.stage:draw(make_probe_graphics(), function()
            end)

            ok, err = pcall(function()
                ctx.stage:draw(make_probe_graphics(), function()
                end)
            end)

            if ok then
                ctx.repeat_failure = 'unexpectedly succeeded'
            else
                ctx.repeat_failure = tostring(err)
            end
        end,
        draw_overlay = function(ctx)
            draw_panel(
                18,
                love.graphics.getHeight() - 120,
                520,
                98,
                'Caught Hard Failures',
                {
                    'startup draw-before-update:',
                    ctx.startup_failure,
                }
            )
            draw_panel(
                554,
                love.graphics.getHeight() - 120,
                love.graphics.getWidth() - 572,
                98,
                'Repeatable Probe',
                {
                    '[T] draw twice in one frame',
                    ctx.repeat_failure,
                }
            )

            local target = ctx.stage:resolveTarget(ctx.probe.x, ctx.probe.y)
            local delivery = ctx.stage:deliverInput({
                kind = 'mousepressed',
                x = ctx.probe.x,
                y = ctx.probe.y,
                button = 1,
            })

            draw_probe(ctx.probe.x, ctx.probe.y, 'stable probe')
            draw_panel(
                18,
                HEADER_HEIGHT + 16,
                360,
                94,
                'Graceful Degradation Check',
                {
                    'target after caught error: ' .. label_of(target),
                    'delivery path: ' .. join_path(delivery.path),
                    'The stage remains usable after the hard failure is caught.',
                }
            )
        end,
    },
}

local function rebuild_current()
    destroy_current()

    local definition = screens[current_index]

    current_screen = {
        definition = definition,
        ctx = definition.build(love.graphics.getWidth(), love.graphics.getHeight()),
    }
end

function love.load()
    love.graphics.setBackgroundColor(0.07, 0.08, 0.10, 1)
    rebuild_current()
end

function love.update(dt)
    local definition = current_screen.definition
    local ctx = current_screen.ctx

    if definition.update ~= nil then
        definition.update(ctx, dt)
    end

    ctx.stage:update(dt)
end

function love.draw()
    local definition = current_screen.definition
    local ctx = current_screen.ctx

    ctx.last_draw_order = {}

    ctx.stage:draw(love.graphics, function(node)
        ctx.last_draw_order[#ctx.last_draw_order + 1] = label_of(node)

        if definition.draw_stage ~= nil then
            definition.draw_stage(ctx, node)
            return
        end

        draw_demo_node(node)
    end)

    if definition.after_draw ~= nil then
        definition.after_draw(ctx)
    end

    draw_header(definition)

    if definition.draw_overlay ~= nil then
        definition.draw_overlay(ctx)
    end
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
        return
    end

    if current_screen.definition.keypressed ~= nil then
        current_screen.definition.keypressed(current_screen.ctx, key)
    end
end

function love.resize(_, _)
    rebuild_current()
end

function love.quit()
    destroy_current()
end
