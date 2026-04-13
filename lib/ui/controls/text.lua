local Drawable = require('lib.ui.core.drawable')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local FontCache = require('lib.ui.text.font_cache')
local ControlUtils = require('lib.ui.controls.control_utils')

local Text = Drawable:extends('Text')

local function count_lines(text)
    if text == nil or text == '' then
        return 1
    end

    local _, count = string.gsub(text, '\n', '\n')
    return count + 1
end

local function resolve_font(self)
    local font = self._font_object
    if font ~= nil then
        return font
    end

    local font_size = self.fontSize or 16
    local font_path = self.font

    if font_path ~= nil and Types.is_table(font_path) then
        return font_path
    end

    if font_path ~= nil and not Types.is_string(font_path) then
        Assert.fail('Text.font must be a font object, string path, or nil', 2)
    end

    font = FontCache.get(font_path, font_size)
    self._font_object = font
    return font
end

local function get_text_metrics(self, width_hint)
    local font = resolve_font(self)
    local text = self.text or ''
    local wrap = self.wrap == true
    local line_height = self.lineHeight or 1

    if not wrap then
        local lines = count_lines(text)
        return font:getWidth(text), font:getHeight() * line_height * lines, lines
    end

    local max_width = self.maxWidth
    local wrap_width = max_width
    if wrap_width == nil then
        wrap_width = width_hint or self._resolved_width or 0
    end
    wrap_width = math.max(0, wrap_width)

    if wrap_width <= 0 then
        return 0, 0, 0
    end

    local _, lines = font:getWrap(text, wrap_width)
    return wrap_width, #lines * font:getHeight() * line_height, #lines
end

function Text:constructor(opts)
    opts = opts or {}

    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = false,
        focusable = false,
    })

    Drawable.constructor(self, drawable_opts)

    self._ui_text_control = true
    self.text = opts.text or ''
    self.font = opts.font
    self.fontSize = opts.fontSize or 16
    self.lineHeight = opts.lineHeight or 1
    self.maxWidth = opts.maxWidth
    self.textAlign = opts.textAlign or 'start'
    self.textVariant = opts.textVariant
    self.color = opts.color or { 1, 1, 1, 1 }
    self.wrap = opts.wrap == true

    if self.textAlign ~= 'start' and self.textAlign ~= 'center' and self.textAlign ~= 'end' then
        Assert.fail('Text.textAlign must be "start", "center", or "end"', 2)
    end

    if not Types.is_string(self.text) then
        Assert.fail('Text.text must be a string', 2)
    end

    if not Types.is_number(self.fontSize) or self.fontSize <= 0 then
        Assert.fail('Text.fontSize must be a number greater than 0', 2)
    end

    if not Types.is_number(self.lineHeight) or self.lineHeight <= 0 then
        Assert.fail('Text.lineHeight must be a number greater than 0', 2)
    end

    if self.maxWidth ~= nil then
        Assert.number('Text.maxWidth', self.maxWidth, 2)
        if self.maxWidth < 0 then
            Assert.fail('Text.maxWidth must be >= 0', 2)
        end
    end

    self._font_object = nil
    self._text_auto_width = opts.width == nil
    self._text_auto_height = opts.height == nil

    -- Intrinsic measurement based on current content.
    local w, h = get_text_metrics(self, self.maxWidth)
    local props = self.props
    if props ~= nil then
        if props:raw_get('width') == 0 then props:raw_set('width', w) end
        if props:raw_get('height') == 0 then props:raw_set('height', h) end
    end
    self:markDirty()
end

function Text.new(opts)
    return Text(opts)
end

function Text:_resolve_visual_variant()
    return self.textVariant or 'base'
end

function Text:addChild()
    Assert.fail('Text may not contain child nodes', 2)
end

function Text:removeChild()
    Assert.fail('Text may not contain child nodes', 2)
end

function Text:setText(value)
    Assert.string('value', value, 2)
    self.text = value
    self:markDirty()
    return self
end

local function refresh_intrinsic_size(self)
    local props = self.props
    local width_hint = nil

    if self.wrap == true then
        width_hint = self._resolved_width or
            (props and props:raw_get('width')) or
            0
        if self._text_auto_width == true and self.maxWidth ~= nil then
            width_hint = self.maxWidth
        end
    end

    local measured_width, measured_height = get_text_metrics(self, width_hint)
    local changed = false

    if self._text_auto_width == true and props ~= nil then
        if props:raw_get('width') ~= measured_width then
            props:raw_set('width', measured_width)
            changed = true
        end
    end

    if self._text_auto_height == true and props ~= nil then
        if props:raw_get('height') ~= measured_height then
            props:raw_set('height', measured_height)
            changed = true
        end
    end

    if changed then
        self:markDirty()
    end
end

function Text:_measure_text_for_draw()
    return get_text_metrics(self)
end

function Text:update(dt)
    Drawable.update(self, dt)
    refresh_intrinsic_size(self)
    return self
end

function Text:_draw_control(graphics)
    if graphics == nil then
        return
    end

    local bounds = self._world_bounds_cache
    if bounds == nil then
        return
    end

    local text = self.text or ''
    if text == '' then
        return
    end

    local font = resolve_font(self)
    local color = self.color or { 1, 1, 1, 1 }

    local old_font = nil
    if Types.is_function(graphics.getFont) then
        old_font = graphics.getFont()
    end

    if Types.is_function(graphics.setFont) then
        graphics.setFont(font)
    end
    if Types.is_function(graphics.setColor) then
        graphics.setColor(color)
    end

    local wrap = self.wrap == true
    local align = self.textAlign or 'start'
    local love_align = align == 'end' and 'right' or (align == 'center' and 'center' or 'left')
    local line_height = self.lineHeight or 1
    local old_line_height = nil

    if Types.is_function(font.getLineHeight) then
        old_line_height = font:getLineHeight()
    end

    if Types.is_function(font.setLineHeight) then
        font:setLineHeight(line_height)
    end

    if wrap then
        local width = self.maxWidth
        if width == nil then
            width = bounds.width
        end
        width = math.max(0, width)

        if width > 0 and Types.is_function(graphics.printf) then
            graphics.printf(text, bounds.x, bounds.y, width, love_align)
        end
    else
        local text_width = font:getWidth(text)
        local x = bounds.x
        if align == 'center' then
            x = x + (bounds.width - text_width) * 0.5
        elseif align == 'end' then
            x = x + (bounds.width - text_width)
        end
        if Types.is_function(graphics.print) then
            graphics.print(text, x, bounds.y)
        end
    end

    if old_line_height ~= nil and Types.is_function(font.setLineHeight) then
        font:setLineHeight(old_line_height)
    end

    if old_font ~= nil and Types.is_function(graphics.setFont) then
        graphics.setFont(old_font)
    end
end

return Text
