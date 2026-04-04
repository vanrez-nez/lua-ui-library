local DemoColors = require('demos.common.colors')
local Hint = require('demos.common.hint')
local UI = require('lib.ui')

local Container = UI.Container
local Stage = UI.Stage

local ScreenHelper = {
    round = Hint.round,
    format_rect = Hint.format_rect,
    badge = Hint.badge,
    set_hint = Hint.set_hint,
    set_hint_name = Hint.set_hint_name,
}
ScreenHelper._draw_context = nil

local function random_range(minimum, maximum)
    if maximum <= minimum then
        return minimum
    end

    return love.math.random(minimum, maximum)
end

local function format_value(value)
    if value == nil then
        return 'nil'
    end

    if type(value) == 'number' then
        return tostring(ScreenHelper.round(value))
    end

    return tostring(value)
end

local function set_color_with_alpha(graphics, color, alpha)
    graphics.setColor(color[1], color[2], color[3], (color[4] or 1) * alpha)
end

local function get_world_quad(node)
    local bounds = node:getLocalBounds()
    local x1, y1 = node:localToWorld(0, 0)
    local x2, y2 = node:localToWorld(bounds.width, 0)
    local x3, y3 = node:localToWorld(bounds.width, bounds.height)
    local x4, y4 = node:localToWorld(0, bounds.height)

    return {
        x1, y1,
        x2, y2,
        x3, y3,
        x4, y4,
    }
end

local function make_text_entry(label, text)
    return {
        label = label,
        badges = {
            Hint.badge(nil, text),
        },
    }
end

