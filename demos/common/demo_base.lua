local MemoryMonitor = require('demos.common.memory_monitor')
local InfoSidebar = require('demos.common.info_sidebar')
local DemoColors = require('demos.common.colors')
local DemoProfiling = require('demos.common.demo_profiling')

local DemoBase = {}
DemoBase.__index = DemoBase

function DemoBase.new(opts)
    opts = opts or {}

    local self = setmetatable({}, DemoBase)
    self.title = opts.title or 'Untitled Demo'
    self.description = opts.description or ''
    self.padding = opts.padding or 24
    self.header_height = opts.header_height or 104
    self.footer_height = opts.footer_height or 44
    self.visible = opts.visible ~= false
    self.screens = {}
    self.active_index = 0
    self.active_screen = nil
    self.memory_monitor = MemoryMonitor.new()
    self.profiling = nil
    self._profiling_auto_initialized = false

    self.title_font = love.graphics.newFont(15)
    self.description_font = love.graphics.newFont(13)
    self.footer_font = love.graphics.newFont(12)
    self.sidebar_title_font = love.graphics.newFont(12)
    self.sidebar_body_font = love.graphics.newFont(12)
    self.info_sidebar = InfoSidebar.new({
        header_height = self.header_height,
        title_font = self.sidebar_title_font,
        body_font = self.sidebar_body_font,
    })

    if opts.profiling ~= nil then
        self.profiling = DemoProfiling.new(opts.profiling)
    end

    return self
end

function DemoBase:show()
    self.visible = true
end

function DemoBase:hide()
    self.visible = false
end

function DemoBase:toggle()
    self.visible = not self.visible
end

function DemoBase:set_title(value)
    self.title = value or 'No Title'
end

function DemoBase:set_description(value)
    self.description = value or ''
end

function DemoBase:get_screen_count()
    return #self.screens
end

function DemoBase:clear_info_items()
    self.info_sidebar:clear_items()
end

function DemoBase:add_info_item(title, lines)
    return self.info_sidebar:add_item(title, lines)
end

function DemoBase:set_info_title(index, title)
    self.info_sidebar:set_item_title(index, title)
end

function DemoBase:set_info_lines(index, lines)
    self.info_sidebar:set_item_lines(index, lines)
end

function DemoBase:set_info_collapsed(index, collapsed)
    self.info_sidebar:set_item_collapsed(index, collapsed)
end

function DemoBase:toggle_info_item(index)
    self.info_sidebar:toggle_item(index)
end

function DemoBase:toggle_info_sidebar()
    self.info_sidebar:toggle()
end

function DemoBase:_reset_global_state()
    if love.audio ~= nil and love.audio.stop ~= nil then
        love.audio.stop()
    end

    if love.keyboard ~= nil and love.keyboard.setTextInput ~= nil then
        love.keyboard.setTextInput(false)
    end

    local g = love.graphics
    if g ~= nil then
        g.origin()
        g.setColor(1, 1, 1, 1)
        g.setCanvas()
        g.setShader()
        g.setScissor()
    end
end

function DemoBase:_cleanup_active_screen()
    if self.active_screen ~= nil and type(self.active_screen.release) == 'function' then
        pcall(self.active_screen.release, self.active_screen)
    end

    self.active_screen = nil
    self:clear_info_items()
    self:_reset_global_state()
end

function DemoBase:_activate_screen(index)
    local total = #self.screens

    if total == 0 then
        self:_cleanup_active_screen()
        self.active_index = 0
        return
    end

    if index < 1 then
        index = total
    elseif index > total then
        index = 1
    end

    self:_cleanup_active_screen()

    local screen = self.screens[index](index) or {}

    self.active_index = index
    self.active_screen = screen
end

function DemoBase:reset_screen()
    if #self.screens == 0 or self.active_index == 0 then
        return
    end

    self:_activate_screen(self.active_index)
end

