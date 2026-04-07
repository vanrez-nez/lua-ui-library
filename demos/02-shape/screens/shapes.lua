local ScreenHelper = require('demos.common.screen_helper')
local UI = require('lib.ui')

local Drawable = UI.Drawable
local CircleShape = UI.CircleShape
local TriangleShape = UI.TriangleShape
local DiamondShape = UI.DiamondShape

return function(owner)
    return ScreenHelper.screen_wrapper(owner, function(scope, stage)
        local root = stage.baseSceneLayer

        root:addChild(Drawable.new({
            id = 'shape-backdrop',
            x = 80,
            y = 110,
            width = 1140,
            height = 620,
            backgroundColor = { 18, 24, 33, 214 },
            borderColor = { 84, 104, 138, 255 },
            borderWidth = 2,
        }))

        root:addChild(Drawable.new({
            id = 'mixed-drawable-probe',
            tag = 'Drawable Probe',
            interactive = true,
            x = 900,
            y = 190,
            width = 210,
            height = 150,
            backgroundColor = { 209, 95, 69, 224 },
            borderColor = { 244, 177, 143, 255 },
            borderWidth = 2,
        }))

        root:addChild(Drawable.new({
            id = 'circle-frame',
            x = 150,
            y = 180,
            width = 220,
            height = 160,
            backgroundColor = nil,
            borderColor = { 116, 136, 168, 255 },
            borderWidth = 1,
            borderPattern = 'dashed',
            borderDashLength = 8,
            borderStyle = 'rough',
        }))
        root:addChild(ScreenHelper.set_markers(CircleShape.new({
            id = 'shape-circle',
            tag = 'CircleShape',
            interactive = true,
            x = 150,
            y = 180,
            width = 220,
            height = 160,
            rotation = math.rad(12),
            pivotX = 0.5,
            pivotY = 0.5,
            fillColor = { 0.28, 0.75, 0.95, 0.9 },
        }), {
            { type = 'pivot', color = { 0.66, 0.91, 1.0, 1.0 } },
        }))

        root:addChild(Drawable.new({
            id = 'triangle-frame',
            x = 440,
            y = 180,
            width = 220,
            height = 180,
            backgroundColor = nil,
            borderColor = { 116, 136, 168, 255 },
            borderWidth = 1,
            borderPattern = 'dashed',
            borderDashLength = 8,
            borderStyle = 'rough',
        }))
        root:addChild(ScreenHelper.set_markers(TriangleShape.new({
            id = 'shape-triangle',
            tag = 'TriangleShape',
            interactive = true,
            x = 440,
            y = 180,
            width = 220,
            height = 180,
            rotation = math.rad(-18),
            -- pivotX = 0.5,
            -- pivotY = 0.5,
            fillColor = { 0.98, 0.74, 0.28, 0.9 },
        }), {
            { type = 'pivot', color = { 1.0, 0.90, 0.56, 1.0 } },
        }))

        root:addChild(Drawable.new({
            id = 'diamond-frame',
            x = 720,
            y = 410,
            width = 220,
            height = 170,
            backgroundColor = nil,
            borderColor = { 116, 136, 168, 255 },
            borderWidth = 1,
            borderPattern = 'dashed',
            borderDashLength = 8,
            borderStyle = 'rough',
        }))
        root:addChild(ScreenHelper.set_markers(DiamondShape.new({
            id = 'shape-diamond',
            tag = 'DiamondShape',
            interactive = true,
            x = 720,
            y = 410,
            width = 220,
            height = 170,
            rotation = math.rad(28),
            -- pivotX = 0.5,
            -- pivotY = 0.5,
            fillColor = { 0.45, 0.92, 0.58, 0.88 },
        }), {
            { type = 'pivot', color = { 0.74, 1.0, 0.80, 1.0 } },
        }))

        return {
            title = 'Shape Primitive',
            description = 'Hover the filled silhouettes. Dashed rectangles show layout bounds, not hit bounds, so the empty corners stay untargetable even after rotation. The red Drawable proves mixed Shape/Drawable trees still resolve by normal retained z-order.',
        }
    end)
end
