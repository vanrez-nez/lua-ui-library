local UI = require('lib.ui')

local Container = UI.Container

return function(owner, helpers)
    return helpers.screen_wrapper(owner, function(stage)
        local root = stage.baseSceneLayer

        local parent = Container.new({
            id = 'percentage-parent',
            x = 0,
            y = 0,
            width = '55%',
            height = '60%',
            minWidth = 350,
            minHeight = 250,
        })
        root:addChild(parent)

        local child = Container.new({
            id = 'percentage-child',
            x = 20,
            y = 20,
            width = '50%',
            height = '50%',
        })
        parent:addChild(child)

        local nested = Container.new({
            id = 'percentage-nested',
            x = 10,
            y = 10,
            width = '50%',
            height = '50%',
        })
        child:addChild(nested)

        return {
            title = 'Nested Percentage Sizing',
            description = table.concat({
                'Shows percentage sizing recalculating from the effective parent region',
                'while the root container moves in a circular path.',
            }, ' '),
        }
    end)
end
