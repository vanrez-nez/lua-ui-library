local UI = require('lib.ui')

local Container = UI.Container

return function(owner, helpers)
    return helpers.screen_wrapper(owner, function(stage)
        local root = stage.baseSceneLayer

        local viewport = Container.new({
            id = 'sizing-viewport',
            x = 0,
            y = 0,
            width = 'fill',
            height = 'fill',
        })
        root:addChild(viewport)

        local parent = Container.new({
            id = 'sizing-parent',
            x = 0,
            y = 0,
            width = 400,
            height = 250,
        })
        viewport:addChild(parent)

        local child = Container.new({
            id = 'sizing-child',
            x = 20,
            y = 20,
            width = '60%',
            height = '60%',
        })
        parent:addChild(child)

        local grandchild = Container.new({
            id = 'sizing-grandchild',
            x = 20,
            y = 20,
            width = '50%',
            height = '60%',
        })
        child:addChild(grandchild)

        local great_grandchild = Container.new({
            id = 'sizing-great-grandchild',
            x = 0,
            y = 0,
            width = 60,
            height = '50%',
        })
        grandchild:addChild(great_grandchild)

        return {
            title = 'Fixed / Fill / Percent Sizing',
            description = [[
                Viewport fills the stage, Root uses fixed sizing, Root->A resolves percent sizing from Root,
                A->B resolves nested percentages, and B->C mixes fixed width with percentage height.
            ]],
        }
    end)
end
