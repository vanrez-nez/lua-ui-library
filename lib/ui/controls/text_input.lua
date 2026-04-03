local Drawable = require('lib.ui.core.drawable')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local FontCache = require('lib.ui.text.font_cache')
local ControlUtils = require('lib.ui.controls.control_utils')

local TextInput = Drawable:extends('TextInput')

local function clamp(n, lo, hi)
    if n < lo then return lo end
    if n > hi then return hi end
    return n
end

local function strlen(value)
    return #value
end

local function get_effective_value(self)
    if rawget(self, '_value_controlled') then
        return rawget(self, 'value') or ''
    end
    return rawget(self, '_value_uncontrolled') or ''
end

local function set_value_request(self, next_value)
    if rawget(self, '_value_controlled') then
        ControlUtils.call_if_function(rawget(self, 'onValueChange'), next_value)
        return
    end

    rawset(self, '_value_uncontrolled', next_value)
    ControlUtils.call_if_function(rawget(self, 'onValueChange'), next_value)
end

local function get_selection_pair(self)
    if rawget(self, '_selection_controlled') then
        local value = get_effective_value(self)
        local len = strlen(value)
        local s = clamp(rawget(self, 'selectionStart') or len, 0, len)
        local e = clamp(rawget(self, 'selectionEnd') or s, 0, len)
        if e < s then s, e = e, s end
        return s, e
    end

    return rawget(self, '_selection_start') or 0, rawget(self, '_selection_end') or 0
end

local function set_selection_request(self, s, e)
    local value = get_effective_value(self)
    local len = strlen(value)
    s = clamp(s or 0, 0, len)
    e = clamp(e or s, 0, len)
    if e < s then s, e = e, s end

    if rawget(self, '_selection_controlled') then
        ControlUtils.call_if_function(rawget(self, 'onSelectionChange'), s, e)
        return
    end

    rawset(self, '_selection_start', s)
    rawset(self, '_selection_end', e)
    ControlUtils.call_if_function(rawget(self, 'onSelectionChange'), s, e)
end

local function caret_pos(self)
    local _, e = get_selection_pair(self)
    return e
end

local function reset_blink(self)
    rawset(self, '_caret_blink_t', 0)
    rawset(self, '_caret_blink_on', true)
end

local function has_focus(self)
    return ControlUtils.stage_focus_owner(self) == self
end

local function apply_max_length(self, value)
    local max_length = rawget(self, 'maxLength')
    if max_length == nil then
        return value
    end

    if #value <= max_length then
        return value
    end

    return value:sub(1, max_length)
end

local function replace_selection(self, insertion)
    local value = get_effective_value(self)
    local s, e = get_selection_pair(self)
    local next_value = value:sub(1, s) .. insertion .. value:sub(e + 1)
    next_value = apply_max_length(self, next_value)

    local next_caret = s + #insertion
    if next_caret > #next_value then
        next_caret = #next_value
    end

    set_value_request(self, next_value)
    set_selection_request(self, next_caret, next_caret)
    reset_blink(self)
end

local function delete_backward(self)
    local value = get_effective_value(self)
    local s, e = get_selection_pair(self)
    if s ~= e then
        replace_selection(self, '')
        return
    end

    if s <= 0 then
        return
    end

    local next_value = value:sub(1, s - 1) .. value:sub(s + 1)
    set_value_request(self, next_value)
    set_selection_request(self, s - 1, s - 1)
    reset_blink(self)
end

