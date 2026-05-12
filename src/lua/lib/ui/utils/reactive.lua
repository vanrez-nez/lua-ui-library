--- Reactive.lua
---
--- Minimal reactive property container with per-key getter/setter hooks.
---
--- Design goals:
--- - Own its full metatable and avoid interfering with host objects/classes.
--- - Keep read/write dispatch minimal and predictable.
--- - Store all reactive state behind one internal key.
--- - Use one shared metatable for all instances to avoid per-object closure allocation.
---
--- Two-tier property storage:
---   Hook-free properties — value lives as a raw key directly on obj.
---     Lua never calls __index/__newindex for keys that exist on the raw table.
---     Reads and writes are plain table ops; the JIT sees no metamethod boundary.
---
---   Hooked properties — key is kept absent from obj (rawset to nil at define time).
---     __index/__newindex engage only for these keys.
---     Value lives in state.values; getter/setter live in state.getters/state.setters.
---
--- Consequences of two-tier design:
---   - raw_get / raw_set must branch on whether the key is hooked.
---   - __pairs must merge raw obj keys with state.values.
---   - remove_property must clean both tiers.
---   - state.values is NOT a full mirror of all property values; it only holds
---     hooked property values.

local Reactive = {}

-- Table reference key — unique by address, impossible to collide with
-- any string or external table key.
local ACCESSOR = {}
local RMETA = {}

-- READ — only reached for hooked properties; hook-free keys exist raw on obj
-- and Lua resolves them without calling __index.
RMETA.__index = function(self, key)
  local state = rawget(self, ACCESSOR)
  local getter = state.getters[key]
  if getter then
    return getter(self, state.values[key])
  end
  return state.values[key]
end

-- WRITE — only reached for hooked properties, same reasoning as above.
-- Equality short-circuit sits before setter dispatch: pure transforms
-- produce identical output for identical input, so the call is skipped.
RMETA.__newindex = function(self, key, val)
  local state = rawget(self, ACCESSOR)
  if not state then rawset(self, key, val); return end

  local old = state.values[key]
  if rawequal(val, old) then return end

  local setter = state.setters[key]
  if setter then
    local new = setter(self, val, old)
    assert(new ~= nil,
      'Reactive: setter for key "' .. tostring(key) .. '" must return a value')
    state.values[key] = new
    return
  end
  if state.getters[key] == nil then
    rawset(self, key, val)
    state.values[key] = nil
    return
  end
  state.values[key] = val
end

-- PAIRS — merges both tiers into a single iteration.
-- Hook-free properties are raw keys on obj (excluding ACCESSOR).
-- Hooked properties are absent from obj but present in state.values.
-- Allocates one scratch table per iteration; __pairs is not a hot path.
RMETA.__pairs = function(self)
  local state = rawget(self, ACCESSOR)
  local result = {}
  for k, v in next, self do
    if k ~= ACCESSOR then result[k] = v end
  end
  for k, v in next, state.values do
    result[k] = v
  end
  return next, result, nil
end

local function init_metatable(obj)
  local state = rawget(obj, ACCESSOR)
  if not state then
    state = {
      values = {},
      getters = {},
      setters = {},
    }
    rawset(obj, ACCESSOR, state)
    setmetatable(obj, RMETA)
  end
  return state
end

local function is_hooked(state, key)
  return state.getters[key] ~= nil or state.setters[key] ~= nil
end

--- Define or redefine a reactive property on obj.
---
--- Hook-free properties are stored as raw keys on obj. Hooked properties
--- are kept absent from obj so metamethods engage; their values live in
--- state.values. Redefining a previously hooked property as hook-free (or
--- vice versa) is handled correctly — both tiers are cleaned up first.
function Reactive.define_property(obj, key, def)
  local state = init_metatable(obj)
  local has_hooks = def.get ~= nil or def.set ~= nil

  state.getters[key] = nil
  state.setters[key] = nil

  if def.get ~= nil then
    assert(type(def.get) == 'function',
      'Reactive.define_property: def.get must be a function or nil')
    state.getters[key] = def.get
  end

  if def.set ~= nil then
    assert(type(def.set) == 'function',
      'Reactive.define_property: def.set must be a function or nil')
    state.setters[key] = def.set
  end

  if has_hooks then
    -- Keep key absent from obj so __index/__newindex stay engaged.
    -- rawset to nil removes the key if it previously existed as hook-free.
    rawset(obj, key, nil)
    state.values[key] = def.val
  else
    -- Plant value directly on obj. Lua resolves this key without ever
    -- calling __index or __newindex — zero metamethod overhead.
    -- Clear state.values in case this key was previously hooked.
    state.values[key] = nil
    rawset(obj, key, def.val)
  end
end

--- Remove a property and all its hooks from obj.
--- Cleans both tiers: raw key on obj and state.values entry.
function Reactive.remove_property(obj, key)
  local state = rawget(obj, ACCESSOR)
  if not state then return end
  rawset(obj, key, nil)
  state.values[key] = nil
  state.getters[key] = nil
  state.setters[key] = nil
end

--- Read a property value directly, bypassing any getter.
--- Routes to the correct tier based on whether the key has hooks.
function Reactive.raw_get(obj, key)
  local state = rawget(obj, ACCESSOR)
  if not state then return rawget(obj, key) end
  if is_hooked(state, key) then
    return state.values[key]
  end
  return rawget(obj, key)
end

--- Write a property value directly, bypassing any setter and equality guard.
--- Routes to the correct tier based on whether the key has hooks.
--- Does not accept nil — use remove_property for explicit removal.
function Reactive.raw_set(obj, key, val)
  assert(val ~= nil, 'Reactive.raw_set: val must not be nil — use remove_property to delete')
  local state = rawget(obj, ACCESSOR)
  if not state then return end
  if is_hooked(state, key) then
    state.values[key] = val
  else
    rawset(obj, key, val)
  end
end

--- Create a new reactive object from a property definition table.
---
--- Example:
--- {
---   foo = {
---     val = 3,
---     get = function(self, v) return v end,
---     set = function(self, v, old) return v end,
---   },
---   bar = { val = 10 },  -- hook-free: raw key on obj, no metamethod cost
--- }
function Reactive.create(definitions)
  local obj = {}
  init_metatable(obj)
  for key, def in pairs(definitions) do
    Reactive.define_property(obj, key, def)
  end
  return obj
end

return Reactive
