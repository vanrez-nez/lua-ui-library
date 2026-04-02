package.path = '../../?.lua;../../?/init.lua;' .. package.path
require('demos.common.bootstrap').init()

local DemoBase = require('demos.common.demo_base')
local DemoColors = require('demos.common.colors')
local UI = require('lib.ui')

local Stage = UI.Stage
local Container = UI.Container

local demo_base

local function round(value)
    return math.floor((value or 0) + 0.5)
end

local function format_rect(rect)
    return string.format(
        'x:%d y:%d w:%d h:%d',
        round(rect.x),
        round(rect.y),
        round(rect.width),
        round(rect.height)
    )
end

local function random_range(minimum, maximum)
    if maximum <= minimum then
        return minimum
    end

    return love.math.random(minimum, maximum)
end
local function random_root_position(width, height, margin)
    local viewport_width = love.graphics.getWidth()
    local viewport_height = love.graphics.getHeight()
    local inset = margin or 96
    local max_x = math.max(inset, viewport_width - width - inset)
    local max_y = math.max(inset, viewport_height - height - inset - 72)

    return {
        x = random_range(inset, max_x),
        y = random_range(inset, max_y),
    }
end

local function make_width_pulse(node, base_width, amplitude, speed)
    local phase = love.math.random() * (math.pi * 2)
    local pulse_speed = speed or 1.2
    local pulse_amplitude = amplitude or 24

    return function(dt)
        local resolved_base = base_width
        if type(base_width) == 'function' then
            resolved_base = base_width()
        end
        phase = phase + (dt * pulse_speed)
        node.width = round(resolved_base + (math.sin(phase) * pulse_amplitude))
    end
end

local function is_visible(node)
    local ev = rawget(node, '_effective_values')
    return not (ev ~= nil and ev.visible == false)
end

local function draw_demo_node(graphics, node)
    if not rawget(node, '_demo_box') or not is_visible(node) then
        return
    end

    local bounds = node:getWorldBounds()
    local label = rawget(node, '_demo_label') or (node.tag or 'container')
    local fill_color = rawget(node, '_demo_fill_color') or DemoColors.roles.accent_blue_fill
    local line_color = rawget(node, '_demo_line_color') or DemoColors.roles.accent_blue_line

    graphics.setColor(fill_color)
    graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
    graphics.setColor(line_color)
    graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 10, 10)
    graphics.setColor(DemoColors.roles.body)
    graphics.print(label, bounds.x + 8, bounds.y + 8)
end

local function make_stage(scope)
    local stage = Stage.new({
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
    })

    scope:on_cleanup(function()
        stage:destroy()
    end)

    return stage
end

local function mark_box(node, label, fill_color, line_color)
    rawset(node, '_demo_box', true)
    rawset(node, '_demo_label', label)
    rawset(node, '_demo_fill_color', fill_color)
    rawset(node, '_demo_line_color', line_color)
    return node
end

local function make_node(scope, parent, opts, label, fill_color, line_color)
    local node = mark_box(Container.new(opts), label, fill_color, line_color)
    parent:addChild(node)
    scope:on_cleanup(function()
        if rawget(node, '_destroyed') ~= true then
            node:destroy()
        end
    end)
    return node
end

local function sync_stage(stage)
    stage:resize(love.graphics.getWidth(), love.graphics.getHeight())
    stage:update(0)
end

local function screen_wrapper(owner, description, build)
    return function(index, scope)
        local stage = make_stage(scope)
        local state = build(scope, stage)
        local info_index = owner:add_info_item(state.title, {})
        local header_description = state.description or description
        owner:set_title(state.title)
        owner:set_description(header_description)

        return {
            update = function(_, dt)
                if type(state.update) == 'function' then
                    state.update(dt)
                end
                stage:resize(love.graphics.getWidth(), love.graphics.getHeight())
                stage:update(dt)
                owner:set_title(state.title)
                owner:set_description(header_description)
                owner:set_info_title(info_index, state.title)
                owner:set_info_lines(info_index, state.inspect(index, owner:get_screen_count()))
            end,
            draw = function()
                if not rawget(stage, '_update_ran') then
                    sync_stage(stage)
                end

                stage:draw(love.graphics, function(node)
                    draw_demo_node(love.graphics, node)
                end)
            end,
        }
    end
