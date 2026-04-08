local ScreenHelper = require('demos.common.screen_helper')
local UI = require('lib.ui')

local RectShape = UI.RectShape
local CircleShape = UI.CircleShape
local TriangleShape = UI.TriangleShape
local DiamondShape = UI.DiamondShape

return function(owner)
    return ScreenHelper.screen_wrapper(owner, function(scope, stage)
        local root = stage.baseSceneLayer
        local triangle = TriangleShape.new({
            id = 'shape-triangle',
            tag = 'TriangleShape',
            interactive = true,
            width = 100,
            height = 150,
            rotation = math.rad(-18),
            fillColor = { 0.98, 0.74, 0.28, 0.9 },
        })
        triangle:set_centroid_pivot()

        root:addChild(RectShape.new({
            id = 'shape-rect',
            tag = 'RectShape',
            interactive = true,
            width = 150,
            height = 100,
            rotation = math.rad(-8),
            fillColor = { 0.93, 0.48, 0.43, 0.9 },
        }))

        root:addChild(CircleShape.new({
            id = 'shape-circle',
            tag = 'CircleShape',
            interactive = true,
            width = 150,
            height = 100,
            rotation = math.rad(12),
            fillColor = { 0.28, 0.75, 0.95, 0.9 },
        }))

        root:addChild(triangle)

        root:addChild(DiamondShape.new({
            id = 'shape-diamond',
            tag = 'DiamondShape',
            interactive = true,
            width = 150,
            height = 100,
            rotation = math.rad(28),
            fillColor = { 0.45, 0.92, 0.58, 0.88 },
        }))

        return {
            title = 'Shape Primitive',
            description = "This screen shows the four built-in shape primitives directly. Hover each silhouette to compare shape-aware targeting against the dashed layout bounds while rotation changes the world box.",
        }
    end)
end