local function append_badge_entry(entries, label, keys, source)
    if keys == false or keys == nil then
        return
    end

    local badges = {}
    for index = 1, #keys do
        local key = keys[index]
        badges[#badges + 1] = Hint.badge(key, format_value(source[key]))
    end

    if #badges > 0 then
        entries[#entries + 1] = {
            label = label,
            badges = badges,
        }
    end
end

local function append_grouped_rows(entries, groups, sources)
    if type(groups) ~= 'table' then
        return false
    end

    for index = 1, #groups do
        local group = groups[index]
        local label = group.label
        local source_name = group.source or 'opts'
        local keys = group.keys
        append_badge_entry(entries, label, keys, sources[source_name] or {})
    end

    return #groups > 0
end

local function draw_point_marker(graphics, x, y, color)
    local cross_radius = 4
    local circle_radius = 6

    graphics.setColor(color)
    graphics.circle('line', x, y, circle_radius)
    graphics.line(x - cross_radius, y, x + cross_radius, y)
    graphics.line(x, y - cross_radius, x, y + cross_radius)
end

local function draw_anchor_marker(graphics, node, color)
    if node.parent == nil then
        return
    end

    local parent_bounds = node.parent:getLocalBounds()
    local anchor_x = (node.anchorX or 0) * parent_bounds.width
    local anchor_y = (node.anchorY or 0) * parent_bounds.height
    local world_x, world_y = node.parent:localToWorld(anchor_x, anchor_y)
    draw_point_marker(graphics, world_x, world_y, color)
end

local function draw_pivot_marker(graphics, node, color)
    local bounds = node:getLocalBounds()
    local pivot_x = (node.pivotX or 0) * bounds.width
    local pivot_y = (node.pivotY or 0) * bounds.height
    local world_x, world_y = node:localToWorld(pivot_x, pivot_y)
    draw_point_marker(graphics, world_x, world_y, color)
end

local function normalize_module_path(path)
    if type(path) ~= 'string' or path == '' then
        return nil
    end

    path = path:gsub('\\', '/')

    local demos_index = path:find('/demos/', 1, true)
    if demos_index ~= nil then
        path = path:sub(demos_index + 1)
    end

    if path:sub(1, 6) ~= 'demos/' then
        local relative_demos_index = path:find('demos/', 1, true)
        if relative_demos_index == nil then
            return nil
        end
        path = path:sub(relative_demos_index)
    end

    if not path:match('%.lua$') then
        return nil
    end

    path = path:gsub('%.lua$', '')
    path = path:gsub('[/\\]+', '.')
    path = path:gsub('^%.+', '')

    return path
end

local function resolve_companion_setup_module(build)
    local info = debug.getinfo(build, 'S')
    local source = info and info.source or nil
    if type(source) ~= 'string' or source:sub(1, 1) ~= '@' then
        return nil
    end

    local path = source:sub(2)
    local module_path = normalize_module_path(path)
    if module_path == nil then
        return nil
    end

    return module_path .. '_setup'
end

local function install_companion_setup(build, args)
    local module_name = resolve_companion_setup_module(build)
    if module_name == nil then
        return
    end

    local ok, result = pcall(require, module_name)
    if not ok then
        if type(result) == 'string' and result:find("module '" .. module_name .. "' not found", 1, true) ~= nil then
            return
        end
        error(result, 0)
    end

    if type(result) == 'table' and type(result.install) == 'function' then
        result.install(args)
    end
end

function ScreenHelper.random_root_position(width, height, margin)
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

function ScreenHelper.make_size_pulse(node, base_width, base_height, width_amplitude, height_amplitude, speed)
    local phase = love.math.random() * (math.pi * 2)
    local pulse_speed = speed or 1.2
    local pulse_width = width_amplitude or 24
    local pulse_height = height_amplitude or 18

    return function(dt)
        local resolved_width = base_width
        local resolved_height = base_height

        if type(base_width) == 'function' then
            resolved_width = base_width()
        end

        if type(base_height) == 'function' then
            resolved_height = base_height()
        end

        phase = phase + (dt * pulse_speed)
        node.width = ScreenHelper.round(resolved_width + (math.sin(phase) * pulse_width))
        node.height = ScreenHelper.round(resolved_height + (math.cos(phase) * pulse_height))
    end
end

function ScreenHelper.make_stage()
    return Stage.new({
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
    })
end

function ScreenHelper.is_visible(node)
    local effective_values = rawget(node, '_effective_values')
    return not (effective_values ~= nil and effective_values.visible == false)
end

function ScreenHelper.set_inspect_props(node, prop_keys)
    rawset(node, '_demo_inspect_props', prop_keys)
    return node
end

function ScreenHelper.set_hint_fields(node, fields)
    rawset(node, '_demo_hint_fields', fields)
    return node
end

function ScreenHelper.set_markers(node, markers)
    rawset(node, '_demo_markers', markers)
    return node
end

function ScreenHelper.get_hint_entries(node)
    return Hint.resolve_entries(node, function(current)
        local opts = rawget(current, '_demo_opts') or {}
        local local_bounds = current:getLocalBounds()
        local world_bounds = current:getWorldBounds()
        local hint_fields = rawget(current, '_demo_hint_fields') or {}
        local inspect_props = rawget(current, '_demo_inspect_props') or hint_fields.props or { 'x', 'y', 'width', 'height' }
        local sources = {
            opts = opts,
            local_bounds = {
                x = local_bounds.x,
                y = local_bounds.y,
                w = local_bounds.width,
                h = local_bounds.height,
            },
            world_bounds = {
                x = world_bounds.x,
                y = world_bounds.y,
                w = world_bounds.width,
                h = world_bounds.height,
            },
            visible = {
                value = tostring(ScreenHelper.is_visible(current)),
            },
            clamp = {
                minW = opts.minWidth,
                maxW = opts.maxWidth,
                minH = opts.minHeight,
                maxH = opts.maxHeight,
            },
        }
        local entries = {}

        if not append_grouped_rows(entries, hint_fields.rows, sources) then
            append_badge_entry(entries, 'props', inspect_props, sources.opts)
            append_badge_entry(entries, 'local', hint_fields['local'], sources.local_bounds)
            append_badge_entry(entries, 'world', hint_fields.world, sources.world_bounds)

            if hint_fields.visible == true then
                entries[#entries + 1] = {
                    label = 'visible',
                    badges = {
                        Hint.badge(nil, sources.visible.value),
                    },
                }
            end

            append_badge_entry(entries, 'clamp', hint_fields.clamp, sources.clamp)
        end

        return entries
    end, {
        string_entry_factory = function(text)
            return make_text_entry('info', text)
        end,
    })
end

function ScreenHelper.draw_hover_overlay(graphics)
    local draw_context = ScreenHelper._draw_context
    local hovered_node = draw_context and draw_context.hovered_node or nil
    local payload = hovered_node and Hint.resolve_payload(hovered_node, function(current)
        return ScreenHelper.get_hint_entries(current)
    end, {
        string_entry_factory = function(text)
            return make_text_entry('info', text)
        end,
    }) or nil
    Hint.draw_hover_overlay(graphics, draw_context, payload)
end

function ScreenHelper.draw_demo_node(graphics, node)
    if not rawget(node, '_demo_box') or not ScreenHelper.is_visible(node) then
        return
    end

    local draw_context = ScreenHelper._draw_context
    local bounds = node:getWorldBounds()
    local local_bounds = node:getLocalBounds()
    local quad = get_world_quad(node)
    local label = rawget(node, '_demo_label') or (node.tag or 'container')
    local fill_color = rawget(node, '_demo_fill_color') or DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24)
    local line_color = rawget(node, '_demo_line_color') or DemoColors.roles.accent_blue_line
    local is_hovered = false

    if draw_context ~= nil and node:containsPoint(draw_context.mouse_x, draw_context.mouse_y) then
        is_hovered = true

        local area = math.max(1, bounds.width * bounds.height)
        if draw_context.hovered_area == nil or area <= draw_context.hovered_area then
            draw_context.hovered_area = area
            draw_context.hovered_node = node
        end
    end

    set_color_with_alpha(graphics, fill_color, is_hovered and 1 or 0.75)
    graphics.polygon('fill', quad)
    set_color_with_alpha(graphics, line_color, is_hovered and 1 or 0.75)
    graphics.polygon('line', quad)
    graphics.setColor(DemoColors.roles.body)

    local label_x, label_y = node:localToWorld(
        math.min(8, math.max(0, local_bounds.width - 8)),
        math.min(8, math.max(0, local_bounds.height - 8))
    )
    graphics.print(label, label_x, label_y)
