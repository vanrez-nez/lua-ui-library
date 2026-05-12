local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local ControlSchema = require('lib.ui.controls.control_schema')

return {
    -- Spec: ui-controls 6.10: single value is string | nil; multiple value is table | nil of unique strings.
    value = Rule.any_of({
        Rule.string(),
        Rule.table({ items = Rule.string() })
    }, { optional = true }),
    onValueChange = ControlSchema.optional_callback(),
    open = Rule.boolean({ optional = true }),
    onOpenChange = ControlSchema.optional_callback(),
    selectionMode = Rule.custom(function(_, value, _, level)
        value = value or 'single'
        if value ~= 'single' and value ~= 'multiple' then
            Assert.fail('Select.selectionMode must be "single" or "multiple"', level or 1)
        end
        return value
    end, { default = 'single' }),
    -- Spec: ui-controls 6.10 props/defaults: placeholder is string | nil, default "None selected".
    placeholder = Rule.string({ default = 'None selected' }),
    modal = Rule.boolean(false),
    disabled = Rule.boolean(false),
    disabledValues = Rule.table({ optional = true, items = Rule.string() }),
}
