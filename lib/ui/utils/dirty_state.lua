local DirtyState = {}
DirtyState.__index = DirtyState

function DirtyState:mark(...)
  local t = self._flags
  for i = 1, select('#', ...) do
    t[select(i, ...)] = true
  end
end

function DirtyState:is_dirty(flag)
  return self._flags[flag] == true
end

function DirtyState:clear(...)
  local t = self._flags
  for i = 1, select('#', ...) do
    t[select(i, ...)] = false
  end
end

function DirtyState:clear_all()
  local t = self._flags
  for k in pairs(t) do t[k] = false end
end

function DirtyState:is_any(...)
  local t = self._flags
  if select('#', ...) == 0 then
    for _, v in pairs(t) do
      if v then return true end
    end
    return false
  end
  for i = 1, select('#', ...) do
    if t[select(i, ...)] then return true end
  end
  return false
end

function DirtyState:is_all(...)
  local t = self._flags
  if select('#', ...) == 0 then
    for _, v in pairs(t) do
      if not v then return false end
    end
    return true
  end
  for i = 1, select('#', ...) do
    if not t[select(i, ...)] then return false end
  end
  return true
end

return setmetatable(DirtyState, {
  __call = function(cls, flags)
    local t = {}
    for _, name in ipairs(flags) do t[name] = false end
    return setmetatable({ _flags = t }, cls)
  end,
})
