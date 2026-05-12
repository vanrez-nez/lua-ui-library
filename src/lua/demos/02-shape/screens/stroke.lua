local ScreenHelper = require('demos.common.screen_helper')
local UI = require('lib.ui')

local RectShape = UI.RectShape
local CircleShape = UI.CircleShape
local TriangleShape = UI.TriangleShape
local DiamondShape = UI.DiamondShape

return function(owner)
    return ScreenHelper.screen_wrapper(owner, function(stage)
        local root = stage.baseSceneLayer

        root:addChild(RectShape.new({
            id = 'stroke-rect',
            interactive = true,
            width = 160,
            height = 110,
            fillColor = { 0.93, 0.48, 0.43, 0.24 },
            strokeColor = { 0.98, 0.58, 0.54, 1.0 },
            strokeWidth = 4,
            strokeStyle = 'smooth',
            strokeJoin = 'miter',
            strokePattern = 'solid',
        }))

        root:addChild(CircleShape.new({
            id = 'stroke-circle',
            interactive = true,
            width = 100,
            height = 150,
            fillColor = { 0.28, 0.75, 0.95, 0.22 },
            strokeColor = { 0.50, 0.90, 1.0, 1.0 },
            strokeWidth = 4,
            strokeStyle = 'smooth',
            strokePattern = 'dashed',
            strokeDashLength = 20,
            strokeGapLength = 10,
        }))

        root:addChild(TriangleShape.new({
            id = 'stroke-triangle',
            interactive = true,
            width = 140,
            height = 170,
            fillColor = { 0.98, 0.74, 0.28, 0.20 },
            strokeColor = { 1.0, 0.86, 0.46, 1.0 },
            strokeOpacity = 0.75,
            strokeWidth = 4,
            strokeStyle = 'rough',
            strokeJoin = 'bevel',
            strokePattern = 'solid',
        }))

        root:addChild(DiamondShape.new({
            id = 'stroke-diamond',
            interactive = true,
            width = 150,
            height = 120,
            opacity = 1,
            fillColor = { 0.45, 0.92, 0.58, 0.18 },
            strokeColor = { 0.70, 1.0, 0.80, 1.0 },
            strokeWidth = 4,
            strokeStyle = 'rough',
            strokePattern = 'dashed',
            strokeDashLength = 18,
            strokeGapLength = 8,
        }))

        return {
            title = 'Shape Stroke',
            description = 'Use the selectors to change stroke style, pattern, width, dash, and gap across all shapes.',
        }
    end)
end
