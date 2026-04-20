local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local Enums = require('lib.ui.core.enums')
local Enum = require('lib.ui.utils.enum')

local enum_has = Enum.enum_has

return {
    -- Spec: ui-controls 6.7 props: number | nil; effective value clamps to [min, max] and quantizes by step.
    value = Rule.number({ optional = true }),
    onValueChange = Rule.func({ optional = true }),
    min = Rule.number({ default = 0 }),
    max = Rule.custom(function(_, value, _, level, full_opts)
        value = (value == nil) and 1 or value
        Assert.number('Slider.max', value, level or 1)
        local min_value = (full_opts and full_opts.min) or 0
        if value <= min_value then
            Assert.fail('Slider.max must be greater than Slider.min', level or 1)
        end
        return value
    end, { default = 1 }),
    step = Rule.custom(function(_, value, _, level)
        if value == nil then return nil end
        Assert.number('Slider.step', value, level or 1)
        if value <= 0 then
            Assert.fail('Slider.step must be > 0 when provided', level or 1)
        end
        return value
    end),
    orientation = Rule.custom(function(_, value, _, level)
        value = value or Enums.Orientation.HORIZONTAL
        if not enum_has(Enums.Orientation, value) then
            Assert.fail('Slider.orientation must be "horizontal" or "vertical"', level or 1)
        end
        return value
    end, { default = Enums.Orientation.HORIZONTAL }),
    disabled = Rule.boolean(false),
}
