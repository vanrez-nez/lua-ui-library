local ScreenHelper = require('demos.common.screen_helper')
local UI = require('lib.ui')

local Container = UI.Container

return function(owner, helpers)
    return helpers.screen_wrapper(owner, function(stage)
        local root = stage.baseSceneLayer

        local width_parent = Container.new({
            id = 'clamp-width-parent',
            x = 0,
            y = 0,
            width = 200,
            height = 150,
        })
        root:addChild(width_parent)

        local width_case = Container.new({
            id = 'clamp-width-case',
            x = 20,
            y = 20,
            width = '80%',
            height = 100,
            minWidth = 120,
            maxWidth = 180,
        })
        width_parent:addChild(width_case)

        local height_parent = Container.new({
            id = 'clamp-height-parent',
            x = 0,
            y = 0,
            width = 200,
            height = 150,
        })
        root:addChild(height_parent)

        local height_case = Container.new({
            id = 'clamp-height-case',
            x = 30,
            y = 20,
            width = 120,
            height = '80%',
            minHeight = 70,
            maxHeight = 120,
        })
        height_parent:addChild(height_case)

        local both_parent = Container.new({
            id = 'clamp-both-parent',
            x = 0,
            y = 0,
            width = 250,
            height = 150,
        })
        root:addChild(both_parent)

        local both_case = Container.new({
            id = 'clamp-both-case',
            x = 10,
            y = 20,
            width = '90%',
            height = '70%',
            minWidth = 220,
            maxWidth = 260,
            minHeight = 80,
            maxHeight = 100,
        })
        both_parent:addChild(both_case)

        return {
            title = 'Min / Max Clamps',
            description = 'Each parent resizes while its child uses percentage sizing plus min and max clamps, so the child visibly hits clamp limits as the parent changes.',
        }
    end)
end
