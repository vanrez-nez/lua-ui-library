-- drawable.lua - base drawable class extending Container
-- Provides empty draw/update interface for subclasses (Sprite, Text, Shape, etc.)
-- Also provides layout properties: padding, margin, alignH, alignV.

local Container = require("lib.ui.core.container")

local Drawable = setmetatable({}, { __index = Container })
Drawable.__index = Drawable

--- Normalize a CSS-shorthand-style insets value into {top, right, bottom, left}.
-- Accepts: number, {v,h}, {top,right,bottom,left}, or a table with named keys.
local function normalizeInsets(v)
    if type(v) == "number" then
        return { top = v, right = v, bottom = v, left = v }
    elseif type(v) == "table" then
        if v.top then return v end  -- already named
        if #v == 2 then
            return { top = v[1], right = v[2], bottom = v[1], left = v[2] }
        elseif #v == 4 then
            return { top = v[1], right = v[2], bottom = v[3], left = v[4] }
        end
    end
    return { top = 0, right = 0, bottom = 0, left = 0 }
end

function Drawable.new(opts)
    opts = opts or {}
    local self = Container.new(opts)
    self = setmetatable(self, Drawable)

    self.padding = normalizeInsets(opts.padding or 0)
    self.margin  = normalizeInsets(opts.margin  or 0)

    -- Align shorthand: opts.align sets both H and V
    if opts.align then
        self.alignH = opts.alignH or opts.align
        self.alignV = opts.alignV or opts.align
    else
        self.alignH = opts.alignH or "left"
        self.alignV = opts.alignV or "top"
    end

    return self
end

function Drawable:draw()
    -- override in subclasses
end

function Drawable:update(dt)
    -- override in subclasses
end

--- Returns the inner content rectangle after padding is applied.
-- @return x, y, w, h
function Drawable:getContentRect()
    local p = self.padding
    local x = p.left
    local y = p.top
    local w = math.max(0, self.size.x - p.left - p.right)
    local h = math.max(0, self.size.y - p.top  - p.bottom)
    return x, y, w, h
end

--- Returns the origin position for content of given size, aligned within the content rect.
-- @param contentW number  width of the content to position
-- @param contentH number  height of the content to position
-- @return x, y
function Drawable:getContentOrigin(contentW, contentH)
    local cx, cy, cw, ch = self:getContentRect()
    local x, y = cx, cy

    if self.alignH == "center" then
        x = cx + (cw - contentW) * 0.5
    elseif self.alignH == "right" then
        x = cx + cw - contentW
    end

    if self.alignV == "center" then
        y = cy + (ch - contentH) * 0.5
    elseif self.alignV == "bottom" then
        y = cy + ch - contentH
    end

    return x, y
end

function Drawable:setPadding(v)
    self.padding = normalizeInsets(v)
end

function Drawable:setMargin(v)
    self.margin = normalizeInsets(v)
end

function Drawable:setAlign(h, v)
    self.alignH = h or self.alignH
    self.alignV = v or self.alignV
end

return Drawable
