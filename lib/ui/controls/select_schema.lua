local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')

local function normalize_disabled_values(values)
    local map = {}
    if values == nil then
        return map
    end

    Assert.table('Select.disabledValues', values, 3)
    for index = 1, #values do
        map[tostring(values[index])] = true
    end
    return map
end

return {
    -- Spec: ui-controls 6.10: single value is string | nil; multiple value is table | nil of unique strings.
    value = Rule.any(),
    onValueChange = Rule.func({ optional = true }),
    open = Rule.boolean(),
    onOpenChange = Rule.func({ optional = true }),
    selectionMode = Rule.custom(function(_, value, _, level)
        value = value or 'single'
        if value ~= 'single' and value ~= 'multiple' then
            Assert.fail('Select.selectionMode must be "single" or "multiple"', level or 1)
        end
        return value
    end, { default = 'single' }),
    -- Spec: ui-controls 6.10 props/defaults: placeholder is string | nil, default "None selected".
    placeholder = Rule.any({ default = 'None selected' }),
    modal = Rule.boolean(false),
    disabled = Rule.boolean(false),
    disabledValues = Rule.custom(function(_, value)
        normalize_disabled_values(value)
        return value
    end),
}
