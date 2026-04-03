local DemoColors = require('demos.common.colors')

local ALIGNMENTS = { 'start', 'center', 'end', 'stretch' }
local CASES = {}

local GRID_ORIGIN_X = 120
local GRID_ORIGIN_Y = 120
local GRID_STEP_X = 310
local GRID_STEP_Y = 180
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
            label = vertical_name .. ' ' .. horizontal_name,
            x = GRID_ORIGIN_X + ((column - 1) * GRID_STEP_X),
            y = GRID_ORIGIN_Y + ((row - 1) * GRID_STEP_Y),
            alignX = align_x,
            alignY = align_y,
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
                local node = helpers.make_node(scope, root, {
                    x = case.x,
                    y = case.y,
                    width = NODE_WIDTH,
                    height = NODE_HEIGHT,
                    alignX = case.alignX,
                    alignY = case.alignY,
                }, case.label, DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.2), DemoColors.roles.accent_blue_line)
                rawset(node, '_demo_sample_size', {
                    width = 72,
                    height = 40,
                })
                helpers.set_hint(node, function(current)
                    return {
                        {
                            label = 'alignment',
                            badges = {
                                helpers.badge('alignX', current.alignX),
                                helpers.badge('alignY', current.alignY),
                            },
                        },
                        {
                            label = 'rect.sample',
                            badges = {
                                helpers.badge('sample', helpers.format_rect(current:resolveContentRect(72, 40))),
                            },
                        },
                    }
                end)
            end

            return {
                title = 'Alignments',
                description = 'All 16 valid alignX/alignY combinations are shown here. Blue is the Drawable bounds, and cyan is the resolved 72x40 aligned sample.',
            }
        end
    )
end
