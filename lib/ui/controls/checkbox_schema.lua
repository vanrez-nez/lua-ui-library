local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local ControlSchema = require('lib.ui.controls.control_schema')

local VALID_STATES = {
    checked = true,
    unchecked = true,
    indeterminate = true,
}

local function validate_toggle_order(toggle_order, level)
    if toggle_order == nil then
        return nil
    end

    Assert.table('toggleOrder', toggle_order, level or 3)

    local has_checked = false
    local has_unchecked = false

    for i = 1, #toggle_order do
        local entry = toggle_order[i]
        if not VALID_STATES[entry] then
            Assert.fail('invalid toggleOrder entry: ' .. tostring(entry), 3)
        end
        if entry == 'checked' then has_checked = true end
        if entry == 'unchecked' then has_unchecked = true end
    end

    if not has_checked or not has_unchecked then
        Assert.fail('toggleOrder must contain both "checked" and "unchecked"', 3)
    end

    return toggle_order
end

return {
    -- Spec: ui-controls 6.3 props: boolean | "indeterminate" | nil.
    checked = Rule.any_of({
        Rule.boolean(),
        Rule.literal('indeterminate')
    }, { optional = true }),
    onCheckedChange = ControlSchema.optional_callback(),
    disabled = Rule.boolean(false),
    -- Spec: ui-controls 6.3 anatomy/composition: optional associated content, non-interactive.
    label = ControlSchema.associated_content(),
    -- Spec: ui-controls 6.3 anatomy/composition: optional associated content, non-interactive.
    description = ControlSchema.associated_content(),
    toggleOrder = Rule.custom(function(_, value, _, level)
        return validate_toggle_order(value, level)
    end, { optional = true }),
}
