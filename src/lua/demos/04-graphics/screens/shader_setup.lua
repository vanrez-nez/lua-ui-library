local DemoColors = require('demos.common.colors')

local Setup = {}

local FRAME_GAP_X = 26
local FRAME_GAP_Y = 44
local ROW_TITLE_GAP = 22
local FOOTER_NOTE_WIDTH = 760
local FOOTER_NOTE_BOTTOM_PADDING = 10
local FOOTER_NOTE_TEXT = 'Root shader is part of the shared root-compositing surface. Each column reuses the same shader preset on a Drawable subtree and a Shape result so the screen shows post-composite shader behavior, not part-local recoloring.'

local CASES = {
    {
        id = 'off',
        label = 'Off',
    },
    {
        id = 'duotone',
        label = 'Duotone',
    },
    {
        id = 'posterize',
        label = 'Posterize',
    },
    {
        id = 'scanlines',
        label = 'Scanlines',
    },
}

local function round(value)
    return math.floor((value or 0) + 0.5)
end

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('shader_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function set_frame_label(frame, label)
    rawset(frame, '_demo_label', label)
    rawset(frame, '_demo_label_align', 'center')
    rawset(frame, '_demo_label_valign', 'start')
    rawset(frame, '_demo_label_inset_y', 10)
end

local function set_frame_hint(helpers, frame, target, surface_name, shader_label, rect_label)
    helpers.set_hint_name(frame, surface_name .. ' / ' .. shader_label)
    helpers.set_hint(frame, function()
        local rect = rect_label == 'content' and target:getContentRect() or target:getLocalBounds()

        return {
            {
                label = 'surface',
                badges = {
                    helpers.badge(nil, surface_name),
                },
            },
            {
                label = 'root',
                badges = {
                    helpers.badge('shader', shader_label),
                    helpers.badge('opacity', helpers.format_scalar(target.opacity)),
                    helpers.badge('blendMode', tostring(target.blendMode)),
                },
            },
            {
                label = 'rect.' .. rect_label,
                badges = {
                    helpers.badge(rect_label, helpers.format_rect(rect)),
                },
            },
        }
    end)
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local stage = args.stage
    local title_font = love.graphics.newFont(13)
    local note_font = love.graphics.newFont(11)
    local drawable_frames = {}
    local shape_frames = {}
    local overlay_layout = nil

    for index = 1, #CASES do
        local case = CASES[index]
        local drawable_frame = find_required(root, 'shader-' .. case.id .. '-drawable-frame')
        local drawable_target = find_required(root, 'shader-' .. case.id .. '-drawable-target')
        local shape_frame = find_required(root, 'shader-' .. case.id .. '-shape-frame')
        local shape_target = find_required(root, 'shader-' .. case.id .. '-shape-target')

        set_frame_label(drawable_frame, case.label)
        set_frame_label(shape_frame, case.label)
        set_frame_hint(helpers, drawable_frame, drawable_target, 'Drawable subtree', case.label, 'content')
        set_frame_hint(helpers, shape_frame, shape_target, 'RectShape fill + stroke', case.label, 'bounds')

        drawable_frames[#drawable_frames + 1] = drawable_frame
        shape_frames[#shape_frames + 1] = shape_frame
    end

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            local frame_width = drawable_frames[1].width
            local frame_height = drawable_frames[1].height
            local total_width = (frame_width * #CASES) + (FRAME_GAP_X * (#CASES - 1))
            local total_height = (frame_height * 2) + FRAME_GAP_Y
            local base_x = round((stage.width - total_width) * 0.5)
            local base_y = round((stage.height - total_height) * 0.5 + 18)

            for index = 1, #CASES do
                local x = base_x + ((index - 1) * (frame_width + FRAME_GAP_X))

                drawable_frames[index].x = x
                drawable_frames[index].y = base_y
                shape_frames[index].x = x
                shape_frames[index].y = base_y + frame_height + FRAME_GAP_Y
            end

            overlay_layout = {
                drawable_title_x = base_x,
                drawable_title_y = base_y - title_font:getHeight() - ROW_TITLE_GAP,
                shape_title_x = base_x,
                shape_title_y = base_y + frame_height + FRAME_GAP_Y - title_font:getHeight() - ROW_TITLE_GAP,
                note_x = round((stage.width - FOOTER_NOTE_WIDTH) * 0.5),
                note_y = stage.height - note_font:getHeight() - FOOTER_NOTE_BOTTOM_PADDING,
            }
        end,
        draw_overlay = function(graphics)
            if overlay_layout == nil then
                return
            end

            graphics.setFont(title_font)
            graphics.setColor(DemoColors.roles.text)
            graphics.print('Drawable subtree', overlay_layout.drawable_title_x, overlay_layout.drawable_title_y)
            graphics.print('Shape fill + stroke', overlay_layout.shape_title_x, overlay_layout.shape_title_y)

            graphics.setFont(note_font)
            graphics.setColor(DemoColors.roles.text_muted)
            graphics.printf(
                FOOTER_NOTE_TEXT,
                overlay_layout.note_x,
                overlay_layout.note_y,
                FOOTER_NOTE_WIDTH,
                'center'
            )
        end,
    })
end

return Setup
