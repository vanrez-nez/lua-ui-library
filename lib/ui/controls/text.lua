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
    local font = rawget(self, '_font_object')
    if font ~= nil then
        return font
    end

    local font_size = rawget(self, 'fontSize') or 16
    local font_path = rawget(self, 'font')

    if font_path ~= nil and Types.is_table(font_path) then
        return font_path
    end

    if font_path ~= nil and not Types.is_string(font_path) then
        Assert.fail('Text.font must be a font object, string path, or nil', 2)
    end

    font = FontCache.get(font_path, font_size)
    rawset(self, '_font_object', font)
    return font
end

local function get_text_metrics(self, width_hint)
    local font = resolve_font(self)
    local text = rawget(self, 'text') or ''
    local wrap = rawget(self, 'wrap') == true
    local line_height = rawget(self, 'lineHeight') or 1

    if not wrap then
        local lines = count_lines(text)
        return font:getWidth(text), font:getHeight() * line_height * lines, lines
    end

    local max_width = rawget(self, 'maxWidth')
    local wrap_width = max_width
    if wrap_width == nil then
        wrap_width = width_hint or rawget(self, '_resolved_width') or 0
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

    rawset(self, '_ui_text_control', true)
    rawset(self, 'text', opts.text or '')
    rawset(self, 'font', opts.font)
    rawset(self, 'fontSize', opts.fontSize or 16)
    rawset(self, 'lineHeight', opts.lineHeight or 1)
    rawset(self, 'maxWidth', opts.maxWidth)
    rawset(self, 'textAlign', opts.textAlign or 'start')
    rawset(self, 'textVariant', opts.textVariant)
    rawset(self, 'color', opts.color or { 1, 1, 1, 1 })
    rawset(self, 'wrap', opts.wrap == true)

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

    rawset(self, '_font_object', nil)
    rawset(self, '_text_auto_width', opts.width == nil)
    rawset(self, '_text_auto_height', opts.height == nil)

    -- Intrinsic measurement based on current content.
    local w, h = get_text_metrics(self, self.maxWidth)
    local pv = rawget(self, '_public_values')
    local ev = rawget(self, '_effective_values')
    if pv and pv.width == 0 then pv.width = w end
    if ev and ev.width == 0 then ev.width = w end
    if pv and pv.height == 0 then pv.height = h end
    if ev and ev.height == 0 then ev.height = h end
    self:markDirty()
end

function Text.new(opts)
    return Text(opts)
end

function Text:_resolve_visual_variant()
    return rawget(self, 'textVariant') or 'base'
end

function Text:addChild()
    Assert.fail('Text may not contain child nodes', 2)
end

function Text:removeChild()
    Assert.fail('Text may not contain child nodes', 2)
end

function Text:setText(value)
    Assert.string('value', value, 2)
    rawset(self, 'text', value)
    self:markDirty()
    return self
end

local function refresh_intrinsic_size(self)
    local pv = rawget(self, '_public_values')
    local ev = rawget(self, '_effective_values')
    local width_hint = nil

    if rawget(self, 'wrap') == true then
        width_hint = rawget(self, '_resolved_width') or (ev and ev.width) or (pv and pv.width) or 0
        if rawget(self, '_text_auto_width') == true and rawget(self, 'maxWidth') ~= nil then
            width_hint = rawget(self, 'maxWidth')
        end
    end

    local measured_width, measured_height = get_text_metrics(self, width_hint)
    local changed = false

    if rawget(self, '_text_auto_width') == true and pv and ev then
        if pv.width ~= measured_width then pv.width = measured_width; changed = true end
        if ev.width ~= measured_width then ev.width = measured_width; changed = true end
    end

    if rawget(self, '_text_auto_height') == true and pv and ev then
        if pv.height ~= measured_height then pv.height = measured_height; changed = true end
        if ev.height ~= measured_height then ev.height = measured_height; changed = true end
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

    local bounds = rawget(self, '_world_bounds_cache')
    if bounds == nil then
        return
    end

    local text = rawget(self, 'text') or ''
    if text == '' then
        return
    end

    local font = resolve_font(self)
    local color = rawget(self, 'color') or { 1, 1, 1, 1 }

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

    local wrap = rawget(self, 'wrap') == true
    local align = rawget(self, 'textAlign') or 'start'
    local love_align = align == 'end' and 'right' or (align == 'center' and 'center' or 'left')
    local line_height = rawget(self, 'lineHeight') or 1
    local old_line_height = nil

    if Types.is_function(font.getLineHeight) then
        old_line_height = font:getLineHeight()
    end

    if Types.is_function(font.setLineHeight) then
        font:setLineHeight(line_height)
    end

    if wrap then
        local width = rawget(self, 'maxWidth')
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
