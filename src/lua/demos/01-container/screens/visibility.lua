local UI = require('lib.ui')

local Container = UI.Container

return function(owner, helpers)
    return helpers.screen_wrapper(owner, function(stage)
        local root = stage.baseSceneLayer

        local parent = Container.new({
            id = 'visibility-parent',
            x = 0,
            y = 0,
            width = 250,
            height = 200,
        })
        root:addChild(parent)

        local child = Container.new({
            id = 'visibility-child',
            x = 30,
            y = 20,
            width = 180,
            height = 130,
        })
        parent:addChild(child)

        local grandchild = Container.new({
            id = 'visibility-grandchild',
            x = 20,
            y = 20,
            width = 120,
            height = 90,
        })
        child:addChild(grandchild)

        local great_grandchild = Container.new({
            id = 'visibility-great-grandchild',
            x = 20,
            y = 15,
            width = 70,
            height = 45,
        })
        grandchild:addChild(great_grandchild)

        return {
            title = 'Visibility',
            description = 'Three nested descendants blink at different timings so visibility changes stay easy to compare across parent-child levels.',
        }
    end)
end
