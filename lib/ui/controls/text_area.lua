local TextInput = require('lib.ui.controls.text_input')
local ScrollableContainer = require('lib.ui.scroll.scrollable_container')
local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')
local Rule = require('lib.ui.utils.rule')
local StyleScope = require('lib.ui.render.style_scope')

local TextArea = TextInput:extends('TextArea')
local TEXT_AREA_FIELD_SCOPE = StyleScope.create('textArea', 'field')
local TEXT_AREA_SCROLL_REGION_SCOPE = StyleScope.create('textArea', 'scroll region')

local TextAreaSchema = {
    wrap = Rule.boolean(true),
    rows = Rule.number(),
    scrollXEnabled = Rule.boolean(false),
    scrollYEnabled = Rule.boolean(true),
    momentum = Rule.boolean(false),
}

TextArea._schema = ControlUtils.extend_schema(TextInput._schema, TextAreaSchema)

function TextArea:constructor(opts)
    opts = opts or {}
    TextInput.constructor(self, opts)

    self._ui_text_area_control = true
    self:setStyleScope(TEXT_AREA_FIELD_SCOPE)

    self.wrap = opts.wrap ~= false
    self.rows = opts.rows
    self.scrollXEnabled = opts.scrollXEnabled == true
    self.scrollYEnabled = opts.scrollYEnabled ~= false
    self.momentum = opts.momentum == true

    if self.rows ~= nil then
        Assert.number('TextArea.rows', self.rows, 2)
        if self.rows < 1 then
            Assert.fail('TextArea.rows must be >= 1', 2)
        end
    end

    local region_surface = Drawable.new({
        tag = (self.tag and (self.tag .. '.scroll-region')) or 'textArea.scroll-region',
        internal = true,
        width = 'fill',
        height = 'fill',
        interactive = false,
        focusable = false,
        style_scope = TEXT_AREA_SCROLL_REGION_SCOPE,
    })
    Container._allow_fill_from_parent(region_surface, { width = true, height = true })

    local region = ScrollableContainer._create_scroll_region({
        scroll_x = (self.wrap == false) and self.scrollXEnabled,
        scroll_y = self.scrollYEnabled,
        momentum = self.momentum,
        show_scrollbars = true,
        width = 'fill',
        height = 'fill',
    })
    Container._allow_fill_from_parent(region, { width = true, height = true })
    region_surface:addChild(region)
    Container.addChild(self, region_surface)
    self.scrollRegion = region_surface
    self._scroll_region = region

    ControlUtils.add_control_listener(self, self, 'ui.submit', function(event)
        if self.disabled or self.readOnly then return end
        if not self:_is_focused() then return end

        self:_replace_selection_internal('\n')
        event:preventDefault()
        event:stopImmediatePropagation()
    end, 'capture')

    ControlUtils.add_control_listener(self, self, 'ui.scroll', function(event)
        if not self:_is_focused() then return end
        local region_ref = self._scroll_region
        if region_ref == nil then return end

        local dx = event.deltaX or 0
        local dy = event.deltaY or 0
        if self.wrap == true then
            dx = 0
        end

        region_ref:_scroll_by(dx, dy)
        event:stopPropagation()
    end)
end

function TextArea.new(opts)
    return TextArea(opts)
end

function TextArea:resolveStyleVariant()
    return TextInput.resolveStyleVariant(self)
end

function TextArea:update(dt)
    TextInput.update(self, dt)

    local region = self._scroll_region
    if region ~= nil then
        local rx = (self.wrap == false) and (self.scrollXEnabled == true)
        region.scrollXEnabled = rx
        region.scrollYEnabled = self.scrollYEnabled ~= false
        region.momentum = self.momentum == true
    end

    local region_surface = self.scrollRegion
    if region_surface ~= nil then
        region_surface:setStyleVariant(self:resolveStyleVariant())
    end

    return self
end

return TextArea
