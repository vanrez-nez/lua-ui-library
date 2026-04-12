local ScreenHelper = require('demos.common.screen_helper')

return function(owner)
    return ScreenHelper.screen_wrapper(owner, function()
        return {
            title = 'Empty Screen',
            description = 'Placeholder screen for the controls demo set. Add control-focused screens here as the contract cases are defined.',
        }
    end)
end
