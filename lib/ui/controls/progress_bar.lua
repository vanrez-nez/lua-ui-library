local Drawable = require('lib.ui.core.drawable')
local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local ControlUtils = require('lib.ui.controls.control_utils')
local MathUtils = require('lib.ui.utils.math')
local Rule = require('lib.ui.utils.rule')

local ProgressBar = Drawable:extends('ProgressBar')

local ProgressBarSchema = {
    value = Rule.number(),
    min = Rule.number({ default = 0 }),
    max = Rule.number({ default = 1 }),
    indeterminate = Rule.boolean(false),
    orientation = Rule.any({ default = 'horizontal' }),
}

ProgressBar._schema = ControlUtils.extend_schema(Drawable._schema, ProgressBarSchema)

local function effective_value(self)
    local value = self.value
    if value == nil then
        value = self.min or 0
    end
    return MathUtils.clamp(value, self.min or 0, self.max or 1)
end

local function ratio(self)
    local min_value = self.min or 0
    local max_value = self.max or 1
    if max_value <= min_value then
        return 0
    end
    return (effective_value(self) - min_value) / (max_value - min_value)
end

local function sync_parts(self)
    local track = rawget(self, 'track')
    local indicator = rawget(self, 'indicator')
    local bounds = {
        width = rawget(self, '_resolved_width') or 0,
        height = rawget(self, '_resolved_height') or 0,
    }
    local current_ratio = ratio(self)

    track.x = 0
    track.y = 0
    track.width = bounds.width
    track.height = bounds.height

    if self.orientation == 'vertical' then
        indicator.x = 0
        indicator.width = bounds.width
        if self.indeterminate then
            indicator.height = math.max(12, bounds.height * 0.35)
            indicator.y = (bounds.height - indicator.height) * 0.5
        else
            indicator.height = bounds.height * current_ratio
            indicator.y = bounds.height - indicator.height
        end
    else
        indicator.y = 0
        indicator.height = bounds.height
        if self.indeterminate then
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
    self.schema:define(ProgressBarSchema)
    self.value = opts.value
    self.min = opts.min or 0
    self.max = opts.max or 1
    self.indeterminate = opts.indeterminate == true
    self.orientation = opts.orientation or 'horizontal'

    rawset(self, '_ui_progress_bar_control', true)

    if self.max <= self.min then
        Assert.fail('ProgressBar.max must be greater than ProgressBar.min', 2)
    end

    if self.orientation ~= 'horizontal' and self.orientation ~= 'vertical' then
        Assert.fail('ProgressBar.orientation must be "horizontal" or "vertical"', 2)
    end

    local track = Drawable.new({
        tag = (self.tag and (self.tag .. '.track')) or 'progress.track',
        internal = true,
        interactive = false,
        focusable = false,
    })
    local indicator = Drawable.new({
        tag = (self.tag and (self.tag .. '.indicator')) or 'progress.indicator',
        internal = true,
        interactive = false,
        focusable = false,
    })
    rawset(track, '_styling_context', {
        component = 'progressBar',
        part = 'track',
    })
    rawset(indicator, '_styling_context', {
        component = 'progressBar',
        part = 'indicator',
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

    local variant = self.indeterminate and 'indeterminate' or 'determinate'
    rawset(rawget(self, 'track'), '_styling_variant', variant)
    rawset(rawget(self, 'indicator'), '_styling_variant', variant)

    rawset(self, '_last_motion_ratio', current_ratio)
    sync_parts(self)
    return self
end

function ProgressBar:destroy()
    if rawget(self, '_destroyed') then
        return
    end
    rawset(self, '_destroyed', true)
    ControlUtils.remove_control_listeners(self)
    rawset(self, '_destroyed', false)
    Container.destroy(self)
end

return ProgressBar
