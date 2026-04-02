local DemoColors = require('demos.common.colors')

local InfoSidebar = {}
InfoSidebar.__index = InfoSidebar

-- Draws the directional triangle used by the whole-sidebar toggle buttons.
local function draw_triangle(x, y, size, direction)
    local half = size * 0.5
    local inset = math.floor(size * 0.28)
    local min_x = x + inset
    local max_x = x + size - inset
    local min_y = y + inset
    local max_y = y + size - inset
    local center_y = y + half

    if direction == 'right' then
        love.graphics.polygon('fill',
            min_x, min_y,
            min_x, max_y,
            max_x, center_y
        )
        return
    end

    love.graphics.polygon('fill',
        max_x, min_y,
        max_x, max_y,
        min_x, center_y
    )
end

-- Draws the shared whole-sidebar toggle button. The only state change is the
-- triangle direction.
local function draw_sidebar_toggle_button(rect, direction)
    local triangle_size = 12
    local triangle_x = rect.x + math.floor((rect.width - triangle_size) * 0.5)
    local triangle_y = rect.y + math.floor((rect.height - triangle_size) * 0.5)

    love.graphics.setColor(DemoColors.roles.surface_interactive)
    love.graphics.rectangle('fill', rect.x, rect.y, rect.width, rect.height)
    love.graphics.setColor(DemoColors.roles.text)
    draw_triangle(triangle_x, triangle_y, triangle_size, direction)
end

-- The collapsed-edge toggle and the expanded-header toggle intentionally share
-- the same size.
local function make_sidebar_toggle_rect(x, y)
    return {
        x = x,
        y = y,
        width = 20,
        height = 28,
    }
end

function InfoSidebar.new(opts)
    opts = opts or {}

    local self = setmetatable({}, InfoSidebar)
    self.header_height = opts.header_height or 104
    self.title_font = opts.title_font or love.graphics.newFont(12)
    self.body_font = opts.body_font or love.graphics.newFont(12)
    self.items = {}
    self.layout = {}
    self.collapsed = false
    self.tab_rect = nil
    self.header_rect = nil
    self.header_button_rect = nil
    return self
end

function InfoSidebar:clear_items()
    self.items = {}
    self.layout = {}
end

