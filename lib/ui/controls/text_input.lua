local Drawable = require('lib.ui.core.drawable')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local FontCache = require('lib.ui.text.font_cache')
local Control = require('lib.ui.controls.control')
local MathUtils = require('lib.ui.utils.math')
local Schema = require('lib.ui.utils.schema')
local Constants = require('lib.ui.core.constants')
local StyleScope = require('lib.ui.render.style_scope')
local TextInputSchema = require('lib.ui.controls.text_input_schema')

local TextInput = Control:extends('TextInput')
local TEXT_INPUT_FIELD_SCOPE = StyleScope.create('textInput', 'field')

TextInput.InputMode = { text = 'text', numeric = 'numeric', email = 'email', url = 'url', search = 'search' }
TextInput.SubmitBehavior = { blur = 'blur', submit = 'submit', none = 'none' }

local function strlen(value)
    return #value
end

local get_effective_value, set_value_request =
    Control.controlled_value('value', '', {
        normalize = function(_, value)
            return tostring(value or '')
        end,
    })

TextInput.schema = Schema.extend(Control.schema, TextInputSchema)

local function get_selection_pair(self)
    if self._selection_controlled then
        local value = get_effective_value(self)
        local len = strlen(value)
        local s = MathUtils.clamp(self.selectionStart or len, 0, len)
        local e = MathUtils.clamp(self.selectionEnd or s, 0, len)
        if e < s then s, e = e, s end
        return s, e
    end

    return self._selection_start or 0, self._selection_end or 0
end

local function set_selection_request(self, s, e)
    local value = get_effective_value(self)
    local len = strlen(value)
    s = MathUtils.clamp(s or 0, 0, len)
    e = MathUtils.clamp(e or s, 0, len)
    if e < s then s, e = e, s end

    if self._selection_controlled then
        Control.call_if_function(self.onSelectionChange, s, e)
        return
    end

    self._selection_start = s
    self._selection_end = e
    Control.call_if_function(self.onSelectionChange, s, e)
end

local function reset_blink(self)
    self._caret_blink_t = 0
    self._caret_blink_on = true
end

local function has_focus(self)
    return self:stageFocusOwner() == self
end

local function apply_max_length(self, value)
    local max_length = self.maxLength
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

    Control.constructor(self, opts, {
        interactive = true,
        focusable = true,
        style_scope = TEXT_INPUT_FIELD_SCOPE,
    })
    self.value = opts.value
    self.onValueChange = opts.onValueChange
    self.selectionStart = opts.selectionStart
    self.selectionEnd = opts.selectionEnd
    self.onSelectionChange = opts.onSelectionChange
    self.placeholder = opts.placeholder
    self.disabled = opts.disabled == true
    self.readOnly = opts.readOnly == true
    self.maxLength = opts.maxLength
    self.inputMode = opts.inputMode or 'text'
    self.submitBehavior = opts.submitBehavior or 'blur'
    self.onSubmit = opts.onSubmit
    self.font = opts.font
    self.fontSize = opts.fontSize or 16
    self.pointerFocusCoupling = 'before'

    self._ui_text_input_control = true

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

    Control.assert_controlled_pair('value', opts.value, 'onValueChange', opts.onValueChange, 2)

    local has_start = opts.selectionStart ~= nil
    local has_end = opts.selectionEnd ~= nil
    if has_start ~= has_end then
        Assert.fail('controlled selection requires both selectionStart and selectionEnd', 2)
    end
    if has_start and not Types.is_function(opts.onSelectionChange) then
        Assert.fail('controlled selection requires onSelectionChange', 2)
    end

    self._value_controlled = opts.value ~= nil
    self._selection_controlled = has_start and has_end

    self._value_uncontrolled = opts.value or ''
    self._selection_start = strlen(opts.value or '')
    self._selection_end = strlen(opts.value or '')
    self._focused = false
    self._composing = false
    self._composition_text = ''
    self._caret_blink_t = 0
    self._caret_blink_on = true

    self:addControlListener(self, 'ui.activate', function()
        if self.disabled then return end

        self:requestFocus()

        local value = get_effective_value(self)
        local at_end = strlen(value)
        set_selection_request(self, at_end, at_end)
        reset_blink(self)
    end)

    self:addControlListener(self, 'ui.text.input', function(event)
        if self.disabled or self.readOnly then return end
        if not has_focus(self) then return end

        local text = event.text or ''
        if text == '' then
            return
        end

        replace_selection(self, text)
        self._composing = false
        self._composition_text = ''
        event:stopPropagation()
    end)

    self:addControlListener(self, 'ui.text.compose', function(event)
        if self.disabled or self.readOnly then return end
        if not has_focus(self) then return end

        self._composing = true
        self._composition_text = event.text or ''
        event:stopPropagation()
    end)

    self:addControlListener(self, 'ui.navigate', function(event)
        if self.disabled then return end
        if not has_focus(self) then return end

        if event.navigationMode ~= Constants.NAVIGATION_MODE_DIRECTIONAL then
            return
        end

        local _, e = get_selection_pair(self)
        local c = e
        local value_len = strlen(get_effective_value(self))

        if event.direction == Constants.NAVIGATION_DIRECTION_LEFT then
            c = MathUtils.clamp(c - 1, 0, value_len)
            set_selection_request(self, c, c)
            reset_blink(self)
            event:preventDefault()
            event:stopPropagation()
            return
        end

        if event.direction == Constants.NAVIGATION_DIRECTION_RIGHT then
            c = MathUtils.clamp(c + 1, 0, value_len)
            set_selection_request(self, c, c)
            reset_blink(self)
            event:preventDefault()
            event:stopPropagation()
            return
        end
    end)

    self:addControlListener(self, 'ui.submit', function(event)
        if self.disabled then return end
        if not has_focus(self) then return end

        local behavior = self.submitBehavior or 'blur'
        if behavior == 'none' then
            event:preventDefault()
            return
        end

        if behavior == 'submit' then
            Control.call_if_function(self.onSubmit, get_effective_value(self), self, event)
            event:preventDefault()
            return
        end

        if behavior == 'blur' then
            self:clearFocus()
            event:preventDefault()
            return
        end
    end)
