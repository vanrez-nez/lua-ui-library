local Utils = require('profiler.utils')

local Token = {}

function Token.open()
  return {
    started_at = Utils.now_seconds(),
    started_heap_kb = Utils.heap_kb(),
    child_time = 0,
    child_memory_kb = 0
  }
end

function Token.close(token)
  local elapsed = Utils.now_seconds() - token.started_at
  local memory_delta_kb = Utils.heap_kb() - token.started_heap_kb
  local self_time = elapsed - token.child_time
  if self_time < 0 then self_time = 0 end
  local self_memory_delta_kb = memory_delta_kb - token.child_memory_kb
  return elapsed, memory_delta_kb, self_time, self_memory_delta_kb
end

function Token.propagate(parent, elapsed, memory_delta_kb)
  if parent == nil then return end
  parent.child_time = parent.child_time + elapsed
  parent.child_memory_kb = parent.child_memory_kb + memory_delta_kb
end

return Token
