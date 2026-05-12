local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local ControlSchema = require('lib.ui.controls.control_schema')

return {
    open = Rule.boolean({ optional = true }),
    onOpenChange = ControlSchema.optional_callback(),
    dismissOnBackdrop = Rule.boolean(true),
    dismissOnEscape = Rule.boolean(true),
    trapFocus = Rule.boolean(true),
    restoreFocus = Rule.boolean(true),
    safeAreaAware = Rule.boolean(true),
    content = Rule.table({ optional = true }),
    backdropDismissBehavior = Rule.custom(function(_, value, level)
        if value ~= 'close' and value ~= 'ignore' then
            Assert.fail(
                'Modal.backdropDismissBehavior must be "close" or "ignore"',
                level or 1
            )
        end

        return value
    end, { default = 'close' }),
}
