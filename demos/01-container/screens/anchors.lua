local ScreenHelper = require('demos.common.screen_helper')
local UI = require('lib.ui')

local Container = UI.Container

return function(owner, helpers)
    return helpers.screen_wrapper(owner, function(stage)
        local root = stage.baseSceneLayer

        local single_parent = Container.new({
            id = 'anchors-single-parent',
            x = 0,
            y = 0,
            width = 250,
            height = 250,
        })
        root:addChild(single_parent)

        local single_child = Container.new({
            id = 'anchors-single-child',
            x = 0,
            y = 0,
            width = 100,
            height = 70,
            anchorX = 0.5,
            anchorY = 0.5,
            pivotX = 0.5,
            pivotY = 0.5,
            rotation = 0,
        })
        single_parent:addChild(single_child)

        local nested_parent = Container.new({
            id = 'anchors-nested-parent',
            x = 0,
            y = 0,
            width = 300,
            height = 250,
        })
        root:addChild(nested_parent)

        local nested_child = Container.new({
            id = 'anchors-nested-child',
            x = -30,
            y = -20,
            width = 130,
            height = 100,
            anchorX = 1,
            anchorY = 1,
        })
        nested_parent:addChild(nested_child)

        local nested_grandchild = Container.new({
            id = 'anchors-nested-grandchild',
            x = 0,
            y = 0,
            width = 60,
            height = 40,
            anchorX = 0.5,
            anchorY = 0.5,
            pivotX = 0.5,
            pivotY = 0.5,
            rotation = 0,
        })
        nested_child:addChild(nested_grandchild)

        return {
            title = 'Anchor Placement',
            description = 'Parents resize while anchorX and anchorY keep direct and nested children attached to parent-relative positions.',
        }
    end)
end
