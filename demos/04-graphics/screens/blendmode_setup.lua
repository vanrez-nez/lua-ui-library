local DemoColors = require('demos.common.colors')
local NativeControls = require('demos.common.native_controls')

local Setup = {}

local DARK_GRID_PRIMARY = DemoColors.names.slate_900
local DARK_GRID_SECONDARY = DemoColors.names.slate_800
local LIGHT_GRID_PRIMARY = DemoColors.names.slate_100
local LIGHT_GRID_SECONDARY = DemoColors.names.slate_400
local MID_GRID_PRIMARY = DemoColors.names.slate_500
local MID_GRID_SECONDARY = DemoColors.names.slate_400

local PRESET_OPTIONS = {
    {
        label = 'Normal',
        blendMode = 'normal',
        nodeOpacity = 1,
        gridPrimary = MID_GRID_PRIMARY,
        gridSecondary = MID_GRID_SECONDARY,
    },
    {
        label = 'Add',
        blendMode = 'add',
        nodeOpacity = 0.6,
        gridPrimary = DARK_GRID_PRIMARY,
        gridSecondary = DARK_GRID_SECONDARY,
    },
    {
        label = 'Subtract',
        blendMode = 'subtract',
        nodeOpacity = 0.6,
        gridPrimary = LIGHT_GRID_PRIMARY,
        gridSecondary = LIGHT_GRID_SECONDARY,
    },
    {
        label = 'Multiply',
        blendMode = 'multiply',
        nodeOpacity = 1,
        gridPrimary = LIGHT_GRID_PRIMARY,
        gridSecondary = DemoColors.names.slate_400,
    },
    {
        label = 'Screen',
        blendMode = 'screen',
        nodeOpacity = 1,
        gridPrimary = DARK_GRID_PRIMARY,
        gridSecondary = DARK_GRID_SECONDARY,
    },
    {
        label = 'Lighten',
        blendMode = 'lighten',
        nodeOpacity = 1,
        gridPrimary = DARK_GRID_PRIMARY,
        gridSecondary = DARK_GRID_SECONDARY,
    },
    {
        label = 'Darken',
        blendMode = 'darken',
        nodeOpacity = 1,
        gridPrimary = LIGHT_GRID_PRIMARY,
        gridSecondary = DemoColors.names.slate_400,
    },
    {
        label = 'Replace',
        blendMode = 'replace',
        nodeOpacity = 1,
        gridPrimary = MID_GRID_PRIMARY,
        gridSecondary = MID_GRID_SECONDARY,
    },
}

local FOOTER_RESERVED_HEIGHT = 44
local FOOTER_NOTE_WIDTH_FRACTION = 0.6
local FOOTER_NOTE_BOTTOM_PADDING = 8
local FOOTER_NOTE_BOTTOM_OFFSET_MULTIPLIER = 1.15
local FOOTER_NOTE_TEXT = 'Click on each item to send it to the front. Inspect the actual overlap in each frame as you switch blend presets and stacking order.'
local FRAME_CONTENT_INSET = 1

local function cycle_index(index, delta, total)
    local next_index = index + delta

    if next_index < 1 then
        return total
    end

    if next_index > total then
        return 1
    end

    return next_index
end

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('blendmode_setup: missing node "' .. id .. '"', 2)
    end
    return node
end

local function set_simple_hint(helpers, node, name)
    helpers.set_hint_name(node, name)
    helpers.set_hint(node, function(current)
        return {
            {
                label = 'blendMode',
                badges = {
                    helpers.badge(nil, tostring(current.blendMode or 'nil')),
                },
            },
            {
                label = 'opacity',
                badges = {
                    helpers.badge(nil, helpers.format_scalar(current.opacity)),
                },
            },
        }
    end)
end