function DemoBase:push_screen(factory)
    assert(type(factory) == 'function', 'screen factory must be a function')
    self.screens[#self.screens + 1] = factory

    if self.active_index == 0 then
        self:_activate_screen(1)
    end

    if self.profiling ~= nil and not self._profiling_auto_initialized then
        self._profiling_auto_initialized = self.profiling:maybe_start_auto(self)
    end
end

function DemoBase:handle_keypressed(key)
    if key == 'escape' then
        love.event.quit()
        return true
    end

    if self.profiling ~= nil and self.profiling:handle_keypressed(key) then
        return true
    end

    if key == 'h' then
        self:toggle()
        return true
    end

    if key == 'r' then
        self:reset_screen()
        return true
    end

    if key == 'm' then
        self.memory_monitor:toggle()
        return true
    end

    if key == 'right' and #self.screens > 0 then
        self:_activate_screen(self.active_index + 1)
        return true
    end

    if key == 'left' and #self.screens > 0 then
        self:_activate_screen(self.active_index - 1)
        return true
    end

    local screen = self.active_screen
    if screen ~= nil and type(screen.keypressed) == 'function' then
        return screen:keypressed(key) == true
    end

    return false
end

function DemoBase:handle_mousepressed(x, y, button)
    if button ~= 1 or not self.visible then
        return false
    end

    if self.info_sidebar:handle_mousepressed(x, y, button) then
        return true
    end

    local screen = self.active_screen
    if screen ~= nil and type(screen.mousepressed) == 'function' then
        return screen:mousepressed(x, y, button) == true
    end

    return false
end

function DemoBase:get_content_rect()
    local width, height = love.graphics.getDimensions()

    return {
        x = 0,
        y = 0,
        width = width,
        height = height,
    }
end

function DemoBase:begin_frame()
    love.graphics.clear(DemoColors.roles.background)
end

function DemoBase:update(dt)
    local screen = self.active_screen
    if screen ~= nil and type(screen.update) == 'function' then
        screen:update(dt)
    end

    if self.profiling ~= nil and self.profiling:update() then
        return
    end
end

function DemoBase:draw()
    local screen = self.active_screen
    if screen ~= nil and type(screen.draw) == 'function' then
        screen:draw(self:get_content_rect())
    end

    if not self.visible then
        return
    end

    local g = love.graphics
    local width, height = g.getDimensions()
    local footer_y = height - self.footer_height
    local total = #self.screens
    local active = self.active_index > 0 and self.active_index or 1

    g.setColor(DemoColors.roles.surface)
    g.rectangle('fill', 0, 0, width, self.header_height)
    g.rectangle('fill', 0, footer_y, width, self.footer_height)

    g.setColor(DemoColors.roles.text)
    g.setFont(self.title_font)
    g.printf(self.title, self.padding, 18, width - (self.padding * 2), 'center')

    g.setColor(DemoColors.roles.text_muted)
    g.setFont(self.description_font)
    g.printf(self.description, self.padding, 42, width - (self.padding * 2), 'center')

    g.setFont(self.footer_font)
    g.setColor(DemoColors.roles.text)
    g.print('[Left/Right] switch screen  [R] reset screen  [H] toggle navigation  [M] memory  [Esc] quit', self.padding, footer_y + 15)

    local metrics = string.format(
        'Screen %d/%d   %dx%d   %d fps',
        active,
        total,
        width,
        height,
        love.timer.getFPS()
    )

    local metrics_width = self.footer_font:getWidth(metrics)
    g.print(metrics, width - self.padding - metrics_width, footer_y + 15)

    if self.info_sidebar:has_items() then
        self.info_sidebar:draw()
    end

    self.memory_monitor:draw()

    if self.profiling ~= nil then
        self.profiling:draw_status(g, DemoColors)
    end
end

function DemoBase:shutdown()
    if self.profiling ~= nil then
        self.profiling:shutdown()
    end
end

return DemoBase
