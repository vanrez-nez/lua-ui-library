local ScreenHelper = require('demos.common.screen_helper')
local UI = require('lib.ui')

local Container = UI.Container

return function(owner, helpers)
    return helpers.screen_wrapper(owner, function(scope, stage)
        local root = stage.baseSceneLayer
        local origin = helpers.random_root_position(520, 260, 120)

        local parent = Container.new({
            id = 'bounds-parent',
            x = origin.x,
            y = origin.y,
            width = 520,
            height = 260,
        })
        root:addChild(parent)

        local child_a = Container.new({
            id = 'bounds-child-a',
            x = 30,
            y = 30,
            width = 160,
            height = 90,
        })
        parent:addChild(child_a)

        local child_b = Container.new({
            id = 'bounds-child-b',
            x = 250,
            y = 40,
            width = 180,
            height = 120,
        })
        parent:addChild(child_b)

        local grandchild = Container.new({
            id = 'bounds-grandchild',
            x = 30,
            y = 30,
            width = 100,
            height = 50,
        })
        child_b:addChild(grandchild)

        local offset_child = Container.new({
            id = 'bounds-offset-child',
            x = -20,
            y = 70,
            width = 80,
            height = 30,
        })
        child_b:addChild(offset_child)

        return {
            title = 'Parent / Child Bounds',
            description = 'Verifies world coordinates across direct children and nested descendants while local bounds remain container-relative.',
        }
    end)
end