end

function TextInput.new(opts)
    return TextInput(opts)
end

function TextInput.addChild()
    Assert.fail('TextInput may not contain child nodes', 2)
end

function TextInput.removeChild()
    Assert.fail('TextInput may not contain child nodes', 2)
end

function TextInput:_get_value()
    return get_effective_value(self)
end

function TextInput:_get_selection()
    return get_selection_pair(self)
end

function TextInput:_is_focused()
    return self._focused == true
end

function TextInput:_is_composing()
    return self._composing == true
end

function TextInput:_composition_text_value()
    return self._composition_text or ''
end

function TextInput:resolveStyleVariant()
    if self.disabled == true then
        return 'disabled'
    end

    if self.readOnly == true then
        return 'readOnly'
    end

    if self._composing == true then
        return 'composing'
    end

    if self._focused == true then
        return 'focused'
    end

    return self.style_variant
end

function TextInput:_delete_backward()
    if self.disabled or self.readOnly then
        return self
    end
    delete_backward(self)
    return self
end

function TextInput:_replace_selection_internal(text)
    text = tostring(text or '')
    if self.disabled or self.readOnly then
        return self
    end
    replace_selection(self, text)
    return self
end

function TextInput:update(dt)
    Drawable.update(self, dt)

    local disabled = self.disabled == true
    local focused = (not disabled) and has_focus(self)
    local was_focused = self._focused == true

    self._focused = focused

    self:setInteractionState(not disabled)

    if focused ~= was_focused and
        love ~= nil and
        love.keyboard ~= nil and
        Types.is_function(love.keyboard.setTextInput) then
        love.keyboard.setTextInput(focused)
    end

    if not focused and self._composing then
        self._composing = false
        self._composition_text = ''
    end

    if focused then
        local t = (self._caret_blink_t or 0) + (dt or 0)
        if t >= 0.5 then
            t = t - 0.5
            self._caret_blink_on = not self._caret_blink_on
        end
        self._caret_blink_t = t
    else
        self._caret_blink_on = false
        self._caret_blink_t = 0
    end

    return self
end

function TextInput:on_destroy()
    self:removeControlListeners()
    Drawable.on_destroy(self)
end

function TextInput._measure_text(self)
    local font = self._cached_font
    if font == nil then
        font = FontCache.get(self.font, self.fontSize or 16)
        self._cached_font = font
    end

    local value = get_effective_value(self)
    local width = font:getWidth(value)
    local height = font:getHeight()
    return width, height, font
end

return TextInput
