local ScreenHelper = require('demos.common.screen_helper')
local UI = require('lib.ui')

local Container = UI.Container

return function(owner, helpers)
    return helpers.screen_wrapper(owner, function(scope, stage)
        local root = stage.baseSceneLayer

        local single_parent = Container.new({
            id = 'pivot-single-parent',
            x = 0,
            y = 0,
            width = 280,
            height = 280,
        })
        root:addChild(single_parent)

        local single_child = Container.new({
            id = 'pivot-single-child',
            x = 80,
            y = 100,
            width = 120,
            height = 80,
            pivotX = 0.5,
            pivotY = 0.5,
            rotation = 0,
        })
        single_parent:addChild(single_child)

        local nested_parent = Container.new({
            id = 'pivot-nested-parent',
            x = 0,
            y = 0,
            width = 320,
            height = 300,
        })
        root:addChild(nested_parent)

        local nested_child = Container.new({
            id = 'pivot-nested-child',
            x = 50,
            y = 50,
            width = 140,
            height = 100,
            pivotX = 0,
            pivotY = 0,
            rotation = 0,
        })
        nested_parent:addChild(nested_child)

        local nested_grandchild = Container.new({
            id = 'pivot-nested-grandchild',
            x = 90,
            y = 60,
            width = 80,
            height = 60,
            pivotX = 1,
            pivotY = 1,
            rotation = 0,
        })
        nested_child:addChild(nested_grandchild)

        return {
            title = 'Pivot Rotation',
            description = 'Rotation stays tied to pivotX and pivotY, first on a single node and then through a nested transform chain.',
        }
    end)
end