end

local function build_bounds_screen(scope, stage)
    local root = stage.baseSceneLayer
    local origin = random_root_position(340, 220, 120)

    local parent = make_node(scope, root, {
        x = origin.x,
        y = origin.y,
        width = 340,
        height = 220,
    }, 'parent', DemoColors.roles.accent_blue_fill, DemoColors.roles.accent_blue_line)

    local child = make_node(scope, parent, {
        x = 30,
        y = 24,
        width = 150,
        height = 92,
    }, 'child', DemoColors.roles.accent_green_fill, DemoColors.roles.accent_green_line)

    local grandchild = make_node(scope, child, {
        x = 18,
        y = 14,
        width = 78,
        height = 42,
    }, 'grandchild', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)

    return {
        title = 'Parent / Child Bounds',
        description = 'Verifies parent offset influence on child world coordinates while child local coordinates remain stable.',
        update = make_width_pulse(parent, 340, 42, 1.1),
        inspect = function(index, total)
            return {
                string.format('root offset  x:%d y:%d', round(origin.x), round(origin.y)),
                'parent local  ' .. format_rect(parent:getLocalBounds()),
                'parent world  ' .. format_rect(parent:getWorldBounds()),
                'child local   ' .. format_rect(child:getLocalBounds()),
                'child world   ' .. format_rect(child:getWorldBounds()),
                'grandchild local ' .. format_rect(grandchild:getLocalBounds()),
                'grandchild world ' .. format_rect(grandchild:getWorldBounds()),
            }
        end,
    }
end

local function build_sizing_screen(scope, stage)
    local root = stage.baseSceneLayer
    local origin = random_root_position(500, 300, 96)
    local frame = make_node(scope, root, {
        x = origin.x,
        y = origin.y,
        width = 500,
        height = 300,
    }, 'frame', DemoColors.roles.accent_violet_fill, DemoColors.roles.accent_violet_line)

    local fixed = make_node(scope, frame, {
        x = 20,
        y = 20,
        width = 120,
        height = 70,
    }, 'fixed 120x70', DemoColors.roles.accent_blue_fill, DemoColors.roles.accent_blue_line)

    local fill = make_node(scope, frame, {
        x = 160,
        y = 20,
        width = 'fill',
        height = 64,
    }, 'fill width', DemoColors.roles.accent_green_fill, DemoColors.roles.accent_green_line)

    local percent = make_node(scope, frame, {
        x = 20,
        y = 116,
        width = '50%',
        height = '40%',
    }, '50% / 40%', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)

    return {
        title = 'Fixed / Fill / Percent Sizing',
        description = 'Compares fixed, fill, and percentage width resolution inside one shared parent container.',
        update = make_width_pulse(frame, 500, 54, 1),
        inspect = function(index, total)
            return {
                string.format('root offset x:%d y:%d', round(origin.x), round(origin.y)),
                'frame       ' .. format_rect(frame:getLocalBounds()),
                'fixed       ' .. format_rect(fixed:getLocalBounds()),
                'fill width  ' .. format_rect(fill:getLocalBounds()),
                'percent     ' .. format_rect(percent:getLocalBounds()),
            }
        end,
    }
end

