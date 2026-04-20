local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local Container = require('lib.ui.core.container')

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
    -- Spec: ui-controls 6.6 anatomy/composition: optional associated content, non-interactive.
    label = Rule.any_of({
        Rule.string(),
        Rule.instance(Container, 'Container')
    }, { optional = true }),
    -- Spec: ui-controls 6.6 anatomy/composition: optional associated content, non-interactive.
    description = Rule.any_of({
        Rule.string(),
        Rule.instance(Container, 'Container')
    }, { optional = true }),
}
