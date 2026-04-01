local Stage = require('lib.ui.scene.stage')
local Container = require('lib.ui.core.container')

local stage = Stage.new({ width = 320, height = 180 })
local scope = Container.new({ x = 60, width = 120, height = 60 })
local inner_first = Container.new({ tag = 'inner_first', focusable = true, width = 40, height = 20 })
local inner_second = Container.new({ tag = 'inner_second', focusable = true, x = 50, width = 40, height = 20 })

stage.baseSceneLayer:addChild(scope)
scope:addChild(inner_first)
scope:addChild(inner_second)
stage:_set_focus_contract_internal(scope, { scope = true })
stage:update()

stage:_request_focus_internal(inner_first)
print("Initial owner: " .. (stage:_get_focus_owner_internal().tag or "none"))

stage:deliverInput({ kind = 'keypressed', key = 'tab' })
print("After tab 1: " .. (stage:_get_focus_owner_internal().tag or "none"))

stage:deliverInput({ kind = 'keypressed', key = 'tab' })
print("After tab 2: " .. (stage:_get_focus_owner_internal().tag or "none"))

if stage:_get_focus_owner_internal() == inner_first then
    print("SUCCESS: Wrapped to inner_first")
else
    print("FAILURE: Did not wrap correctly")
end

stage:destroy()