local function build_percentage_screen(scope, stage)
    local root = stage.baseSceneLayer
    local origin = random_root_position(420, 280, 96)

    local parent = make_node(scope, root, {
        x = origin.x,
        y = origin.y,
        width = '55%',
        height = '58%',
        minWidth = 360,
        minHeight = 240,
    }, '55% parent', DemoColors.roles.accent_cyan_fill, DemoColors.roles.accent_cyan_line)

    local child = make_node(scope, parent, {
        x = 24,
        y = 24,
        width = '50%',
        height = '50%',
    }, '50% child', DemoColors.roles.accent_green_fill, DemoColors.roles.accent_green_line)

    local nested = make_node(scope, child, {
        x = 12,
        y = 12,
        width = '50%',
        height = '50%',
    }, '50% nested', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)

    local pulse_parent_width = make_width_pulse(parent, function()
        return love.graphics.getWidth() * 0.55
    end, 64, 0.9)

    return {
        title = 'Nested Percentage Sizing',
        description = 'Shows percentage sizing recalculating from the effective parent region, including under resize.',
        update = pulse_parent_width,
        inspect = function(index, total)
            return {
                string.format('root offset x:%d y:%d', round(origin.x), round(origin.y)),
                'parent ' .. format_rect(parent:getLocalBounds()),
                'child  ' .. format_rect(child:getLocalBounds()),
                'nested ' .. format_rect(nested:getLocalBounds()),
            }
        end,
    }
end

local function build_clamp_screen(scope, stage)
    local root = stage.baseSceneLayer
    local origin = random_root_position(620, 310, 72)
    local frame = make_node(scope, root, {
        x = origin.x,
        y = origin.y,
        width = 620,
        height = 310,
    }, 'clamp frame', DemoColors.roles.accent_violet_fill, DemoColors.roles.accent_violet_line)

    local max_width = make_node(scope, frame, {
        x = 20,
        y = 24,
        width = 'fill',
        height = 70,
        maxWidth = 160,
    }, 'fill + maxWidth', DemoColors.roles.accent_blue_fill, DemoColors.roles.accent_blue_line)

    local min_width = make_node(scope, frame, {
        x = 220,
        y = 24,
        width = '20%',
        height = 70,
        minWidth = 120,
    }, '20% + minWidth', DemoColors.roles.accent_green_fill, DemoColors.roles.accent_green_line)

    local max_height = make_node(scope, frame, {
        x = 20,
        y = 124,
        width = 120,
        height = 'fill',
        maxHeight = 96,
    }, 'fill + maxHeight', DemoColors.roles.accent_red_fill, DemoColors.roles.accent_red_line)

    local min_height = make_node(scope, frame, {
        x = 220,
        y = 124,
        width = 120,
        height = '15%',
        minHeight = 72,
    }, '15% + minHeight', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)

    return {
        title = 'Min / Max Clamps',
        description = 'Shows min and max constraints clamping otherwise valid fixed, fill, and percentage sizes.',
        update = make_width_pulse(frame, 620, 84, 1.05),
        inspect = function(index, total)
            return {
                string.format('root offset x:%d y:%d', round(origin.x), round(origin.y)),
                'max width  ' .. format_rect(max_width:getLocalBounds()),
                'min width  ' .. format_rect(min_width:getLocalBounds()),
                'max height ' .. format_rect(max_height:getLocalBounds()),
                'min height ' .. format_rect(min_height:getLocalBounds()),
            }
        end,
    }
end

local function build_visibility_screen(scope, stage)
    local root = stage.baseSceneLayer
    local origin = random_root_position(500, 160, 96)

    local visible_parent = make_node(scope, root, {
        x = origin.x,
        y = origin.y,
        width = 220,
        height = 160,
    }, 'visible parent', DemoColors.roles.accent_blue_fill, DemoColors.roles.accent_blue_line)

    local visible_child = make_node(scope, visible_parent, {
        x = 20,
        y = 20,
        width = 120,
        height = 64,
    }, 'visible child', DemoColors.roles.accent_green_fill, DemoColors.roles.accent_green_line)

    local hidden_parent = make_node(scope, root, {
        x = origin.x + 280,
        y = origin.y,
        width = 220,
        height = 160,
        visible = false,
    }, 'hidden parent', DemoColors.roles.accent_red_fill, DemoColors.roles.accent_red_line)

    local hidden_child = make_node(scope, hidden_parent, {
        x = 20,
        y = 20,
        width = 120,
        height = 64,
    }, 'child of hidden', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)

    local pulse_visible_width = make_width_pulse(visible_parent, 220, 28, 1.15)

    return {
        title = 'Visibility',
        description = 'Demonstrates retained tree membership separately from effective drawing visibility.',
        update = function(dt)
            pulse_visible_width(dt)
            hidden_parent.width = visible_parent.width
        end,
        inspect = function(index, total)
            return {
                string.format('root offset x:%d y:%d', round(origin.x), round(origin.y)),
                'visible parent visible = true',
                'visible child draws = ' .. tostring(is_visible(visible_child)),
                'hidden parent visible = false',
                'hidden child effective draw = ' .. tostring(is_visible(hidden_child)),
            }
        end,
    }
