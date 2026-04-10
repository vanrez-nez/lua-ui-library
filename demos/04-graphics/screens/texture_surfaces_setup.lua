local DemoColors = require('demos.common.colors')
local NativeControls = require('demos.common.native_controls')
local TextureCommon = require('demos.04-graphics.screens.texture_common')

local Setup = {}

local FRAME_CONTENT_INSET = 1
local FRAME_GAP_X = 36
local FRAME_GAP_Y = 28
local CONTROL_COLUMN_GAP = 36
local LABEL_GAP = 10
local CONTROL_ROW_GAP = 20
local GRID_BOTTOM_GAP = 24

local function floor(value)
    return math.floor(value + 0.5)
end

local function build_navigator_layout(x, y, font, body_width)
    local arrow_width = 42
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

local function resolve_selectors_body_width(font, selectors)
    local width = 0

    for index = 1, #selectors do
        width = math.max(width, resolve_body_width(font, selectors[index].options))
    end

    return width
end

local function selector_step_height(font)
    local nav_height = font:getHeight() + 12
    return font:getHeight() + LABEL_GAP + nav_height
end

local function build_column_layouts(x, y, font, selectors)
    local layouts = {}
    local body_width = resolve_selectors_body_width(font, selectors)
    local current_y = y
    local step_height = selector_step_height(font)

    for index = 1, #selectors do
        local selector = selectors[index]

        layouts[selector.id] = build_navigator_layout(x, current_y, font, body_width)
        current_y = current_y + step_height

        if index < #selectors then
            current_y = current_y + CONTROL_ROW_GAP
        end
    end

    return layouts, layout_width(build_navigator_layout(x, y, font, body_width)), current_y - y
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

local function set_center_label(node, label)
    rawset(node, '_demo_label', label)
    rawset(node, '_demo_label_align', 'center')
    rawset(node, '_demo_label_valign', 'center')
end

local function set_preview_hint(helpers, node, source_selector, region_selector)
    helpers.set_hint_name(node, 'Source Preview')
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
        }
    end)
end

