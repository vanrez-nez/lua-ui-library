local Utils = require('profiler.utils')

local Trace = {}
Trace.__index = Trace

function Trace.new()
  return setmetatable({
    started_at = Utils.now_seconds(),
    frames = {},
    frame_index_by_key = {},
    events = {}
  }, Trace)
end

function Trace:enabled(config)
  return config ~= nil and config.format == 'speedscope'
end

function Trace:frame_index(name, source, line)
  local key = Utils.function_key(source or '', line or 0, name)
  local index = self.frame_index_by_key[key]

  if index ~= nil then
    return index
  end

  index = #self.frames
  self.frame_index_by_key[key] = index
  self.frames[#self.frames + 1] = {
    name = name or '<anonymous>',
    file = source,
    line = line
  }
  return index
end

function Trace:push_event(type_name, index)
  if index == nil then return end
  local at = (Utils.now_seconds() - self.started_at) * 1000
  self.events[#self.events + 1] = {
    type = type_name,
    frame = index,
    at = at
  }
end

function Trace:snapshot()
  return {
    frames = self.frames,
    events = self.events
  }
end

return Trace
