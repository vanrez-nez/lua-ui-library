local DemoColors = require('demos.common.colors')

local MemoryMonitor = {}
MemoryMonitor.__index = MemoryMonitor
local LINE_HEIGHT = 1.3

local function to_mb(bytes)
    return bytes / (1024 * 1024)
end

local function format_duration(seconds)
    local total = math.floor(seconds or 0)
    local hours = math.floor(total / 3600)
    local minutes = math.floor((total % 3600) / 60)
    local secs = total % 60
    return string.format('%02d:%02d:%02d', hours, minutes, secs)
end

function MemoryMonitor.new()
    return setmetatable({
        visible = false,
        title_font = love.graphics.newFont(16),
        body_font = love.graphics.newFont(13),
    }, MemoryMonitor)
end

function MemoryMonitor:toggle()
    self.visible = not self.visible
end

function MemoryMonitor:hide()
    self.visible = false
end

function MemoryMonitor:draw(stats_context)
    if not self.visible then
        return
    end

    local g = love.graphics
    local stats = g.getStats()
    local width, height = g.getDimensions()
    local box_width = 420
    local box_height = 230
    local x = math.floor((width - box_width) * 0.5 + 0.5)
    local y = math.floor((height - box_height) * 0.5 + 0.5)
    local gc_kb = collectgarbage('count')

    local lines = {
        string.format('Running time: %s', format_duration(love.timer.getTime())),
        string.format('Lua GC memory: %.2f MB', gc_kb / 1024),
        string.format('Texture memory: %.2f MB', to_mb(stats.texturememory or 0)),
        string.format('Draw calls: %d', stats.drawcalls or 0),
        string.format('Canvas switches: %d', stats.canvasswitches or 0),
        string.format('Images: %d', stats.images or 0),
        string.format('Fonts: %d', stats.fonts or 0),
        string.format('Canvases: %d', stats.canvases or 0),
        string.format('Shaders: %d', stats.shaders or 0),
    }

    g.setColor(DemoColors.roles.background_alt)
    g.rectangle('fill', x, y, box_width, box_height, 0, 0)

    g.setFont(self.title_font)
    g.setColor(DemoColors.roles.text)
    g.printf('Memory Monitor', x + 20, y + 18, box_width - 40, 'center')

    g.setFont(self.body_font)
    g.setColor(DemoColors.roles.text_subtle)
    if self.body_font.setLineHeight ~= nil then
        self.body_font:setLineHeight(LINE_HEIGHT)
    end
    g.printf(table.concat(lines, '\n'), x + 24, y + 58, box_width - 48, 'left')
end

return MemoryMonitor
