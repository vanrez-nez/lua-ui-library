--- DirtyProps (sync strategy) — bitwise per-frame property change tracking
--
-- sync_dirty_props() builds a single dirty_mask integer via bitwise OR.
-- All queries are O(1) band operations — no loops, no table lookups.
--
-- Hard limit: 31 props per object (LuaJIT signed 32-bit integers).
--
-- Two usage modes:
--
-- 1. Standalone:
--      local props = DirtyProps.create({
--        x     = { val = 0,       groups = { 'layout' } },
--        y     = { val = 0,       groups = { 'layout' } },
--        color = { val = 0xff0000 },
--      })
--      props:reset_dirty_props()
--      props.x = 10
--      props:sync_dirty_props()
--      props:is_dirty('x')          --> true
--      props:group_dirty('layout')  --> true
--
-- 2. cls.lua mixin:
--      local Node = Object:extends('Node')
--      Node:implements(DirtyProps)
--
--      function Node:constructor()
--        DirtyProps.init(self, {
--          x = { val = 0, groups = { 'layout' } },
--          y = { val = 0, groups = { 'layout' } },
--        })
--        self:reset_dirty_props()
--      end
--
--      function Node:update()
--        self:sync_dirty_props()
--        if self:group_dirty('layout') then self:reflow() end
--        self:reset_dirty_props()
--      end
--
--      node.x = 50  -- plain field write, no metamethod

local bit = require('bit')
local band = bit.band
local bor = bit.bor
local lshift = bit.lshift

local DirtyProps = {}
DirtyProps.__index = DirtyProps

local ACCESSOR = {}

local function get_state(obj)
  return rawget(obj, ACCESSOR)
end

local function ensure_state(obj)
  local s = rawget(obj, ACCESSOR)
  if not s then
    s = {
      props = {},
      group_masks = {},
      properties = {},
      dirty_mask = 0,
      bit_count = 0,
    }
    rawset(obj, ACCESSOR, s)
  end
  return s
end

local function define(obj, key, def)
  local state = ensure_state(obj)
  local groups = def.groups or {}
  assert(state.bit_count < 31, 'DirtyProps: max 31 props per object')
  local b = lshift(1, state.bit_count)
  state.bit_count = state.bit_count + 1
  rawset(obj, key, def.val)
  state.props[key] = { b, def.val }
  state.properties[#state.properties + 1] = key
  for _, g in ipairs(groups) do
    state.group_masks[g] = bor(state.group_masks[g] or 0, b)
  end
end

function DirtyProps:sync_dirty_props()
  local state = get_state(self)
  local props = state.props
  local properties = state.properties
  local mask = 0
  for i = 1, #properties do
    local key = properties[i]
    local p = props[key]
    local cur = rawget(self, key)
    if cur ~= p[2] then
      p[2] = cur
      mask = bor(mask, p[1])
    end
  end
  state.dirty_mask = mask
end

function DirtyProps:reset_dirty_props()
  local state = get_state(self)
  local props = state.props
  for _, key in ipairs(state.properties) do
    props[key][2] = rawget(self, key)
  end
  state.dirty_mask = 0
  return self
end

function DirtyProps:mark_dirty(...)
  local state = get_state(self)
  local gm = state.group_masks
  local mask = state.dirty_mask
  for i = 1, select('#', ...) do
    local m = gm[select(i, ...)]
    if m then mask = bor(mask, m) end
  end
  state.dirty_mask = mask
  return self
end

--- @param key string
--- @return boolean
function DirtyProps:is_dirty(key)
  local s = get_state(self)
  return band(s.dirty_mask, s.props[key][1]) ~= 0
end

--- OR: true if any of the given props are dirty.
function DirtyProps:any_dirty(...)
  local s = get_state(self)
  local props = s.props
  local mask = s.dirty_mask
  for i = 1, select('#', ...) do
    if band(mask, props[select(i, ...)][1]) ~= 0 then return true end
  end
  return false
end

--- AND: true if all of the given props are dirty.
function DirtyProps:all_dirty(...)
  local s = get_state(self)
  local props = s.props
  local mask = s.dirty_mask
  for i = 1, select('#', ...) do
    if band(mask, props[select(i, ...)][1]) == 0 then return false end
  end
  return true
end

--- @param name string
--- @return boolean
function DirtyProps:group_dirty(name)
  local s = get_state(self)
  local m = s.group_masks[name]
  return m ~= nil and band(s.dirty_mask, m) ~= 0
end

--- OR: true if any of the given groups are dirty.
function DirtyProps:group_any_dirty(...)
  local s = get_state(self)
  local gm = s.group_masks
  local mask = s.dirty_mask
  for i = 1, select('#', ...) do
    local m = gm[select(i, ...)]
    if m and band(mask, m) ~= 0 then return true end
  end
  return false
end

--- AND: true if all of the given groups are dirty.
function DirtyProps:group_all_dirty(...)
  local s = get_state(self)
  local gm = s.group_masks
  local mask = s.dirty_mask
  for i = 1, select('#', ...) do
    local m = gm[select(i, ...)]
    if not m or band(mask, m) == 0 then return false end
  end
  return true
end

--- Returns a copy of the dirty props map: { [key] = bool }.
function DirtyProps:get_dirty_props()
  local s = get_state(self)
  local props = s.props
  local mask = s.dirty_mask
  local result = {}
  for _, key in ipairs(s.properties) do
    result[key] = band(mask, props[key][1]) ~= 0
  end
  return result
end

--- Returns a copy of the dirty groups map: { [group] = bool }.
function DirtyProps:get_dirty_groups()
  local s = get_state(self)
  local mask = s.dirty_mask
  local result = {}
  for name, m in pairs(s.group_masks) do
    result[name] = band(mask, m) ~= 0
  end
  return result
end

--- Standalone mode: returns a self-contained tracked object.
function DirtyProps.create(definitions)
  local obj = setmetatable({}, DirtyProps)
  for key, def in pairs(definitions) do
    define(obj, key, def)
  end
  return obj
end

--- cls.lua mixin mode: defines props on an existing instance.
--- Does NOT touch the metatable. Call once in constructor, then self:reset_dirty_props().
function DirtyProps.init(obj, definitions)
  for key, def in pairs(definitions) do
    define(obj, key, def)
  end
end

return DirtyProps