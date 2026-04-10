local DemoColors = require('demos.common.colors')
local NativeControls = require('demos.common.native_controls')
local TextureCommon = require('demos.04-graphics.screens.texture_common')

local Setup = {}

local PREVIEW_FRAME_WIDTH = 240
local PREVIEW_FRAME_HEIGHT = 240
local FRAME_CONTENT_INSET = 1
local FRAME_GAP = 50
local CONTROL_GAP = 20
local LABEL_GAP = 10
local ROW_GAP = 22

local function floor(value)
    return math.floor(value + 0.5)
end

local function build_navigator_layout(x, y, font, body_width)
    local arrow_width = 24
    local nav_height = font:getHeight() + 12

    return {
        left = {
            x = x,
            y = y,
            width = arrow_width,
            height = nav_height,
        },
        body = {
            x = x + arrow_width + 6,
            y = y,
            width = body_width,
            height = nav_height,
        },
        right = {
            x = x + arrow_width + 6 + body_width + 6,
            y = y,
            width = arrow_width,
            height = nav_height,
        },
    }
end

local function layout_width(layout)
    return layout.right.x + layout.right.width - layout.left.x
end

local function resolve_body_width(font, options)
    local width = 0

    for index = 1, #options do
        width = math.max(width, font:getWidth(options[index].label) + 28)
    end

    return width
end

local function build_row_layouts(screen_width, y, font, selectors)
    local total_width = 0
    local body_widths = {}
    local layouts = {}

    for index = 1, #selectors do
        local selector = selectors[index]
        local body_width = resolve_body_width(font, selector.options)
        local layout = build_navigator_layout(0, y, font, body_width)

        body_widths[index] = body_width
        layouts[selector.id] = layout
        total_width = total_width + layout_width(layout)

        if index < #selectors then
            total_width = total_width + CONTROL_GAP
        end
    end

    local x = floor((screen_width - total_width) * 0.5)

    for index = 1, #selectors do
        local selector = selectors[index]

        layouts[selector.id] = build_navigator_layout(x, y, font, body_widths[index])
        x = x + layout_width(layouts[selector.id]) + CONTROL_GAP
    end

    return layouts
end

local function draw_selector(graphics, font, selector, layout, hovered_left, hovered_right, disabled)
    local title = selector.title

    graphics.setColor(DemoColors.roles.text_muted)
    graphics.setFont(font)
    graphics.print(
        title,
        layout.body.x + floor((layout.body.width - font:getWidth(title)) * 0.5),
        layout.body.y - font:getHeight() - LABEL_GAP
    )

    NativeControls.draw_navigator(
        graphics,
        font,
        layout,
        selector.options[selector.index].label,
        hovered_left,
        hovered_right,
        DemoColors.roles.border_light,
        disabled
    )
end