end

function ScreenHelper.draw_demo_markers(graphics, node)
    if not rawget(node, '_demo_box') or not ScreenHelper.is_visible(node) then
        return
    end

    local markers = rawget(node, '_demo_markers')
    if markers == nil then
        return
    end

    for index = 1, #markers do
        local marker = markers[index]
        local marker_type = marker.type
        local color = marker.color or DemoColors.roles.accent_highlight

        if marker_type == 'anchor' then
            draw_anchor_marker(graphics, node, color)
        elseif marker_type == 'pivot' then
            draw_pivot_marker(graphics, node, color)
        end
    end
end

function ScreenHelper.mark_box(node, label, fill_color, line_color)
    rawset(node, '_demo_box', true)
    rawset(node, '_demo_label', label)
    Hint.set_hint_name(node, label)
    rawset(node, '_demo_fill_color', fill_color)
    rawset(node, '_demo_line_color', line_color)
    return node
end

function ScreenHelper.make_node(scope, parent, opts, label, fill_color, line_color)
    local node = ScreenHelper.mark_box(Container.new(opts), label, fill_color, line_color)
    rawset(node, '_demo_opts', opts)
    parent:addChild(node)

    return node
end

function ScreenHelper.sync_stage(stage)
    stage:resize(love.graphics.getWidth(), love.graphics.getHeight())
    stage:update(0)
end

