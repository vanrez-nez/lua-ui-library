local UI = require('lib.ui')

local Container = UI.Container

return function(owner, helpers)
    return helpers.screen_wrapper(owner, function(stage)
        local root = stage.baseSceneLayer

        local single_parent = Container.new({
            id = 'scale-single-parent',
            x = 0,
            y = 0,
            width = 280,
            height = 260,
        })
        root:addChild(single_parent)

        local single_child = Container.new({
            id = 'scale-single-child',
            x = 0,
            y = 0,
            width = 100,
            height = 80,
            pivotX = 0.5,
            pivotY = 0.5,
            scaleX = 1,
            scaleY = 1,
        })
        single_parent:addChild(single_child)

        local nested_parent = Container.new({
            id = 'scale-nested-parent',
            x = 0,
            y = 0,
            width = 320,
            height = 280,
        })
        root:addChild(nested_parent)

        local nested_child = Container.new({
            id = 'scale-nested-child',
            x = 0,
            y = 0,
            width = 140,
            height = 100,
            pivotX = 0.5,
            pivotY = 0.5,
            scaleX = 1.2,
            scaleY = 0.85,
        })
        nested_parent:addChild(nested_child)

        local nested_grandchild = Container.new({
            id = 'scale-nested-grandchild',
            x = 0,
            y = 0,
            width = 70,
            height = 50,
            pivotX = 0.5,
            pivotY = 0.5,
            scaleX = 0.9,
            scaleY = 1.35,
        })
        nested_child:addChild(nested_grandchild)

        return {
            title = 'Scaling',
            description = table.concat({
                'scaleX and scaleY stretch direct and nested nodes',
                'while the cases translate to keep the transforms easy to read.',
            }, ' '),
        }
    end)
end
