--- DirtyProps (sync strategy) — bitwise per-frame property change tracking
--
-- sync() builds a single dirty_mask integer via bitwise OR.
-- All queries are O(1) band operations — no loops, no table lookups.
--
-- Hard limit: 31 props per object (LuaJIT signed 32-bit integers).
--
-- Usage:
--   local props = DirtyProps.create({
--     x     = { val = 0,   groups = { 'layout' } },
--     y     = { val = 0,   groups = { 'layout' } },
--     color = { val = 0xff0000 },
--   })
--
--   props:reset()
--   props.x = 10
--   props:sync()
--
--   props:is_dirty('x')          --> true
--   props:group_dirty('layout')  --> true

local bit    = require('bit')
local Common = require('lib.ui.utils.common')

-- [OPT] Upvalue caching — avoids a 'bit' table lookup on every sync() call
-- and every query. Particularly impactful inside sync()'s inner loop.
local band   = bit.band
local bor    = bit.bor
local lshift = bit.lshift

local DirtyProps = {}
DirtyProps.__index = DirtyProps

local ACCESSOR = {}

local function get_state(obj)
  return rawget(obj, ACCESSOR)
end

local function init_metatable(obj)
  local state = get_state(obj)
  if not state then
    state = {
      -- [OPT] Consolidated per-key metadata replaces two separate sub-tables
      -- (prop_bits, cache). sync()'s inner loop does one hash lookup per prop
      -- (state.props[key]) + two integer array accesses (p[1]/p[2]) instead
      -- of two independent hash lookups across two tables.
      --   p[1] = bit mask    (integer)
      --   p[2] = cached value (last known value)
      props        = {},
      group_masks  = {},  -- { [group] = integer bitmask, OR of member bits }
      properties   = {},  -- ordered list of all tracked keys
      dirty_mask   = 0,
      bit_count    = 0,
    }
    rawset(obj, ACCESSOR, state)
    setmetatable(obj, DirtyProps)
  end
  return state
end

local function define(obj, key, def)
  local state  = init_metatable(obj)
  local groups = def.groups or {}
  assert(state.bit_count < 31, 'DirtyProps: max 31 props per object')
  local b = lshift(1, state.bit_count)
  state.bit_count = state.bit_count + 1
  rawset(obj, key, def.val)
  state.props[key] = { b, def.val }  -- { bit, cached_val }
  state.properties[#state.properties + 1] = key
  for _, g in ipairs(groups) do
    state.group_masks[g] = bor(state.group_masks[g] or 0, b)
  end
end

--- Diffs all props and builds dirty_mask in one pass.
--- All downstream queries are O(1) band operations.
--- @return self
function DirtyProps:sync()
  local state      = get_state(self)
  local props      = state.props
  -- [OPT] Cache the properties list reference so the loop body doesn't
  -- re-resolve it through state on each iteration.
  local properties = state.properties
  local mask       = 0

  -- [OPT] Numeric for instead of ipairs — eliminates the iterator function
  -- call overhead per step. The limit (#properties) is evaluated once by
  -- the numeric for, not per iteration.
  for i = 1, #properties do
    local key = properties[i]
    local p   = props[key]
    -- [OPT] rawget bypasses __index since props are always stored as direct
    -- fields on the object (set via rawset in define / direct assignment).
    local curr = rawget(self, key)
    if curr ~= p[2] then
      p[2]  = curr
      mask  = bor(mask, p[1])
    end
  end

  state.dirty_mask = mask
end

--- Resets dirty state and aligns cache to current values.
function DirtyProps:reset()
  local state = get_state(self)
  local props = state.props
  for _, key in ipairs(state.properties) do
    props[key][2] = rawget(self, key)
  end
  state.dirty_mask = 0
  return self
end

--- Marks one or more groups dirty from outside the sync cycle.
function DirtyProps:mark_dirty(...)
  local state = get_state(self)
  local gm    = state.group_masks
  local mask  = state.dirty_mask
  -- [OPT] select instead of ipairs({...}) — zero table allocation per call.
  for i = 1, select('#', ...) do
    local m = gm[select(i, ...)]
    if m then mask = bor(mask, m) end
  end
  state.dirty_mask = mask
  return self
end

--- @param  key  string
--- @return boolean
function DirtyProps:is_dirty(key)
  local s = get_state(self)
  return band(s.dirty_mask, s.props[key][1]) ~= 0
end

--- OR: true if any of the given props are dirty.
function DirtyProps:any_dirty(...)
  local s    = get_state(self)
  local props = s.props
  local mask = s.dirty_mask
  for i = 1, select('#', ...) do
    if band(mask, props[select(i, ...)][1]) ~= 0 then return true end
  end
  return false
end

--- AND: true if all of the given props are dirty.
function DirtyProps:all_dirty(...)
  local s    = get_state(self)
  local props = s.props
  local mask = s.dirty_mask
  for i = 1, select('#', ...) do
    if band(mask, props[select(i, ...)][1]) == 0 then return false end
  end
  return true
end

--- @param  name  string
--- @return boolean
function DirtyProps:group_dirty(name)
  local s = get_state(self)
  local m = s.group_masks[name]
  return m ~= nil and band(s.dirty_mask, m) ~= 0
end

--- OR: true if any of the given groups are dirty.
function DirtyProps:group_any_dirty(...)
  local s    = get_state(self)
  local gm   = s.group_masks
  local mask = s.dirty_mask
  for i = 1, select('#', ...) do
    local m = gm[select(i, ...)]
    if m and band(mask, m) ~= 0 then return true end
  end
  return false
end

--- AND: true if all of the given groups are dirty.
function DirtyProps:group_all_dirty(...)
  local s    = get_state(self)
  local gm   = s.group_masks
  local mask = s.dirty_mask
  for i = 1, select('#', ...) do
    local m = gm[select(i, ...)]
    if not m or band(mask, m) == 0 then return false end
  end
  return true
end

--- Returns a copy of the dirty props map: { [key] = bool }.
function DirtyProps:get_dirty_props()
  local s      = get_state(self)
  local props  = s.props
  local mask   = s.dirty_mask
  local result = {}
  for _, key in ipairs(s.properties) do
    result[key] = band(mask, props[key][1]) ~= 0
  end
  return result
end

--- Returns a copy of the dirty groups map: { [group] = bool }.
function DirtyProps:get_dirty_groups()
  local s      = get_state(self)
  local mask   = s.dirty_mask
  local result = {}
  for name, m in pairs(s.group_masks) do
    result[name] = band(mask, m) ~= 0
  end
  return result
end

--- Creates and returns a tracked props object from a definitions table.
--- Each prop is assigned a unique bit position. Group masks are precomputed
--- as the OR of their member bits.
---
--- Example:
---   local props = DirtyProps.create({
---     x      = { val = 0,     groups = { 'layout' } },
---     y      = { val = 0,     groups = { 'layout' } },
---     width  = { val = 100,   groups = { 'layout', 'size' } },
---     height = { val = 40,    groups = { 'layout', 'size' } },
---     color  = { val = 0xffffff },
---   })
---
---   props:reset()
---   props.x = 50
---   props:sync()
---
---   props:is_dirty('x')          --> true
---   props:group_dirty('layout')  --> true
---   props:group_dirty('size')    --> false
function DirtyProps.create(definitions)
  local obj = {}
  for key, def in pairs(definitions) do
    define(obj, key, def)
  end
  return obj
end

return DirtyProps