function ScreenHelper.screen_wrapper(owner, helpers, description, build)
    if type(helpers) ~= 'table' then
        build = description
        description = helpers
        helpers = ScreenHelper
    end

    if type(description) == 'function' and build == nil then
        build = description
        description = nil
    end

    return function(index, scope)
        local stage = ScreenHelper.make_stage()
        local state = build(scope, stage)

        install_companion_setup(build, {
            scope = scope,
            owner = owner,
            helpers = helpers,
            stage = stage,
            root = stage.baseSceneLayer,
            state = state,
        })

        local stage_hooks = rawget(stage, '_demo_screen_hooks') or {}
        local info_index = nil
        local screen_title = state.title or 'No Title'
        local header_description = state.description

        if header_description == nil then
            header_description = description
        end

        if state.sidebar ~= nil then
            info_index = owner:add_info_item(state.sidebar_title or screen_title, {})
        end

        owner:set_title(screen_title)
        owner:set_description(header_description)

        return {
            release = function()
                if rawget(stage, '_destroyed') ~= true then
                    stage:destroy()
                end
            end,
            keypressed = function(_, key)
                if type(stage_hooks.keypressed) == 'function' then
                    return stage_hooks.keypressed(key) == true
                end

                if type(state.keypressed) == 'function' then
                    return state:keypressed(key) == true
                end

                return false
            end,
            mousepressed = function(_, x, y, button)
                if type(stage_hooks.mousepressed) == 'function' then
                    return stage_hooks.mousepressed(x, y, button) == true
                end

                if type(state.mousepressed) == 'function' then
                    return state:mousepressed(x, y, button) == true
                end

                return false
            end,
            update = function(_, dt)
                stage:resize(love.graphics.getWidth(), love.graphics.getHeight())

                if type(stage_hooks.update) == 'function' then
                    stage_hooks.update(dt)
                end

                if type(state.update) == 'function' then
                    state.update(dt)
                end

                stage:update(dt)

                if type(stage_hooks.after_update) == 'function' then
                    if stage_hooks.after_update(dt) == true then
                        stage:update(0)
                    end
                end

                if type(helpers.sync_stage_visuals) == 'function' then
                    helpers.sync_stage_visuals(stage, dt)
                end

                owner:set_title(screen_title)
                owner:set_description(header_description)

                if info_index ~= nil then
                    owner:set_info_title(info_index, state.sidebar_title or screen_title)
                    owner:set_info_lines(info_index, state.sidebar(index, owner:get_screen_count()))
                end
            end,
            draw = function()
                if not rawget(stage, '_update_ran') then
                    ScreenHelper.sync_stage(stage)
                end

                local mouse_x, mouse_y = love.mouse.getPosition()
                helpers._draw_context = {
                    mouse_x = mouse_x,
                    mouse_y = mouse_y,
                    hovered_node = nil,
                    hovered_area = nil,
                }

                if type(stage_hooks.draw_under) == 'function' then
                    stage_hooks.draw_under(love.graphics)
                end

                if type(helpers.draw_stage) == 'function' then
                    helpers.draw_stage(stage, love.graphics)
                else
                    stage:draw(love.graphics, function(node)
                        if type(helpers.draw_demo_node) == 'function' then
                            helpers.draw_demo_node(love.graphics, node)
                        end

                        if type(helpers.draw_demo_markers) == 'function' then
                            helpers.draw_demo_markers(love.graphics, node)
                        end
                    end)
                end

                if type(stage_hooks.draw_overlay) == 'function' then
                    stage_hooks.draw_overlay(love.graphics)
                end

                if type(state.draw_overlay) == 'function' then
                    state.draw_overlay(love.graphics)
                end

                if type(helpers.draw_hover_overlay) == 'function' then
                    helpers.draw_hover_overlay(love.graphics)
                end

                helpers._draw_context = nil
            end,
        }
    end
end

return ScreenHelper
