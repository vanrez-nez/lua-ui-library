local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')

return {
    open = Rule.boolean({ optional = true }),
    onOpenChange = Rule.func({ optional = true }),
    dismissOnBackdrop = Rule.boolean(true),
    dismissOnEscape = Rule.boolean(true),
    trapFocus = Rule.boolean(true),
    restoreFocus = Rule.boolean(true),
    safeAreaAware = Rule.boolean(true),
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