local function apply_grid_preset(background_node, preset)
    rawset(background_node, '_grid_primary_color', preset.gridPrimary or DARK_GRID_PRIMARY)
    rawset(background_node, '_grid_secondary_color', preset.gridSecondary or DARK_GRID_SECONDARY)
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local scope = args.scope
    local stage = args.stage
    local title_font = scope:font(12)
    local note_font = scope:font(11)
    local drawable_frame = find_required(root, 'blendmode-drawable-frame')
    local shape_frame = find_required(root, 'blendmode-shape-frame')
    local drawable_group = find_required(root, 'blendmode-drawable-group')
    local shape_group = find_required(root, 'blendmode-shape-group')
    local drawable_background = find_required(root, 'blendmode-drawable-background')
    local shape_background = find_required(root, 'blendmode-shape-background')
    local drawable_nodes = {
        find_required(root, 'blendmode-drawable-a'),
        find_required(root, 'blendmode-drawable-b'),
        find_required(root, 'blendmode-drawable-c'),
    }
    local shape_nodes = {
        find_required(root, 'blendmode-shape-a'),
        find_required(root, 'blendmode-shape-b'),
        find_required(root, 'blendmode-shape-c'),
    }
    local active_preset_index = 1
    local preset_layout = nil
    local next_drawable_z_index = 1
    local next_shape_z_index = 1

    local function active_preset()
        return PRESET_OPTIONS[active_preset_index]
    end

    local function sync_layout()
        local screen_width = stage.width
        local screen_height = stage.height
        local frame_gap = 60
        local total_width = drawable_frame.width + frame_gap + shape_frame.width
        local base_x = math.floor((screen_width - total_width) * 0.5 + 0.5)
        local frame_y = math.floor((screen_height - drawable_frame.height) * 0.5 + 50.5)
        local base_preset_y = 120
        local nav_height = title_font:getHeight() + 12
        local base_gap = frame_y - (base_preset_y + nav_height)
        local preset_y = math.floor(frame_y - nav_height - (base_gap * 0.5) + 0.5)

        preset_layout = NativeControls.build_centered_navigator_layout(
            screen_width,
            preset_y,
            title_font,
            active_preset().label
        )

        drawable_frame.x = base_x
        drawable_frame.y = frame_y
        shape_frame.x = base_x + drawable_frame.width + frame_gap
        shape_frame.y = frame_y
        drawable_group.x = FRAME_CONTENT_INSET
        drawable_group.y = FRAME_CONTENT_INSET
        shape_group.x = FRAME_CONTENT_INSET
        shape_group.y = FRAME_CONTENT_INSET
    end

    local function apply_preset(nodes, preset)
        for index = 1, #nodes do
            nodes[index].blendMode = preset.blendMode
            nodes[index].opacity = preset.nodeOpacity or 1
        end
    end

    local function set_active_preset(index)
        active_preset_index = index
        apply_preset(drawable_nodes, active_preset())
        apply_preset(shape_nodes, active_preset())
        apply_grid_preset(drawable_background, active_preset())
        apply_grid_preset(shape_background, active_preset())
        sync_layout()
    end

    rawset(drawable_nodes[1], '_demo_label', 'A')
    rawset(drawable_nodes[2], '_demo_label', 'B')
    rawset(drawable_nodes[3], '_demo_label', 'C')

    rawset(shape_nodes[1], '_demo_label', 'A')
    rawset(shape_nodes[2], '_demo_label', 'B')
    rawset(shape_nodes[3], '_demo_label', 'C')
    rawset(shape_nodes[1], '_demo_label_align', 'center')
    rawset(shape_nodes[2], '_demo_label_align', 'center')
    rawset(shape_nodes[3], '_demo_label_align', 'center')
    rawset(shape_nodes[1], '_demo_label_valign', 'center')
    rawset(shape_nodes[2], '_demo_label_valign', 'center')
    rawset(shape_nodes[3], '_demo_label_valign', 'center')

    set_simple_hint(helpers, drawable_nodes[1], 'Drawable A')
    set_simple_hint(helpers, drawable_nodes[2], 'Drawable B')
    set_simple_hint(helpers, drawable_nodes[3], 'Drawable C')
    set_simple_hint(helpers, shape_nodes[1], 'Shape A')
    set_simple_hint(helpers, shape_nodes[2], 'Shape B')
    set_simple_hint(helpers, shape_nodes[3], 'Shape C')

    set_active_preset(active_preset_index)

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            sync_layout()
        end,
        mousepressed = function(x, y, button)
            if button ~= 1 or preset_layout == nil then
                return false
            end

            if NativeControls.point_in_rect(preset_layout.left, x, y) then
                set_active_preset(cycle_index(active_preset_index, -1, #PRESET_OPTIONS))
                return true
            end

            if NativeControls.point_in_rect(preset_layout.right, x, y) then
                set_active_preset(cycle_index(active_preset_index, 1, #PRESET_OPTIONS))
                return true
            end

            local drawable_target = drawable_group:_hit_test(x, y)
            if drawable_target ~= nil then
                drawable_target.zIndex = next_drawable_z_index
                next_drawable_z_index = next_drawable_z_index + 1
                return true
            end

            local shape_target = shape_group:_hit_test(x, y)
            if shape_target ~= nil then
                shape_target.zIndex = next_shape_z_index
                next_shape_z_index = next_shape_z_index + 1
                return true
            end

            return false
        end,
        draw_overlay = function(graphics)
            local mouse_x, mouse_y = love.mouse.getPosition()
            local hovered_preset_left = preset_layout ~= nil and
                NativeControls.point_in_rect(preset_layout.left, mouse_x, mouse_y)
            local hovered_preset_right = preset_layout ~= nil and
                NativeControls.point_in_rect(preset_layout.right, mouse_x, mouse_y)

            graphics.setColor(DemoColors.roles.text_muted)
            graphics.setFont(title_font)
            graphics.print(
                'Preset',
                preset_layout.body.x + math.floor((preset_layout.body.width - title_font:getWidth('Preset')) * 0.5 + 0.5),
                preset_layout.body.y - title_font:getHeight() - 10
            )
            NativeControls.draw_navigator(
                graphics,
                title_font,
                preset_layout,
                active_preset().label,
                hovered_preset_left,
                hovered_preset_right,
                DemoColors.roles.border_light
            )

            graphics.setColor(DemoColors.roles.text_muted)
            graphics.print(
                'Drawable',
                drawable_frame.x + math.floor((drawable_frame.width - title_font:getWidth('Drawable')) * 0.5 + 0.5),
                drawable_frame.y + drawable_frame.height + 12
            )
            graphics.print(
                'Shape',
                shape_frame.x + math.floor((shape_frame.width - title_font:getWidth('Shape')) * 0.5 + 0.5),
                shape_frame.y + shape_frame.height + 12
            )

            local note_width = math.floor(stage.width * FOOTER_NOTE_WIDTH_FRACTION + 0.5)
            local note_x = math.floor((stage.width - note_width) * 0.5 + 0.5)
            local note_bottom_offset = math.floor(
                (FOOTER_RESERVED_HEIGHT + FOOTER_NOTE_BOTTOM_PADDING) * FOOTER_NOTE_BOTTOM_OFFSET_MULTIPLIER + 0.5
            )
            local _, wrapped_lines = note_font:getWrap(FOOTER_NOTE_TEXT, note_width)
            local note_height = #wrapped_lines * note_font:getHeight()

            graphics.setColor(DemoColors.roles.text_subtle)
            graphics.setFont(note_font)
            graphics.printf(
                FOOTER_NOTE_TEXT,
                note_x,
                stage.height - note_height - note_bottom_offset,
                note_width,
                'center'
            )
        end,
    })
end

return Setup
