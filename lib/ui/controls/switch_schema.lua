local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')

return {
    checked = Rule.boolean(),
    onCheckedChange = Rule.func({ optional = true }),
    disabled = Rule.boolean(false),
    dragThreshold = Rule.custom(function(_, value, _, level)
        if value == nil then return 10 end
        Assert.number('Switch.dragThreshold', value, level or 1)
        if value < 0 then
            Assert.fail('negative dragThreshold is invalid', level or 1)
        end
        return value
    end, { default = 10 }),
    snapBehavior = Rule.custom(function(_, value, _, level)
        value = value or 'nearest'
        if value ~= 'nearest' and value ~= 'directional' then
            Assert.fail('Switch.snapBehavior must be "nearest" or "directional"', level or 1)
        end
        return value
    end, { default = 'nearest' }),
    label = Rule.any(),
    description = Rule.any(),
}
