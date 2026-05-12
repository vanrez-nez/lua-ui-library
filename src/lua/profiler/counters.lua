local Counters = {}
Counters.__index = Counters

local function new_counter(kind, key, attrs)
  attrs = attrs or {}

  return {
    kind = kind,
    key = key,
    file = attrs.file,
    line = attrs.line,
    name = attrs.name,
    zone = attrs.zone,
    calls = 0,
    total_time = 0,
    self_time = 0,
    memory_net_kb = 0,
    memory_self_net_kb = 0,
    memory_alloc_kb = 0,
    memory_self_alloc_kb = 0,
    memory_free_kb = 0,
    memory_self_free_kb = 0,
    samples = 0
  }
end

function Counters.new()
  return setmetatable({
    order = {},
    by_key = {}
  }, Counters)
end

function Counters:get(kind, key, attrs)
  local scoped_key = kind .. ':' .. key
  local counter = self.by_key[scoped_key]

  if counter ~= nil then
    return counter
  end

  counter = new_counter(kind, key, attrs)
  self.by_key[scoped_key] = counter
  self.order[#self.order + 1] = counter
  return counter
end

function Counters:add_call(kind, key, attrs, values)
  values = values or {}

  local counter = self:get(kind, key, attrs)
  counter.calls = counter.calls + (values.calls or 1)
  counter.total_time = counter.total_time + (values.total_time or 0)
  counter.self_time = counter.self_time + (values.self_time or 0)
  counter.memory_net_kb = counter.memory_net_kb + (values.memory_net_kb or 0)
  counter.memory_self_net_kb = counter.memory_self_net_kb + (values.memory_self_net_kb or 0)

  local memory_net_kb = values.memory_net_kb or 0
  local memory_self_net_kb = values.memory_self_net_kb or 0
  if memory_net_kb >= 0 then
    counter.memory_alloc_kb = counter.memory_alloc_kb + memory_net_kb
  else
    counter.memory_free_kb = counter.memory_free_kb - memory_net_kb
  end

  if memory_self_net_kb >= 0 then
    counter.memory_self_alloc_kb = counter.memory_self_alloc_kb + memory_self_net_kb
  else
    counter.memory_self_free_kb = counter.memory_self_free_kb - memory_self_net_kb
  end

  counter.samples = counter.samples + (values.samples or 0)
  return counter
end

function Counters:rows(kind)
  local rows = {}

  for _, counter in ipairs(self.order) do
    if kind == nil or counter.kind == kind then
      rows[#rows + 1] = counter
    end
  end

  return rows
end

return Counters
