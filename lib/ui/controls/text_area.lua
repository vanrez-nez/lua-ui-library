local TextInput = require('lib.ui.controls.text_input')
local ScrollableContainer = require('lib.ui.scroll.scrollable_container')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')

local TextArea = TextInput:extends('TextArea')

function TextArea:constructor(opts)
    opts = opts or {}
    TextInput.constructor(self, opts)

    rawset(self, '_ui_text_area_control', true)

    rawset(self, 'wrap', opts.wrap ~= false)
    rawset(self, 'rows', opts.rows)
    rawset(self, 'scrollXEnabled', opts.scrollXEnabled == true)
    rawset(self, 'scrollYEnabled', opts.scrollYEnabled ~= false)
    rawset(self, 'momentum', opts.momentum == true)

    if self.rows ~= nil then
        Assert.number('TextArea.rows', self.rows, 2)
        if self.rows < 1 then
            Assert.fail('TextArea.rows must be >= 1', 2)
        end
    end

    local region = ScrollableContainer._create_scroll_region({
        scroll_x = (self.wrap == false) and self.scrollXEnabled,
        scroll_y = self.scrollYEnabled,
        momentum = self.momentum,
        show_scrollbars = true,
        width = 'fill',
        height = 'fill',
    })
    Container.addChild(self, region)
    rawset(self, '_scroll_region', region)

    self:_add_event_listener('ui.submit', function(event)
        if rawget(self, '_destroyed') then return end
        if rawget(self, 'disabled') or rawget(self, 'readOnly') then return end
        if not self:_is_focused() then return end

        self:_replace_selection_internal('\n')
        event:preventDefault()
        event:stopImmediatePropagation()
    end, 'capture')

    self:_add_event_listener('ui.scroll', function(event)
        if rawget(self, '_destroyed') then return end
        if not self:_is_focused() then return end
        local region_ref = rawget(self, '_scroll_region')
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

function TextArea:update(dt)
    TextInput.update(self, dt)

    local region = rawget(self, '_scroll_region')
    if region ~= nil then
        local rx = (rawget(self, 'wrap') == false) and (rawget(self, 'scrollXEnabled') == true)
        region.scrollXEnabled = rx
        region.scrollYEnabled = rawget(self, 'scrollYEnabled') ~= false
        region.momentum = rawget(self, 'momentum') == true
    end

    return self
end

return TextArea
