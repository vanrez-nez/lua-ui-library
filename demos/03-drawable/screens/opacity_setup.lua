local DemoColors = require('demos.common.colors')
local NativeControls = require('demos.common.native_controls')

local Setup = {}

local CASES = {
    {
        label = 'Opacity 0.5',
        opacity = 0.5,
        visible = true,
        description = 'The circles overlap first, then the whole subtree fades as one composited unit.',
    },
    {
        label = 'Opacity 1.0',
        opacity = 1,
        visible = true,
        description = 'Baseline case. The subtree renders at full strength with normal overlap.',
    },
    {
        label = 'Opacity 0.0',
        opacity = 0,
        visible = true,
        description = 'Fully transparent is still not invisibility. The subtree remains retained, hit-testable, and inspectable.',
    },
    {
        label = 'Visible false',
        opacity = 1,
        visible = false,
        description = 'visible = false suppresses rendering entirely. The outline is demo annotation only, not node rendering.',
    },
}

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
        error('opacity_setup: missing node "' .. id .. '"', 2)
    end
    return node
end

local function apply_case(node, case)
    node.opacity = case.opacity
    node.visible = case.visible
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local scope = args.scope
    local stage = args.stage
    local title_font = scope:font(12)
    local body_font = scope:font(13)
    local frame = find_required(root, 'opacity-frame')
    local opacity_subtree = find_required(root, 'opacity-subtree')
    local active_case_index = 1
    local selector_layout = nil
    local selector_description_rect = nil

    local function active_case()
        return CASES[active_case_index]
    end

    local function sync_layout()
        local case = active_case()
        local screen_width = stage.width
        local screen_height = stage.height
        local frame_x = math.floor((screen_width - frame.width) * 0.5)
        local frame_y = math.floor((screen_height - frame.height) * 0.5) + 25
        local description_width = 540
        local _, wrapped_description = body_font:getWrap(case.description, description_width)

        selector_layout = NativeControls.build_centered_navigator_layout(
            screen_width,
            125,
            title_font,
            case.label
        )
        selector_description_rect = {
            x = math.floor((screen_width - description_width) * 0.5),
            y = selector_layout.body.y + selector_layout.body.height + 15,
            width = description_width,
            height = #wrapped_description * body_font:getHeight(),
        }

        frame.x = frame_x
        frame.y = frame_y
        opacity_subtree.x = frame_x + math.floor((frame.width - opacity_subtree.width) * 0.5)
        opacity_subtree.y = frame_y + math.floor((frame.height - opacity_subtree.height) * 0.5)
    end

    local function set_active_case(index)
        active_case_index = index
        apply_case(opacity_subtree, active_case())
        sync_layout()
    end

    helpers.set_hint_name(opacity_subtree, 'opacity subtree')
    helpers.set_hint(opacity_subtree, function(current)
        local case = active_case()

        return {
            {
                label = 'case',
                badges = {
                    helpers.badge('label', case.label),
                },
            },
            {
                label = 'root',
                badges = {
                    helpers.badge('opacity', helpers.format_scalar(current.opacity)),
                    helpers.badge('visible', tostring(current.visible)),
                },
            },
            {
                label = 'contract',
                badges = {
                    helpers.badge('meaning', case.description),
                },
            },
        }
    end)

    set_active_case(active_case_index)

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            sync_layout()
        end,
        mousepressed = function(x, y, button)
            if button ~= 1 or selector_layout == nil then
                return false
            end

            if NativeControls.point_in_rect(selector_layout.left, x, y) then
                set_active_case(cycle_index(active_case_index, -1, #CASES))
                return true
            end

            if NativeControls.point_in_rect(selector_layout.right, x, y) then
                set_active_case(cycle_index(active_case_index, 1, #CASES))
                return true
            end

            return false
        end,
        draw_overlay = function(graphics)
            local mouse_x, mouse_y = love.mouse.getPosition()
            local case = active_case()
            local hovered_left = selector_layout ~= nil and
                NativeControls.point_in_rect(selector_layout.left, mouse_x, mouse_y)
            local hovered_right = selector_layout ~= nil and
                NativeControls.point_in_rect(selector_layout.right, mouse_x, mouse_y)
            local draw_context = helpers._draw_context
            local bounds = {
                x = opacity_subtree.x,
                y = opacity_subtree.y,
                width = opacity_subtree.width,
                height = opacity_subtree.height,
            }
            local is_inside = mouse_x >= bounds.x and
                mouse_y >= bounds.y and
                mouse_x <= bounds.x + bounds.width and
                mouse_y <= bounds.y + bounds.height

            NativeControls.draw_navigator(
                graphics,
                title_font,
                selector_layout,
                case.label,
                hovered_left,
                hovered_right,
                DemoColors.roles.border_light
            )

            graphics.setColor(DemoColors.roles.body_muted)
            graphics.setFont(body_font)
            graphics.printf(
                case.description,
                selector_description_rect.x,
                selector_description_rect.y,
                selector_description_rect.width,
                'center'
            )

            if draw_context ~= nil and is_inside then
                draw_context.hovered_node = opacity_subtree
                draw_context.hovered_area = bounds.width * bounds.height
            end

            if not case.visible then
                graphics.setColor(DemoColors.rgba(DemoColors.roles.accent_highlight, 0.18))
                graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 20, 20)
                graphics.setColor(DemoColors.roles.accent_highlight)
                graphics.setLineWidth(is_inside and 3 or 2)
                graphics.rectangle('line', bounds.x, bounds.y, bounds.width, bounds.height, 20, 20)
                graphics.setLineWidth(1)
            end
        end,
    })
end

return Setup