function TextInput:constructor(opts)
    opts = opts or {}

    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = true,
        focusable = true,
    })

    Drawable.constructor(self, drawable_opts)
    rawset(self, 'pointerFocusCoupling', 'before')

    rawset(self, '_ui_text_input_control', true)

    rawset(self, 'value', opts.value)
    rawset(self, 'onValueChange', opts.onValueChange)
    rawset(self, 'selectionStart', opts.selectionStart)
    rawset(self, 'selectionEnd', opts.selectionEnd)
    rawset(self, 'onSelectionChange', opts.onSelectionChange)
    rawset(self, 'placeholder', opts.placeholder)
    rawset(self, 'disabled', opts.disabled == true)
    rawset(self, 'readOnly', opts.readOnly == true)
    rawset(self, 'maxLength', opts.maxLength)
    rawset(self, 'inputMode', opts.inputMode or 'text')
    rawset(self, 'submitBehavior', opts.submitBehavior or 'blur')
    rawset(self, 'onSubmit', opts.onSubmit)
    rawset(self, 'font', opts.font)
    rawset(self, 'fontSize', opts.fontSize or 16)

    if self.maxLength ~= nil then
        Assert.number('TextInput.maxLength', self.maxLength, 2)
        if self.maxLength < 0 then
            Assert.fail('maxLength < 0 is invalid', 2)
        end
    end

    if self.submitBehavior ~= 'blur' and self.submitBehavior ~= 'submit' and self.submitBehavior ~= 'none' then
        Assert.fail('TextInput.submitBehavior must be "blur", "submit", or "none"', 2)
    end

    if self.inputMode ~= 'text' and self.inputMode ~= 'numeric' and self.inputMode ~= 'email' and
        self.inputMode ~= 'url' and self.inputMode ~= 'search' then
        Assert.fail('TextInput.inputMode is invalid', 2)
    end

    ControlUtils.assert_controlled_pair('value', opts.value, 'onValueChange', opts.onValueChange, 2)

    local has_start = opts.selectionStart ~= nil
    local has_end = opts.selectionEnd ~= nil
    if has_start ~= has_end then
        Assert.fail('controlled selection requires both selectionStart and selectionEnd', 2)
    end
    if has_start and not Types.is_function(opts.onSelectionChange) then
        Assert.fail('controlled selection requires onSelectionChange', 2)
    end

    rawset(self, '_value_controlled', opts.value ~= nil)
    rawset(self, '_selection_controlled', has_start and has_end)

    rawset(self, '_value_uncontrolled', opts.value or '')
    rawset(self, '_selection_start', strlen(opts.value or ''))
    rawset(self, '_selection_end', strlen(opts.value or ''))
    rawset(self, '_focused', false)
    rawset(self, '_composing', false)
    rawset(self, '_composition_text', '')
    rawset(self, '_caret_blink_t', 0)
    rawset(self, '_caret_blink_on', true)
    rawset(self, '_styling_context', {
        component = 'textInput',
        part = 'field',
    })

    self:_add_event_listener('ui.activate', function(event)
        if rawget(self, '_destroyed') then return end
        if rawget(self, 'disabled') then return end

        ControlUtils.request_focus(self)

        local value = get_effective_value(self)
        local at_end = strlen(value)
        set_selection_request(self, at_end, at_end)
        reset_blink(self)
    end)

    self:_add_event_listener('ui.text.input', function(event)
        if rawget(self, '_destroyed') then return end
        if rawget(self, 'disabled') or rawget(self, 'readOnly') then return end
        if not has_focus(self) then return end

        local text = event.text or ''
        if text == '' then
            return
        end

        replace_selection(self, text)
        rawset(self, '_composing', false)
        rawset(self, '_composition_text', '')
        event:stopPropagation()
    end)

    self:_add_event_listener('ui.text.compose', function(event)
        if rawget(self, '_destroyed') then return end
        if rawget(self, 'disabled') or rawget(self, 'readOnly') then return end
        if not has_focus(self) then return end

        rawset(self, '_composing', true)
        rawset(self, '_composition_text', event.text or '')
        event:stopPropagation()
    end)

    self:_add_event_listener('ui.navigate', function(event)
        if rawget(self, '_destroyed') then return end
        if rawget(self, 'disabled') then return end
        if not has_focus(self) then return end

        if event.navigationMode ~= 'directional' then
            return
        end

        local s, e = get_selection_pair(self)
        local c = e
        local value_len = strlen(get_effective_value(self))

        if event.direction == 'left' then
            c = clamp(c - 1, 0, value_len)
            set_selection_request(self, c, c)
            reset_blink(self)
            event:preventDefault()
            event:stopPropagation()
            return
        end

        if event.direction == 'right' then
            c = clamp(c + 1, 0, value_len)
            set_selection_request(self, c, c)
            reset_blink(self)
            event:preventDefault()
            event:stopPropagation()
            return
        end
    end)

    self:_add_event_listener('ui.submit', function(event)
        if rawget(self, '_destroyed') then return end
        if rawget(self, 'disabled') then return end
        if not has_focus(self) then return end

        local behavior = rawget(self, 'submitBehavior') or 'blur'
        if behavior == 'none' then
            event:preventDefault()
            return
        end

        if behavior == 'submit' then
            ControlUtils.call_if_function(rawget(self, 'onSubmit'), get_effective_value(self), self, event)
            event:preventDefault()
            return
        end

        if behavior == 'blur' then
            ControlUtils.clear_focus(self)
            event:preventDefault()
            return
        end
    end)
