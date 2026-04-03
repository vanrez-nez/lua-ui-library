local DemoColors = require('demos.common.colors')
local DemoInstruments = require('demos.02-drawable.demo_instruments')

local GRID_STEP_X = 310
local GRID_STEP_Y = 180
local SAMPLE_WIDTH = 72
local SAMPLE_HEIGHT = 40
local ALIGNMENTS = { 'start', 'center', 'end', 'stretch' }

local Setup = {}

local function case_label(align_y, align_x)
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

    return vertical_name .. ' ' .. horizontal_name
end

local function collect_cases(root)
    local nodes = {}

    for row = 1, #ALIGNMENTS do
        local align_y = ALIGNMENTS[row]
        for column = 1, #ALIGNMENTS do
            local align_x = ALIGNMENTS[column]
            local node_id = string.format('alignments-%s-%s', align_y, align_x)
            local node = root:findById(node_id, -1)
            if node == nil then
                error('alignments_setup: missing node "' .. node_id .. '"', 2)
            end

            nodes[#nodes + 1] = {
                node = node,
                align_x = align_x,
                align_y = align_y,
                row = row,
                column = column,
                label = case_label(align_y, align_x),
            }
        end
    end

    return nodes
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local cases = collect_cases(root)

    for index = 1, #cases do
        local entry = cases[index]
        DemoInstruments.decorate_drawable(entry.node, {
            label = entry.label,
            fill = DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.2),
            line = DemoColors.roles.accent_blue_line,
        })
        rawset(entry.node, '_demo_sample_size', {
            width = SAMPLE_WIDTH,
            height = SAMPLE_HEIGHT,
        })
        helpers.set_hint(entry.node, function(current)
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
                        helpers.badge('sample', helpers.format_rect(current:resolveContentRect(SAMPLE_WIDTH, SAMPLE_HEIGHT))),
                    },
                },
            }
        end)
    end

    rawset(args.stage, '_demo_screen_hooks', {
        update = function()
            local viewport = root:getWorldBounds()
            local total_width = cases[1].node.width + GRID_STEP_X * (#ALIGNMENTS - 1)
            local total_height = cases[1].node.height + GRID_STEP_Y * (#ALIGNMENTS - 1)
            local start_x = math.floor((viewport.width - total_width) * 0.5 + 0.5)
            local start_y = math.floor((viewport.height - total_height) * 0.5 + 0.5)

            for index = 1, #cases do
                local entry = cases[index]
                entry.node.x = start_x + ((entry.column - 1) * GRID_STEP_X)
                entry.node.y = start_y + ((entry.row - 1) * GRID_STEP_Y)
            end
        end,
    })
end

return Setup
