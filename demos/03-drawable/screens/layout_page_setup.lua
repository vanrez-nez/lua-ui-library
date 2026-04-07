local DemoColors = require('demos.common.colors')
local NativeControls = require('demos.common.native_controls')

local Setup = {}

local WIDTH_OPTIONS = {
    { label = '50%', value = '50%' },
    { label = '75%', value = '75%' },
    { label = '100%', value = '100%' },
}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('layout_page_setup: missing node "' .. id .. '"', 2)
    end
    return node
end

function Setup.install(args)
    local root = args.root
    local scope = args.scope
    local stage = args.stage
    local page = find_required(root, 'layout-page-root')
    local header = find_required(root, 'layout-page-header')
    local content = find_required(root, 'layout-page-content')
    local sidebar = find_required(root, 'layout-page-sidebar')
    local footer = find_required(root, 'layout-page-footer')
    local title_font = scope:font(12)
    local width_index = 1
    local width_layout = nil
    local guides = {
        { node = page, color = { 184 / 255, 191 / 255, 207 / 255, 0.10 } },
        { node = header, color = { 117 / 255, 184 / 255, 255 / 255, 0.12 } },
        { node = content, color = { 125 / 255, 235 / 255, 168 / 255, 0.12 } },
        { node = sidebar, color = { 255 / 255, 208 / 255, 117 / 255, 0.12 } },
        { node = footer, color = { 210 / 255, 165 / 255, 255 / 255, 0.12 } },
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

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            page.width = WIDTH_OPTIONS[width_index].value
        end,
        after_update = function()
            local viewport = root:getWorldBounds()
            local page_bounds = page:getLocalBounds()
            local next_x = math.floor((viewport.width - page_bounds.width) * 0.5) - page_bounds.x
            local next_y = math.floor((viewport.height - page_bounds.height) * 0.5) - page_bounds.y
            local moved = page.x ~= next_x or page.y ~= next_y

            page.x = next_x
            page.y = next_y
            width_layout = NativeControls.build_centered_navigator_layout(
                viewport.width,
                viewport.y + 150,
                title_font,
                WIDTH_OPTIONS[width_index].label
            )

            return moved
        end,
        mousepressed = function(x, y, button)
            if button ~= 1 or width_layout == nil then
                return false
            end

            if NativeControls.point_in_rect(width_layout.left, x, y) then
                width_index = cycle_index(width_index, -1, #WIDTH_OPTIONS)
                return true
            end

            if NativeControls.point_in_rect(width_layout.right, x, y) then
                width_index = cycle_index(width_index, 1, #WIDTH_OPTIONS)
                return true
            end

            return false
        end,
        draw_under = function(graphics)
            for index = 1, #guides do
                local guide = guides[index]
                local bounds = guide.node:getWorldBounds()

                graphics.setColor(guide.color)
                graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height)
            end
        end,
        draw_overlay = function(graphics)
            local mouse_x, mouse_y

            if width_layout == nil then
                return
            end

            mouse_x, mouse_y = love.mouse.getPosition()
            graphics.setColor(DemoColors.roles.text)
            graphics.setFont(title_font)
            graphics.print(
                'Root Width',
                width_layout.left.x + math.floor((width_layout.right.x + width_layout.right.width - width_layout.left.x - title_font:getWidth('Root Width')) * 0.5),
                width_layout.body.y - title_font:getHeight() - 6
            )
            NativeControls.draw_navigator(
                graphics,
                title_font,
                width_layout,
                WIDTH_OPTIONS[width_index].label,
                NativeControls.point_in_rect(width_layout.left, mouse_x, mouse_y),
                NativeControls.point_in_rect(width_layout.right, mouse_x, mouse_y)
            )
        end,
    })
end

return Setup