end

function TextInput.new(opts)
    return TextInput(opts)
end

function TextInput:addChild()
    Assert.fail('TextInput may not contain child nodes', 2)
end

function TextInput:removeChild()
    Assert.fail('TextInput may not contain child nodes', 2)
end

function TextInput:_get_value()
    return get_effective_value(self)
end

function TextInput:_get_selection()
    return get_selection_pair(self)
end

function TextInput:_is_focused()
    return rawget(self, '_focused') == true
end

function TextInput:_is_composing()
    return rawget(self, '_composing') == true
end

function TextInput:_composition_text_value()
    return rawget(self, '_composition_text') or ''
end

function TextInput:_resolve_visual_variant()
    if rawget(self, 'disabled') == true then
        return 'disabled'
    end

    if rawget(self, 'readOnly') == true then
        return 'readOnly'
    end

    if rawget(self, '_composing') == true then
        return 'composing'
    end

    if rawget(self, '_focused') == true then
        return 'focused'
    end

    return 'base'
end

function TextInput:_delete_backward()
    if rawget(self, 'disabled') or rawget(self, 'readOnly') then
        return self
    end
    delete_backward(self)
    return self
end

function TextInput:_replace_selection_internal(text)
    text = tostring(text or '')
    if rawget(self, 'disabled') or rawget(self, 'readOnly') then
        return self
    end
    replace_selection(self, text)
    return self
end

function TextInput:update(dt)
    Drawable.update(self, dt)

    local disabled = rawget(self, 'disabled') == true
    local focused = (not disabled) and has_focus(self)
    local was_focused = rawget(self, '_focused') == true

    rawset(self, '_focused', focused)

    local pv = rawget(self, '_public_values')
    local ev = rawget(self, '_effective_values')
    if pv then
        pv.enabled = not disabled
        pv.interactive = not disabled
        pv.focusable = not disabled
    end
    if ev then
        ev.enabled = not disabled
        ev.interactive = not disabled
        ev.focusable = not disabled
    end

    if focused ~= was_focused and love ~= nil and love.keyboard ~= nil and Types.is_function(love.keyboard.setTextInput) then
        love.keyboard.setTextInput(focused)
    end

    if not focused and rawget(self, '_composing') then
        rawset(self, '_composing', false)
        rawset(self, '_composition_text', '')
    end

    if focused then
        local t = (rawget(self, '_caret_blink_t') or 0) + (dt or 0)
        if t >= 0.5 then
            t = t - 0.5
            rawset(self, '_caret_blink_on', not rawget(self, '_caret_blink_on'))
        end
        rawset(self, '_caret_blink_t', t)
    else
        rawset(self, '_caret_blink_on', false)
        rawset(self, '_caret_blink_t', 0)
    end

    return self
end

function TextInput:_measure_text(graphics)
    local font = rawget(self, '_cached_font')
    if font == nil then
        font = FontCache.get(rawget(self, 'font'), rawget(self, 'fontSize') or 16)
        rawset(self, '_cached_font', font)
    end

    local value = get_effective_value(self)
    local width = font:getWidth(value)
    local height = font:getHeight()
    return width, height, font
end

return TextInput