end

local function build_zero_screen(scope, stage)
    local root = stage.baseSceneLayer
    local origin = random_root_position(242, 2, 120)

    local zero_parent = make_node(scope, root, {
        x = origin.x,
        y = origin.y,
        width = 0,
        height = 0,
    }, 'zero parent', DemoColors.roles.accent_red_fill, DemoColors.roles.accent_red_line)

    local zero_child = make_node(scope, zero_parent, {
        x = 0,
        y = 0,
        width = '50%',
        height = '50%',
    }, 'child of zero', DemoColors.roles.accent_amber_fill, DemoColors.roles.accent_amber_line)

    local tiny_parent = make_node(scope, root, {
        x = origin.x + 240,
        y = origin.y,
        width = 2,
        height = 2,
    }, 'tiny parent', DemoColors.roles.accent_blue_fill, DemoColors.roles.accent_blue_line)

    local tiny_child = make_node(scope, tiny_parent, {
        x = 0,
        y = 0,
        width = '50%',
        height = '50%',
    }, 'child of tiny', DemoColors.roles.accent_green_fill, DemoColors.roles.accent_green_line)

    return {
        title = 'Zero / Tiny Parent Edge Cases',
        description = 'Confirms degenerate parent sizes degrade cleanly without hard failure in descendant percentage sizing.',
        inspect = function(index, total)
            return {
                string.format('root offset x:%d y:%d', round(origin.x), round(origin.y)),
                'zero parent ' .. format_rect(zero_parent:getLocalBounds()),
                'zero child  ' .. format_rect(zero_child:getLocalBounds()),
                'tiny parent ' .. format_rect(tiny_parent:getLocalBounds()),
                'tiny child  ' .. format_rect(tiny_child:getLocalBounds()),
            }
        end,
    }
end

function love.load()
    demo_base = DemoBase.new({
        title = '01-container',
        description = 'Container contract coverage.',
    })

    demo_base:push_screen(screen_wrapper(
        demo_base,
        'Parent / child bounds, local versus world coordinates, and retained tree structure.',
        build_bounds_screen
    ))
    demo_base:push_screen(screen_wrapper(
        demo_base,
        'Fixed, fill, and percentage sizing in a single container frame.',
        build_sizing_screen
    ))
    demo_base:push_screen(screen_wrapper(
        demo_base,
        'Nested percentage sizing under resize.',
        build_percentage_screen
    ))
    demo_base:push_screen(screen_wrapper(
        demo_base,
        'Min and max clamp behavior across width and height.',
        build_clamp_screen
    ))
    demo_base:push_screen(screen_wrapper(
        demo_base,
        'Visibility behavior without mixing in later control systems.',
        build_visibility_screen
    ))
    demo_base:push_screen(screen_wrapper(
        demo_base,
        'Zero-size and tiny-parent edge cases.',
        build_zero_screen
    ))
end

function love.update(dt)
    demo_base:update(dt)
end

function love.draw()
    demo_base:begin_frame()
    love.graphics.clear(DemoColors.roles.background_alt)
    demo_base:draw()
end

function love.keypressed(key)
    demo_base:handle_keypressed(key)
end

function love.mousepressed(x, y, button)
    demo_base:handle_mousepressed(x, y, button)
end
