local Stage = require('lib.ui.scene.stage')
local Container = require('lib.ui.core.container')

local function dump_candidates(stage, scope)
    local candidates = {}
    local function collect(node)
        if stage:_is_focusable_candidate_internal(node, scope) then
            candidates[#candidates+1] = node.tag or "unnamed"
        end
        local children = rawget(node, '_children') or {}
        for i=1,#children do collect(children[i]) end
    end
    collect(scope)
    print("Candidates: " .. table.concat(candidates, ", "))
end

-- We'll bridge into stage internals since they are local
-- Actually, I'll just use the public API if possible.

local stage = Stage.new({ width = 320, height = 180 })
local scope = Container.new({ tag = 'scope', focusable = false, width = 120, height = 60 })
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

stage:destroy()
