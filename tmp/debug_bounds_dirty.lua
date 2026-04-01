local Stage = require('lib.ui.scene.stage')
local Container = require('lib.ui.core.container')

local stage = Stage.new({ width = 320, height = 180 })
local child = Container.new({ width = 100, height = 100 })

print("Before addChild: child._bounds_dirty = " .. tostring(rawget(child, '_bounds_dirty')))

stage.baseSceneLayer:addChild(child)

print("After addChild: child._bounds_dirty = " .. tostring(rawget(child, '_bounds_dirty')))

if rawget(child, '_bounds_dirty') then
    print("SUCCESS")
else
    print("FAILURE")
end

stage:destroy()
