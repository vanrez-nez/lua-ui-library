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
}


-- Default no-op constructor. Override in subclasses.
function Object:constructor() end


-- Creates a named subclass. name is optional but recommended for debugging.
function Object:extends(name)
  local cls      = {}
  cls.__index    = cls
  cls.__name     = name or "?"
  cls.super      = self

  for _, mm in ipairs(METAMETHODS) do
    local v = rawget(self, mm)
    if v ~= nil then cls[mm] = v end
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