local UI = require('lib.ui')

local Drawable = UI.Drawable
local ALIGNMENTS = { 'start', 'center', 'end', 'stretch' }
local CASES = {}
local NODE_WIDTH = 220
local NODE_HEIGHT = 120

for row = 1, #ALIGNMENTS do
    local align_y = ALIGNMENTS[row]
    for column = 1, #ALIGNMENTS do
        local align_x = ALIGNMENTS[column]
        local vertical_name = ({
            start = 'Top',
            center = 'Middle',
            ['end'] = 'Bottom',
            stretch = 'Stretch',
        })[align_y]
        local horizontal_name = ({
            start = 'Left',
            center = 'Center',
            ['end'] = 'Right',
            stretch = 'Stretch',
        })[align_x]
        CASES[#CASES + 1] = {
            id = string.format('alignments-%s-%s', align_y, align_x),
            label = vertical_name .. ' ' .. horizontal_name,
            alignX = align_x,
            alignY = align_y,
            row = row,
            column = column,
        }
    end
end

return function(owner, helpers)
    return helpers.screen_wrapper(
        owner,
        'Shows every valid Drawable alignment combination using only the Drawable bounds and the resolved sample box.',
        function(scope, stage)
            local root = stage.baseSceneLayer

            for index = 1, #CASES do
                local case = CASES[index]
                local node = Drawable.new({
                    id = case.id,
                    x = 0,
                    y = 0,
                    width = NODE_WIDTH,
                    height = NODE_HEIGHT,
                    alignX = case.alignX,
                    alignY = case.alignY,
                    backgroundColor = { 117, 184, 255, 51 },
                    borderColor = { 117, 184, 255 },
                    borderWidth = 1,
                })
                node:addChild(Drawable.new({
                    internal = true,
                    enabled = false,
                    x = 0,
                    y = 0,
                    width = 72,
                    height = 40,
                    backgroundColor = { 107, 235, 250, 89 },
                    borderColor = { 107, 235, 250 },
                    borderWidth = 1,
                }))
                root:addChild(node)
            end

            return {
                title = 'Alignments',
                description = 'All 16 valid alignX/alignY combinations are shown here. Blue is the Drawable bounds, and cyan is the resolved 72x40 aligned sample.',
            }
        end
    )
end