local function set_hint(helpers, node, source_selector, region_selector, align_x_selector, align_y_selector, offset_x_selector, offset_y_selector)
    helpers.set_hint_name(node, 'Drawable Background')
    helpers.set_hint(node, function()
        return {
            {
                label = 'source',
                badges = {
                    helpers.badge(nil, source_selector.options[source_selector.index].label),
                    helpers.badge('region', source_selector.options[source_selector.index].kind == 'texture'
                        and 'full'
                        or region_selector.options[region_selector.index].label),
                },
            },
            {
                label = 'align',
                badges = {
                    helpers.badge('x', align_x_selector.options[align_x_selector.index].value),
                    helpers.badge('y', align_y_selector.options[align_y_selector.index].value),
                },
            },
            {
                label = 'offset',
                badges = {
                    helpers.badge('x', tostring(offset_x_selector.options[offset_x_selector.index].value)),
                    helpers.badge('y', tostring(offset_y_selector.options[offset_y_selector.index].value)),
                },
            },
        }
    end)
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local scope = args.scope
    local stage = args.stage
    local font = scope:font(12)
    local frame = TextureCommon.find_required(root, 'texture-background-frame', 'texture_background_setup')
    local group = TextureCommon.find_required(root, 'texture-background-group', 'texture_background_setup')
    local target = TextureCommon.find_required(root, 'texture-background-target', 'texture_background_setup')
    local base_texture = target.backgroundImage
    local preview_frame, preview = TextureCommon.add_source_preview(
        root,
        'texture-background-preview',
        PREVIEW_FRAME_WIDTH,
        PREVIEW_FRAME_HEIGHT
    )
    local layouts = nil
    local source_selector = {
        id = 'source',
        title = 'Source',
        options = TextureCommon.SOURCE_OPTIONS,
        index = 2,
    }
    local region_selector = {
        id = 'region',
        title = 'Region',
        options = TextureCommon.REGION_OPTIONS,
        index = 3,
    }
    local align_x_selector = {
        id = 'align_x',
        title = 'Align X',
        options = TextureCommon.ALIGN_OPTIONS,
        index = 2,
    }
    local align_y_selector = {
        id = 'align_y',
        title = 'Align Y',
        options = TextureCommon.ALIGN_OPTIONS,
        index = 2,
    }
    local offset_x_selector = {
        id = 'offset_x',
        title = 'Offset X',
        options = TextureCommon.OFFSET_OPTIONS,
        index = 3,
    }
    local offset_y_selector = {
        id = 'offset_y',
        title = 'Offset Y',
        options = TextureCommon.OFFSET_OPTIONS,
        index = 3,
    }
    local rows = {
        { source_selector, region_selector },
        { align_x_selector, align_y_selector },
        { offset_x_selector, offset_y_selector },
    }

    rawset(target, '_demo_label', 'Drawable')
    rawset(target, '_demo_label_align', 'center')
    rawset(target, '_demo_label_valign', 'center')
    set_hint(
        helpers,
        target,
        source_selector,
        region_selector,
        align_x_selector,
        align_y_selector,
        offset_x_selector,
        offset_y_selector
    )

    local function apply_state()
        local source = TextureCommon.resolve_source(
            base_texture,
            source_selector.options[source_selector.index],
            region_selector.options[region_selector.index]
        )

        target.backgroundImage = source
        target.backgroundAlignX = align_x_selector.options[align_x_selector.index].value
        target.backgroundAlignY = align_y_selector.options[align_y_selector.index].value
        target.backgroundOffsetX = offset_x_selector.options[offset_x_selector.index].value
        target.backgroundOffsetY = offset_y_selector.options[offset_y_selector.index].value

        TextureCommon.set_preview_source(
            preview,
            base_texture,
            source_selector.options[source_selector.index],
            region_selector.options[region_selector.index]
        )
    end

    local function sync_layout()
        local screen_width = stage.width
        local screen_height = stage.height
        local target_total_width = preview_frame.width + FRAME_GAP + frame.width
        local base_x = floor((screen_width - target_total_width) * 0.5)
        local center_y = floor((screen_height * 0.5) + 50)
        local preview_y = floor(center_y - (preview_frame.height * 0.5))
        local frame_y = floor(center_y - (frame.height * 0.5))
        local top_y = 110

        preview_frame.x = base_x
        preview_frame.y = preview_y
        frame.x = base_x + preview_frame.width + FRAME_GAP
        frame.y = frame_y
        group.x = FRAME_CONTENT_INSET
        group.y = FRAME_CONTENT_INSET
        target.x = floor((group.width - target.width) * 0.5)
        target.y = floor((group.height - target.height) * 0.5)

        layouts = {}
        local y = top_y

        for index = 1, #rows do
            local row_layouts = build_row_layouts(screen_width, y, font, rows[index])

            for key, layout in pairs(row_layouts) do
                layouts[key] = layout
            end

            y = y + font:getHeight() + LABEL_GAP + font:getHeight() + 12 + ROW_GAP
        end
    end

    local function selector_disabled(selector)
        return selector.id == 'region' and
            source_selector.options[source_selector.index].kind == 'texture'
    end

    local function handle_selector_click(selector, x, y)
        local layout = layouts and layouts[selector.id] or nil

        if layout == nil or selector_disabled(selector) then
            return false
        end

        if NativeControls.point_in_rect(layout.left, x, y) then
            selector.index = TextureCommon.cycle_index(selector.index, -1, #selector.options)
            apply_state()
            return true
        end

        if NativeControls.point_in_rect(layout.right, x, y) then
            selector.index = TextureCommon.cycle_index(selector.index, 1, #selector.options)
            apply_state()
            return true
        end

        return false
    end

    apply_state()

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            sync_layout()
        end,
        mousepressed = function(x, y, button)
            if button ~= 1 or layouts == nil then
                return false
            end

            if handle_selector_click(source_selector, x, y) then
                return true
            end
            if handle_selector_click(region_selector, x, y) then
                return true
            end
            if handle_selector_click(align_x_selector, x, y) then
                return true
            end
            if handle_selector_click(align_y_selector, x, y) then
                return true
            end
            if handle_selector_click(offset_x_selector, x, y) then
                return true
            end
            if handle_selector_click(offset_y_selector, x, y) then
                return true
            end

            return false
        end,
        draw_overlay = function(graphics)
            if layouts == nil then
                return
            end

            local mouse_x, mouse_y = love.mouse.getPosition()

            draw_selector(
                graphics,
                font,
                source_selector,
                layouts.source,
                NativeControls.point_in_rect(layouts.source.left, mouse_x, mouse_y),
                NativeControls.point_in_rect(layouts.source.right, mouse_x, mouse_y),
                false
            )
            draw_selector(
                graphics,
                font,
                region_selector,
                layouts.region,
                NativeControls.point_in_rect(layouts.region.left, mouse_x, mouse_y),
                NativeControls.point_in_rect(layouts.region.right, mouse_x, mouse_y),
                selector_disabled(region_selector)
            )
            draw_selector(
                graphics,
                font,
                align_x_selector,
                layouts.align_x,
                NativeControls.point_in_rect(layouts.align_x.left, mouse_x, mouse_y),
                NativeControls.point_in_rect(layouts.align_x.right, mouse_x, mouse_y),
                false
            )
            draw_selector(
                graphics,
                font,
                align_y_selector,
                layouts.align_y,
                NativeControls.point_in_rect(layouts.align_y.left, mouse_x, mouse_y),
                NativeControls.point_in_rect(layouts.align_y.right, mouse_x, mouse_y),
                false
            )
            draw_selector(
                graphics,
                font,
                offset_x_selector,
                layouts.offset_x,
                NativeControls.point_in_rect(layouts.offset_x.left, mouse_x, mouse_y),
                NativeControls.point_in_rect(layouts.offset_x.right, mouse_x, mouse_y),
                false
            )
            draw_selector(
                graphics,
                font,
                offset_y_selector,
                layouts.offset_y,
                NativeControls.point_in_rect(layouts.offset_y.left, mouse_x, mouse_y),
                NativeControls.point_in_rect(layouts.offset_y.right, mouse_x, mouse_y),
                false
            )
        end,
    })
end

return Setup
