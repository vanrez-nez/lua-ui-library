-- text.lua - Text component extending Drawable
-- Renders text with configurable type, font, color, and optional word wrapping.

local Drawable = require("lib.ui.core.drawable")
local theme    = require("lib.ui.themes")

local Text = setmetatable({}, { __index = Drawable })
Text.__index = Text

-- Static presets for common text types
Text.TYPES = {
    heading = { fontSize = 32, color = theme.text.heading },
    body    = { fontSize = 16, color = theme.text.body },
    caption = { fontSize = 12, color = theme.text.caption },
}

-- Module-level font cache keyed by "fontPath:fontSize"
local fontCache = {}

--- Resolve a font path that may be relative to the project root.
-- LÖVE's filesystem is rooted at the source directory (which may be a subfolder
-- like test/text/), so we resolve against the real OS path instead.
local function resolveFontPath(fontPath)
    -- Absolute OS path — use as-is
    if fontPath:sub(1, 1) == "/" then
        return fontPath
    end
    -- Relative path — resolve from project root via SOURCE_DIR parents
    local sourceDir = love.filesystem.getSource()
    local full = sourceDir .. "/" .. fontPath
    -- If not found, walk up directories (handles test/<name>/ subdirs)
    local f = io.open(full, "r")
    if f then
        f:close()
        return full
    end
    -- Try up to 3 parent levels
    local dir = sourceDir
    for _ = 1, 3 do
        dir = dir:match("^(.+)/[^/]+$")
        if not dir then break end
        full = dir .. "/" .. fontPath
        f = io.open(full, "r")
        if f then
            f:close()
            return full
        end
    end
    -- Fall back to original (will error with a clear message)
    return fontPath
end

local function getOrCreateFont(fontPath, fontSize)
    if fontPath then
        local key = fontPath .. ":" .. fontSize
        if not fontCache[key] then
            local resolved = resolveFontPath(fontPath)
            local handle = io.open(resolved, "rb")
            local bytes = handle:read("*a")
            handle:close()
            local fileData = love.filesystem.newFileData(bytes, fontPath)
            fontCache[key] = love.graphics.newFont(fileData, fontSize)
        end
        return fontCache[key]
    else
        local key = "default:" .. fontSize
        if not fontCache[key] then
            fontCache[key] = love.graphics.newFont(fontSize)
        end
        return fontCache[key]
    end
end

function Text.new(opts)
    opts = opts or {}
    local self = Drawable.new(opts)
    self = setmetatable(self, Text)

    -- Apply type preset defaults
    local preset = opts.textType and Text.TYPES[opts.textType]
    local defaultFontSize = preset and preset.fontSize or 16
    local defaultColor = preset and preset.color or theme.text.default

    self.text     = opts.text or ""
    self.fontSize = opts.fontSize or defaultFontSize
    self.color    = opts.color or { defaultColor[1], defaultColor[2], defaultColor[3], defaultColor[4] }
    self.maxWidth = opts.maxWidth or nil
    self.autoSize = opts.autoSize == nil and true or opts.autoSize

    -- Font resolution: opts.font > newFont(fontPath, fontSize) > newFont(fontSize)
    if opts.font then
        self.font = opts.font
    else
        self.font = getOrCreateFont(opts.fontPath, self.fontSize)
    end

    self:_measureAndResize()

    return self
end

function Text:_measureAndResize()
    if not self.autoSize then return end

    local w, h
    if self.maxWidth then
        local wrappedWidth, lines = self.font:getWrap(self.text, self.maxWidth)
        w = self.maxWidth
        h = #lines * self.font:getHeight()
    else
        w = self.font:getWidth(self.text)
        h = self.font:getHeight()
    end

    self:setSize(w, h)
end

function Text:setText(text)
    self.text = text
    self:_measureAndResize()
end

function Text:setColor(color)
    self.color = color
end

function Text:setFont(font)
    self.font = font
    self:_measureAndResize()
end

function Text:draw()
    love.graphics.setColor(self.color)
    love.graphics.setFont(self.font)

    if self.maxWidth then
        love.graphics.printf(self.text, 0, 0, self.maxWidth, self.alignH)
    else
        love.graphics.print(self.text, 0, 0)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Text
