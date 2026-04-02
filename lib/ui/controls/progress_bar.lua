local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')

local ProgressBar = Drawable:extends('ProgressBar')

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function effective_value(self)
    local value = rawget(self, 'value')
    if value == nil then
        value = rawget(self, 'min') or 0
    end
    return clamp(value, rawget(self, 'min') or 0, rawget(self, 'max') or 1)
end

local function ratio(self)
    local min_value = rawget(self, 'min') or 0
    local max_value = rawget(self, 'max') or 1
    if max_value <= min_value then
        return 0
    end
    return (effective_value(self) - min_value) / (max_value - min_value)
end

local function sync_parts(self)
    local track = rawget(self, 'track')
    local indicator = rawget(self, 'indicator')
    local bounds = self:getLocalBounds()
    local current_ratio = ratio(self)

    track.x = 0
    track.y = 0
    track.width = bounds.width
    track.height = bounds.height

    if rawget(self, 'orientation') == 'vertical' then
        indicator.x = 0
        indicator.width = bounds.width
        if rawget(self, 'indeterminate') then
            indicator.height = math.max(12, bounds.height * 0.35)
            indicator.y = (bounds.height - indicator.height) * 0.5
        else
            indicator.height = bounds.height * current_ratio
            indicator.y = bounds.height - indicator.height
        end
    else
        indicator.y = 0
        indicator.height = bounds.height
        if rawget(self, 'indeterminate') then
            indicator.width = math.max(12, bounds.width * 0.35)
            indicator.x = (bounds.width - indicator.width) * 0.5
        else
            indicator.width = bounds.width * current_ratio
            indicator.x = 0
        end
    end

    track:markDirty()
    indicator:markDirty()
end

function ProgressBar:constructor(opts)
    opts = opts or {}
    local drawable_opts = ControlUtils.base_opts(opts, {
        interactive = false,
        focusable = false,
    })
    Drawable.constructor(self, drawable_opts)

    rawset(self, '_ui_progress_bar_control', true)
    rawset(self, 'value', opts.value)
    rawset(self, 'min', opts.min or 0)
    rawset(self, 'max', opts.max or 1)
    rawset(self, 'indeterminate', opts.indeterminate == true)
    rawset(self, 'orientation', opts.orientation or 'horizontal')

    if self.max <= self.min then
        Assert.fail('ProgressBar.max must be greater than ProgressBar.min', 2)
    end

    if self.orientation ~= 'horizontal' and self.orientation ~= 'vertical' then
        Assert.fail('ProgressBar.orientation must be "horizontal" or "vertical"', 2)
    end

    local track = Container.new({
        tag = (self.tag and (self.tag .. '.track')) or 'progress.track',
        interactive = false,
        focusable = false,
    })
    local indicator = Container.new({
        tag = (self.tag and (self.tag .. '.indicator')) or 'progress.indicator',
        interactive = false,
        focusable = false,
    })

    Container.addChild(self, track)
    Container.addChild(self, indicator)
    rawset(self, 'track', track)
    rawset(self, 'indicator', indicator)
    rawset(self, '_last_motion_ratio', nil)
    rawset(self, '_last_indeterminate', self.indeterminate)
end

function ProgressBar.new(opts)
    return ProgressBar(opts)
end

function ProgressBar:_get_value_ratio()
    return ratio(self)
end

function ProgressBar:update(dt)
    Drawable.update(self, dt)

    local current_ratio = ratio(self)
    local previous_ratio = rawget(self, '_last_motion_ratio')
    local previous_indeterminate = rawget(self, '_last_indeterminate')

    if self.indeterminate ~= previous_indeterminate then
        self:_raise_motion('indeterminate', {
            defaultTarget = 'indicator',
            previousValue = previous_indeterminate,
            nextValue = self.indeterminate,
        })
        rawset(self, '_last_indeterminate', self.indeterminate)
    elseif previous_ratio ~= nil and math.abs(current_ratio - previous_ratio) > 1e-9 then
        self:_raise_motion('value', {
            defaultTarget = 'indicator',
            previousValue = previous_ratio,
            nextValue = current_ratio,
        })
    end

    rawset(self, '_last_motion_ratio', current_ratio)
    sync_parts(self)
    return self
end

return ProgressBar
