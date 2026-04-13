local Memoize = {}

local NIL    = {}
local RESULT = {}

local function walk(cache, ...)
  local n    = select('#', ...)
  local node = cache
  for i = 1, n do
    local k = select(i, ...)
    if k == nil then k = NIL end
    local child = node[k]
    if not child then
      child = {}
      node[k] = child
    end
    node = child
  end
  return node
end

-- Single return value. No allocation on hit or miss (beyond trie nodes).
-- Use this for everything unless you explicitly need multiple returns.
function Memoize.memoize(fn)
  local cache = {}
  return function(...)
    local node = walk(cache, ...)
    local r = node[RESULT]
    if r == nil then
      r = fn(...)
      node[RESULT] = r == nil and NIL or r
    end
    return r == NIL and nil or r
  end
end

-- Multi return value. Allocates one table per unique arg combination.
-- Only pay this cost when you actually need it.
function Memoize.memoize_multi(fn)
  local cache = {}
  local pack  = function(...) return { n = select('#', ...), ... } end
  return function(...)
    local node = walk(cache, ...)
    if not node[RESULT] then
      node[RESULT] = pack(fn(...))
    end
    return unpack(node[RESULT], 1, node[RESULT].n)
  end
end

local current_tick = 0

function Memoize.memoize_tick(fn)
  local cache     = {}
  local last_tick = -1
  return function(...)
    if current_tick ~= last_tick then
      cache     = {}
      last_tick = current_tick
    end
    local node = walk(cache, ...)
    local r = node[RESULT]
    if r == nil then
      r = fn(...)
      node[RESULT] = r == nil and NIL or r
    end
    return r == NIL and nil or r
  end
end

function Memoize.tick()
  current_tick = current_tick + 1
end

return Memoize