function InfoSidebar:add_item(title, lines)
    assert(#self.items < 10, 'DemoBase supports at most 10 info items')

    self.items[#self.items + 1] = {
        title = title or 'Info',
        lines = lines or {},
        collapsed = false,
    }

    return #self.items
end

function InfoSidebar:set_item_title(index, title)
    local item = self.items[index]
    if item ~= nil then
        item.title = title or item.title
    end
end

function InfoSidebar:set_item_lines(index, lines)
    local item = self.items[index]
    if item ~= nil then
        item.lines = lines or {}
    end
end

function InfoSidebar:set_item_collapsed(index, collapsed)
    local item = self.items[index]
    if item ~= nil then
        item.collapsed = collapsed == true
    end
end

function InfoSidebar:toggle_item(index)
    local item = self.items[index]
    if item ~= nil then
        item.collapsed = not item.collapsed
    end
end

function InfoSidebar:toggle()
    self.collapsed = not self.collapsed
end

function InfoSidebar:handle_mousepressed(x, y, button)
    if button ~= 1 then
        return false
    end

    local tab = self.tab_rect
    if tab ~= nil and
        x >= tab.x and x <= (tab.x + tab.width) and
        y >= tab.y and y <= (tab.y + tab.height) then
        self:toggle()
        return true
    end

    local header = self.header_rect
    if header ~= nil and
        x >= header.x and x <= (header.x + header.width) and
        y >= header.y and y <= (header.y + header.height) then
        self:toggle()
        return true
    end

    local header_button = self.header_button_rect
    if header_button ~= nil and
        x >= header_button.x and x <= (header_button.x + header_button.width) and
        y >= header_button.y and y <= (header_button.y + header_button.height) then
        self:toggle()
        return true
    end

    for index = 1, #self.layout do
        local rect = self.layout[index]
        if rect ~= nil and rect.button ~= nil and
            x >= rect.button.x and x <= (rect.button.x + rect.button.width) and
            y >= rect.button.y and y <= (rect.button.y + rect.button.height) then
            self:toggle_item(index)
            return true
        end
    end

    return false
end

function InfoSidebar:draw_shell(x, y, width, header_height, toggle_width, toggle_height)
    local g = love.graphics

    -- Left edge toggle that remains visible even when the full sidebar is collapsed.
    self.tab_rect = make_sidebar_toggle_rect(0, self.header_height)
    self.header_rect = nil
    self.header_button_rect = nil

    if self.collapsed then
        draw_sidebar_toggle_button(self.tab_rect, 'right')
        return nil
    end

    draw_sidebar_toggle_button(self.tab_rect, 'left')

    -- Main "Info" header bar for the expanded sidebar.
    g.setColor(DemoColors.roles.surface_emphasis)
    g.rectangle('fill', x, y, width, header_height)
    g.setColor(DemoColors.roles.text)
    g.setFont(self.title_font)
    g.print('Info', x + 8, y + 8)

    self.header_rect = {
        x = x,
        y = y,
        width = width,
        height = header_height,
    }

    -- Right-side header toggle button. This is the same object as the left edge
    -- toggle, just rendered inside the expanded header.
    self.header_button_rect = {
        x = x + width - toggle_width,
        y = y,
        width = toggle_width,
        height = toggle_height,
    }

    draw_sidebar_toggle_button(self.header_button_rect, 'left')

    return y + header_height
end

function InfoSidebar:draw_panels(x, y, width, bar_height, line_height)
    local g = love.graphics

    self.layout = {}

    for index = 1, #self.items do
        local item = self.items[index]
        local body_lines = item.lines or {}
        local body_height = item.collapsed and 0 or ((#body_lines * line_height) + 12)
        local total_height = bar_height + body_height
        local button_size = 18
        local button_x = x + 6
        local button_y = y + 3

        -- Full panel body that contains the handle and the optional text lines.
        g.setColor(DemoColors.roles.surface_alt_soft)
        g.rectangle('fill', x, y, width, total_height)

        -- Panel handle bar. Clicking its +/- control collapses or expands only
        -- this panel's body.
        g.setColor(DemoColors.roles.surface_alt)
        g.rectangle('fill', x, y, width, bar_height)
        g.setColor(DemoColors.roles.body_muted)
        g.setFont(self.title_font)
        g.print(item.title, x + 30, y + 6)

        -- Panel-local +/- collapse control.
        g.setColor(DemoColors.roles.surface)
        g.rectangle('fill', button_x, button_y, button_size, button_size)
        g.setColor(DemoColors.roles.text)
        local button_label = item.collapsed and '+' or '-'
        local label_width = self.title_font:getWidth(button_label)
        local label_height = self.title_font:getHeight()
        g.print(
            button_label,
            button_x + math.floor((button_size - label_width) * 0.5),
            button_y + math.floor((button_size - label_height) * 0.5) - 1
        )

        self.layout[index] = {
            x = x,
            y = y,
            width = width,
            height = total_height,
            button = {
                x = button_x,
                y = button_y,
                width = button_size,
                height = button_size,
            },
        }

        if not item.collapsed then
            -- Expanded panel body text lines.
            g.setColor(DemoColors.roles.text_muted)
            g.setFont(self.body_font)
            for line_index = 1, #body_lines do
                g.print(body_lines[line_index], x + 10, y + bar_height + 8 + ((line_index - 1) * line_height))
            end
        end

        y = y + total_height
    end
end

function InfoSidebar:draw()
    local x = 0
    local y = self.header_height
    local width = 360
    local toggle_width = 20
    local toggle_height = 28
    local header_height = toggle_height
    local bar_height = 24
    local line_height = 16

    -- Step 1: draw the sidebar shell. This may stop early if the whole sidebar
    -- is collapsed.
    local panels_y = self:draw_shell(x, y, width, header_height, toggle_width, toggle_height)
    if panels_y == nil then
        self.layout = {}
        return
    end

    -- Step 2: draw the stacked inspection panels below the header.
    self:draw_panels(x, panels_y, width, bar_height, line_height)
end

return InfoSidebar
