local UI = require('lib.ui')

local Column = UI.Column
local Container = UI.Container
local Drawable = UI.Drawable
local Flow = UI.Flow
local Row = UI.Row
local Stack = UI.Stack

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        function(scope, stage)
            local root = stage.baseSceneLayer

            local host = Container.new({
                id = 'spacing-host',
                x = 0,
                y = 0,
                width = 420,
                height = 420,
            })
            root:addChild(host)

            local drawable_parent = Drawable.new({
                id = 'spacing-parent-drawable',
                width = 300,
                height = 300,
                padding = 0,
                margin = 0,
                backgroundColor = { 184, 191, 207, 18 },
                borderColor = { 184, 191, 207 },
                borderWidth = 1,
                borderStyle = 'rough',
                borderPattern = 'dashed',
                borderDashLength = 8,
                borderGapLength = 6,
            })
            local drawable_child = Drawable.new({
                id = 'spacing-child-drawable',
                x = 0,
                y = 0,
                width = 144,
                height = 144,
                padding = 10,
                margin = 0,
                backgroundColor = { 125, 235, 168, 51 },
                borderColor = { 125, 235, 168 },
                borderWidth = 1,
                borderStyle = 'rough',
            })
            drawable_parent:addChild(drawable_child)
            host:addChild(drawable_parent)

            local stack_parent = Stack.new({
                id = 'spacing-parent-stack',
                width = 300,
                height = 300,
                padding = 0,
                justify = 'center',
                align = 'center',
            })
            local stack_child = Drawable.new({
                id = 'spacing-child-stack',
                width = 144,
                height = 144,
                padding = 10,
                margin = 0,
                backgroundColor = { 125, 235, 168, 51 },
                borderColor = { 125, 235, 168 },
                borderWidth = 1,
                borderStyle = 'rough',
            })
            stack_parent:addChild(stack_child)
            host:addChild(stack_parent)

            local row_parent = Row.new({
                id = 'spacing-parent-row',
                width = 300,
                height = 300,
                padding = 0,
                justify = 'center',
                align = 'center',
            })
            local row_child = Drawable.new({
                id = 'spacing-child-row',
                width = 144,
                height = 144,
                padding = 10,
                margin = 0,
                backgroundColor = { 125, 235, 168, 51 },
                borderColor = { 125, 235, 168 },
                borderWidth = 1,
                borderStyle = 'rough',
            })
            row_parent:addChild(row_child)
            host:addChild(row_parent)

            local column_parent = Column.new({
                id = 'spacing-parent-column',
                width = 300,
                height = 300,
                padding = 0,
                justify = 'center',
                align = 'center',
            })
            local column_child = Drawable.new({
                id = 'spacing-child-column',
                width = 144,
                height = 144,
                padding = 10,
                margin = 0,
                backgroundColor = { 125, 235, 168, 51 },
                borderColor = { 125, 235, 168 },
                borderWidth = 1,
                borderStyle = 'rough',
            })
            column_parent:addChild(column_child)
            host:addChild(column_parent)

            local flow_parent = Flow.new({
                id = 'spacing-parent-flow',
                width = 300,
                height = 300,
                padding = 0,
                justify = 'center',
                align = 'center',
                wrap = true,
            })
            local flow_child = Drawable.new({
                id = 'spacing-child-flow',
                width = 144,
                height = 144,
                padding = 10,
                margin = 0,
                backgroundColor = { 125, 235, 168, 51 },
                borderColor = { 125, 235, 168 },
                borderWidth = 1,
                borderStyle = 'rough',
            })
            flow_parent:addChild(flow_child)
            host:addChild(flow_parent)

            return {
                title = 'Spacing Contracts',
                description = 'Spacing, alignment properties, and sizes react differently depending on how elements are nested. Each combination defines a behavior contract. Use the playground below to explore those differences across element types. Use the presets to navigate through common cases.',
            }
        end
    )
end
