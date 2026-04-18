--
-- cls.lua
-- Based on rxi/classic — MIT License
-- Refactored for correctness, predictability, and minimal overhead
--

local Object = {}
Object.__index = Object
Object.__name  = "Object"

-- Full Lua metamethod set. Copied explicitly to each subclass because
-- Lua resolves metamethods directly in the metatable, not through __index.
local METAMETHODS = {
  "__add", "__sub", "__mul", "__div", "__mod", "__pow",
  "__unm", "__idiv",
  "__band", "__bor", "__bxor", "__bnot", "__shl", "__shr",
  "__concat", "__len",
  "__eq", "__lt", "__le",
  "__call", "__tostring", "__gc", "__close",
  "__index", "__newindex",
  "is", "derivedFrom", "instanceOf",
}


-- Default no-op constructor. Override in subclasses.
function Object.constructor() end


-- Default no-op destroy hook. Override in subclasses to release resources.
-- Called once by destroy() before the dead proxy is installed.
function Object.on_destroy() end


-- Creates a named subclass. name is optional but recommended for debugging.
function Object:extends(name)
  local cls      = {}
  cls.__name     = name or "?"
  cls.super      = self

  for _, mm in ipairs(METAMETHODS) do
    local v = self[mm]
    if v ~= nil then cls[mm] = v end
  end

  if type(cls.__index) ~= 'function' then
    cls.__index = cls
  end

  setmetatable(cls, self)
  return cls
end


-- Copies own methods from one or more mixin tables into this class.
-- Shallow only: methods inherited by the mixin are not included.
-- Does not overwrite methods already defined on self.
function Object:implements(...)
  for _, mixin in ipairs({...}) do
    for k, v in pairs(mixin) do
      if type(v) == "function" and rawget(self, k) == nil then
        rawset(self, k, v)
      end
    end
  end
end


-- Marks the instance as destroyed and replaces its metatable with a dead
-- proxy that errors on any further access. Idempotent: safe to call twice.
-- Calls on_destroy() before installing the dead proxy, giving subclasses
-- a chance to release resources, unregister watchers, etc.
function Object:destroy()
  if rawget(self, '_destroyed') then return end
  rawset(self, '_destroyed', true)

  if type(self.on_destroy) == 'function' then
    self:on_destroy()
  end

  -- Capture name before the metatable swap makes it inaccessible normally.
  local name = tostring(rawget(self, '__name') or 'Object')

  setmetatable(self, {
    __index = function(_, k)
      -- Allow internal liveness checks to pass through without erroring.
      if k == '_destroyed' then return true end
      error(('attempt to access "%s" on destroyed %s'):format(tostring(k), name), 2)
    end,
    __newindex = function(_, k, _)
      error(('attempt to write "%s" on destroyed %s'):format(tostring(k), name), 2)
    end,
    __tostring = function()
      return ('destroyed:%s'):format(name)
    end,
  })
end


-- Returns true if obj has been destroyed.
-- Safe to call on any value including nil — never errors.
function Object.is_destroyed(obj)
  return type(obj) == 'table' and rawget(obj, '_destroyed') == true
end


-- Returns true if this object was instantiated directly from T.
function Object:instanceOf(T)
  return getmetatable(self) == T
end


-- Returns true if T appears anywhere in this object's prototype chain.
function Object:derivedFrom(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then return true end
    mt = getmetatable(mt)
  end
  return false
end


-- Returns true if obj is an instance of T (where T is a class or class name).
-- Handles nil or non-table objects gracefully.
function Object.is(obj, T)
  if type(obj) ~= "table" then
    return false
  end

  if type(T) == "string" then
    local mt = getmetatable(obj)
    while mt do
      if mt.__name == T then return true end
      mt = getmetatable(mt)
    end
    return false
  end

  if type(T) == "table" and type(obj.derivedFrom) == "function" then
    return obj:derivedFrom(T)
  end

  return false
end


-- Returns the class name. Resolves correctly for both instances and classes.
function Object:__tostring()
  return self.__name or "Object"
end


-- Allocates a new instance and calls its constructor.
function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:constructor(...)
  return obj
end


return Object
