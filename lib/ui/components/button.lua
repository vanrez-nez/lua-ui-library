-- button.lua - Button component extending Drawable
-- Provides a clickable button with label, hover/press states, and configurable colors.

local Drawable = require("lib.ui.core.drawable")
local Text     = require("lib.ui.components.text")
local theme    = require("lib.ui.themes")

local Button = setmetatable({}, { __index = Drawable })
Button.__index = Button

function Button.new(opts)
    opts = opts or {}

    -- Default padding and alignment for buttons
    opts.padding = opts.padding or { 8, 16, 8, 16 }
    if not opts.align and not opts.alignH and not opts.alignV then
        opts.align = "center"
    end

    local self = Drawable.new(opts)
    self = setmetatable(self, Button)

    self.label        = opts.label        or "Button"
    self.font         = opts.font         or nil
    self.onClick      = opts.onClick      or nil

    self.color        = opts.color        or theme.button.color
    self.hoverColor   = opts.hoverColor   or theme.button.hoverColor
    self.pressColor   = opts.pressColor   or theme.button.pressColor
    self.textColor    = opts.textColor    or theme.button.textColor
    self.borderColor  = opts.borderColor  or theme.button.borderColor
    self.cornerRadius = opts.cornerRadius or 8

    self.enabled  = opts.enabled == nil and true or opts.enabled
    self._hovered = false
    self._pressed = false

    self._textChild = Text.new({
        text  = self.label,
        font  = self.font,
        color = self.textColor,
    })

    return self
end

function Button:draw()
    local w, h = self.size.x, self.size.y

    -- Pick background color based on state
    local bg
    if not self.enabled then
        local s = theme.button.disabledBgScale
        bg = { self.color[1] * s, self.color[2] * s, self.color[3] * s }
    elseif self._pressed then
        bg = self.pressColor
    elseif self._hovered then
        bg = self.hoverColor
    else
        bg = self.color
    end

    -- Fill
    love.graphics.setColor(bg)
    love.graphics.rectangle("fill", 0, 0, w, h, self.cornerRadius, self.cornerRadius)

    -- Border
    love.graphics.setColor(self.borderColor)
    love.graphics.rectangle("line", 0, 0, w, h, self.cornerRadius, self.cornerRadius)

    -- Label (sync if changed directly)
    if self._textChild.text ~= self.label then
        self._textChild:setText(self.label)
    end

    local textW = self._textChild.size.x
    local textH = self._textChild.size.y
    local tx, ty = self:getContentOrigin(textW, textH)

    self._textChild.color = not self.enabled
        and { self.textColor[1], self.textColor[2], self.textColor[3], theme.button.disabledTextAlpha }
        or self.textColor

    love.graphics.push()
    love.graphics.translate(tx, ty)
    self._textChild:draw()
    love.graphics.pop()

    love.graphics.setColor(1, 1, 1, 1)
end

function Button:update(dt)
    if not self.enabled then
        self._hovered = false
        return
    end
    local mx, my = love.mouse.getPosition()
    self._hovered = self:containsPoint(mx, my)
end

function Button:setLabel(newLabel)
    self.label = newLabel
    self._textChild:setText(newLabel)
end

function Button:mousepressed(mx, my, btn)
    if btn ~= 1 or not self.enabled then return false end
    if self:containsPoint(mx, my) then
        self._pressed = true
        return true
    end
    return false
end

function Button:mousereleased(mx, my, btn)
    if btn ~= 1 or not self._pressed then return false end
    self._pressed = false
    if self:containsPoint(mx, my) and self.onClick then
        self.onClick(self)
    end
    return true
end

return Button
