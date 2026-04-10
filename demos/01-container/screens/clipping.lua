local ScreenHelper = require('demos.common.screen_helper')
local UI = require('lib.ui')

local Container = UI.Container

return function(owner, helpers)
    return helpers.screen_wrapper(owner, function(stage)
        local root = stage.baseSceneLayer

        local overflow_parent = Container.new({
            id = 'clipping-overflow-parent',
            x = 0,
            y = 0,
            width = 220,
            height = 160,
            clipChildren = false,
        })
        root:addChild(overflow_parent)

        local overflow_child = Container.new({
            id = 'clipping-overflow-child',
            x = 120,
            y = 40,
            width = 160,
            height = 90,
        })
        overflow_parent:addChild(overflow_child)

        local overflow_grandchild = Container.new({
            id = 'clipping-overflow-grandchild',
            x = 90,
            y = 20,
            width = 120,
            height = 40,
        })
        overflow_child:addChild(overflow_grandchild)

        local clipped_parent = Container.new({
            id = 'clipping-clipped-parent',
            x = 0,
            y = 0,
            width = 220,
            height = 160,
            clipChildren = true,
        })
        root:addChild(clipped_parent)

        local clipped_child = Container.new({
            id = 'clipping-clipped-child',
            x = 120,
            y = 40,
            width = 160,
            height = 200,
        })
        clipped_parent:addChild(clipped_child)

        local clipped_grandchild = Container.new({
            id = 'clipping-clipped-grandchild',
            x = 90,
            y = 20,
            width = 140,
            height = 40,
        })
        clipped_child:addChild(clipped_grandchild)

        return {
            title = 'Overflow / Clipping',
            description = 'Click any visible box to toggle its clipChildren value. Compare the same overflowing subtree with clipping enabled or disabled at parent, child, and grandchild levels.',
        }
    end)
end
