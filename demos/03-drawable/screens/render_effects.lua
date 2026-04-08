local DemoColors = require('demos.common.colors')
local UI = require('lib.ui')

local Drawable = UI.Drawable

local CASES = {
    {
        label = 'Alpha',
        x = 120,
        opacity = 1,
        blendMode = 'alpha',
        line = DemoColors.roles.accent_blue_line,
    },
    {
        label = 'Soft',
        x = 430,
        opacity = 0.45,
        blendMode = 'alpha',
        line = DemoColors.roles.accent_cyan_line,
    },
    {
        label = 'Add',
        x = 740,
        opacity = 1,
        blendMode = 'add',
        line = DemoColors.roles.accent_amber_line,
    },
    {
        label = 'Multiply',
        x = 1050,
        opacity = 1,
        blendMode = 'multiply',
        line = DemoColors.roles.accent_red_line,
    },
}

local function set_fill(graphics, color)
    graphics.setColor(color[1], color[2], color[3], color[4] or 1)
end

local function world_rect(node, x, y, width, height)
    local x1, y1 = node:localToWorld(x, y)
    local x2, y2 = node:localToWorld(x + width, y)
    local x3, y3 = node:localToWorld(x + width, y + height)
    local x4, y4 = node:localToWorld(x, y + height)

    return {
        x1, y1,
        x2, y2,
        x3, y3,
        x4, y4,
    }
end

local function draw_world_rect(node, graphics, x, y, width, height, color)
    set_fill(graphics, color)
    graphics.polygon('fill', world_rect(node, x, y, width, height))
end

local function make_effect_panel(scope, root, helpers, case)
    local panel = helpers.make_node(scope, root, {
        x = case.x,
        y = 170,
        width = 220,
        height = 200,
        padding = 10,
        opacity = case.opacity,
        blendMode = case.blendMode,
    }, case.label, DemoColors.rgba(DemoColors.roles.surface_emphasis, 0.18), case.line)
    helpers.show_bounds(panel)

    function panel:draw(graphics)
        local bounds = self:getWorldBounds()
        set_fill(graphics, DemoColors.rgba(DemoColors.roles.surface_interactive, 0.92))
        graphics.rectangle('fill', bounds.x, bounds.y, bounds.width, bounds.height, 12, 12)

        set_fill(graphics, DemoColors.rgba(DemoColors.roles.surface_alt, 0.85))
        graphics.rectangle('fill', bounds.x + 14, bounds.y + 18, bounds.width - 28, bounds.height - 36, 10, 10)

        set_fill(graphics, DemoColors.rgba(DemoColors.roles.border_light, 0.35))
        graphics.rectangle('fill', bounds.x + 24, bounds.y + 30, bounds.width - 48, 12, 6, 6)
    end

    local red = Drawable.new({
        tag = case.label .. '.red',
        x = 30,
        y = 60,
        width = 90,
        height = 90,
    })
    function red:draw(graphics)
        draw_world_rect(self, graphics, 0, 0, 88, 88, DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.72))
        draw_world_rect(self, graphics, 44, 18, 48, 48, DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.44))
    end

    local green = Drawable.new({
        tag = case.label .. '.green',
        x = 80,
        y = 90,
        width = 100,
        height = 70,
    })
    function green:draw(graphics)
        draw_world_rect(self, graphics, 0, 0, 96, 72, DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.72))
        draw_world_rect(self, graphics, 20, -22, 56, 44, DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.5))
    end

    panel:addChild(red)
    panel:addChild(green)

    helpers.set_hint(panel, function(current)
        return {
            {
                label = 'render',
                badges = {
                    helpers.badge('opacity', helpers.format_scalar(current.opacity)),
                    helpers.badge('blendMode', tostring(current.blendMode or 'nil')),
                },
            },
            {
                label = 'rect.content',
                badges = {
                    helpers.badge('content', helpers.format_rect(current:getContentRect())),
                },
            },
        }
    end)

    return panel
end

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(scope, stage)
            local root = stage.baseSceneLayer

            for index = 1, #CASES do
                make_effect_panel(scope, root, helpers, CASES[index])
            end

            return {
                title = 'Render Effects',
                description = 'Each panel draws the same overlapping child content. Compare alpha, subtree opacity, add, and multiply through the shared retained compositing path.',
            }
        end
    )
end