local function set_surface_hint(helpers, node, name, source_selector, region_selector, repeat_selector, align_x_selector, align_y_selector, offset_x_selector, offset_y_selector)
    helpers.set_hint_name(node, name)
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
                label = 'repeat',
                badges = {
                    helpers.badge(nil, repeat_selector.options[repeat_selector.index].label),
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
    local stage = args.stage
    local font = love.graphics.newFont(12)
    local drawable_frame = TextureCommon.find_required(root, 'texture-surfaces-drawable-frame', 'texture_surfaces_setup')
    local drawable_group = TextureCommon.find_required(root, 'texture-surfaces-drawable-group', 'texture_surfaces_setup')
    local drawable_target = TextureCommon.find_required(root, 'texture-surfaces-drawable-target', 'texture_surfaces_setup')
    local rect_frame = TextureCommon.find_required(root, 'texture-surfaces-rect-frame', 'texture_surfaces_setup')
    local rect_group = TextureCommon.find_required(root, 'texture-surfaces-rect-group', 'texture_surfaces_setup')
    local rect_target = TextureCommon.find_required(root, 'texture-surfaces-rect-target', 'texture_surfaces_setup')
    local circle_frame = TextureCommon.find_required(root, 'texture-surfaces-circle-frame', 'texture_surfaces_setup')
    local circle_group = TextureCommon.find_required(root, 'texture-surfaces-circle-group', 'texture_surfaces_setup')
    local circle_target = TextureCommon.find_required(root, 'texture-surfaces-circle-target', 'texture_surfaces_setup')
    local base_texture = drawable_target.backgroundImage
    local preview_frame, preview = TextureCommon.add_source_preview(
        root,
        'texture-surfaces-preview',
        drawable_frame.width,
        drawable_frame.height
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
    local repeat_selector = {
        id = 'repeat',
        title = 'Repeat',
        options = TextureCommon.REPEAT_OPTIONS,
        index = 4,
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
    local selectors = {
        source_selector,
        region_selector,
        repeat_selector,
        align_x_selector,
        align_y_selector,
        offset_x_selector,
        offset_y_selector,
    }

    set_center_label(preview, 'Source')
    set_preview_hint(helpers, preview, source_selector, region_selector)
    set_center_label(drawable_target, 'Drawable')
    set_center_label(rect_target, 'Rect')
    set_center_label(circle_target, 'Circle')

    set_surface_hint(
        helpers,
        drawable_target,
        'Drawable Background',
        source_selector,
        region_selector,
        repeat_selector,
        align_x_selector,
        align_y_selector,
        offset_x_selector,
        offset_y_selector
    )
    set_surface_hint(
        helpers,
        rect_target,
        'RectShape Fill',
        source_selector,
        region_selector,
        repeat_selector,
        align_x_selector,
        align_y_selector,
        offset_x_selector,
        offset_y_selector
    )
    set_surface_hint(
        helpers,
        circle_target,
        'CircleShape Fill',
        source_selector,
        region_selector,
        repeat_selector,
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
        local repeat_mode = repeat_selector.options[repeat_selector.index]
        local align_x = align_x_selector.options[align_x_selector.index].value
        local align_y = align_y_selector.options[align_y_selector.index].value
        local offset_x = offset_x_selector.options[offset_x_selector.index].value
        local offset_y = offset_y_selector.options[offset_y_selector.index].value

        drawable_target.backgroundImage = source
        drawable_target.backgroundRepeatX = repeat_mode.repeatX
        drawable_target.backgroundRepeatY = repeat_mode.repeatY
        drawable_target.backgroundAlignX = align_x
        drawable_target.backgroundAlignY = align_y
        drawable_target.backgroundOffsetX = offset_x
        drawable_target.backgroundOffsetY = offset_y

        rect_target.fillTexture = source
        rect_target.fillRepeatX = repeat_mode.repeatX
        rect_target.fillRepeatY = repeat_mode.repeatY
        rect_target.fillAlignX = align_x
        rect_target.fillAlignY = align_y
        rect_target.fillOffsetX = offset_x
        rect_target.fillOffsetY = offset_y

        circle_target.fillTexture = source
        circle_target.fillRepeatX = repeat_mode.repeatX
        circle_target.fillRepeatY = repeat_mode.repeatY
        circle_target.fillAlignX = align_x
        circle_target.fillAlignY = align_y
        circle_target.fillOffsetX = offset_x
        circle_target.fillOffsetY = offset_y

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
        local grid_width = preview_frame.width + FRAME_GAP_X + drawable_frame.width
        local grid_height = preview_frame.height + FRAME_GAP_Y + rect_frame.height
        local selector_probe_width = layout_width(build_navigator_layout(0, 0, font, resolve_selectors_body_width(font, selectors)))
        local selector_probe_height = (#selectors * selector_step_height(font)) + ((#selectors - 1) * CONTROL_ROW_GAP)
        local total_width = grid_width + CONTROL_COLUMN_GAP + selector_probe_width
        local total_height = math.max(grid_height, selector_probe_height)
        local base_x = floor((screen_width - total_width) * 0.5)
        local base_y = floor((screen_height - total_height - GRID_BOTTOM_GAP) * 0.5)
        local grid_y = base_y + floor((total_height - grid_height) * 0.5)
        local selector_x = base_x + grid_width + CONTROL_COLUMN_GAP
        local selector_y = base_y + floor((total_height - selector_probe_height) * 0.5)

        layouts = build_column_layouts(selector_x, selector_y, font, selectors)

        preview_frame.x = base_x
        preview_frame.y = grid_y

        drawable_frame.x = base_x + preview_frame.width + FRAME_GAP_X
        drawable_frame.y = grid_y
        drawable_group.x = FRAME_CONTENT_INSET
        drawable_group.y = FRAME_CONTENT_INSET
        drawable_target.x = floor((drawable_group.width - drawable_target.width) * 0.5)
        drawable_target.y = floor((drawable_group.height - drawable_target.height) * 0.5)

        rect_frame.x = base_x
        rect_frame.y = grid_y + preview_frame.height + FRAME_GAP_Y
        rect_group.x = FRAME_CONTENT_INSET
        rect_group.y = FRAME_CONTENT_INSET
        rect_target.x = floor((rect_group.width - rect_target.width) * 0.5)
        rect_target.y = floor((rect_group.height - rect_target.height) * 0.5)

        circle_frame.x = drawable_frame.x
        circle_frame.y = rect_frame.y
        circle_group.x = FRAME_CONTENT_INSET
        circle_group.y = FRAME_CONTENT_INSET
        circle_target.x = floor((circle_group.width - circle_target.width) * 0.5)
        circle_target.y = floor((circle_group.height - circle_target.height) * 0.5)
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
            if handle_selector_click(repeat_selector, x, y) then
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
                repeat_selector,
                layouts['repeat'],
                NativeControls.point_in_rect(layouts['repeat'].left, mouse_x, mouse_y),
                NativeControls.point_in_rect(layouts['repeat'].right, mouse_x, mouse_y),
                false
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
