local Config = require('profiler.config')
local Counters = require('profiler.counters')
local Reporter = require('profiler.reporter')
local Utils = require('profiler.utils')
local SourceFilter = require('profiler.source_filter')
local Token = require('profiler.token')
local Trace = require('profiler.trace')

local Profiler = {}

local state = {
  active = false,
  config = nil,
  counters = nil,
  output = nil,
  last_output = nil,
  started_at = nil,
  trace = nil,
  stack = nil,
  zone_stack = nil,
  pending = nil,
  capture_frames = nil,
  captured_frames = 0
}

local function current_zone()
  if state.zone_stack == nil or #state.zone_stack == 0 then
    return nil
  end

  return state.zone_stack[#state.zone_stack].name
end

local function record_frame(frame, elapsed, memory_delta_kb, self_time, self_memory_delta_kb)
  local values = {
    total_time = state.config.features.time and elapsed or 0,
    self_time = state.config.features.time and self_time or 0,
    memory_net_kb = state.config.features.memory and memory_delta_kb or 0,
    memory_self_net_kb = state.config.features.memory and self_memory_delta_kb or 0
  }

  state.counters:add_call('file', frame.source, {
    file = frame.source,
    zone = frame.zone
  }, values)

  state.counters:add_call('function', Utils.function_key(frame.source, frame.line, frame.name), {
    file = frame.source,
    line = frame.line,
    name = frame.name,
    zone = frame.zone
  }, values)
end

local function push_frame(info)
  local source = Utils.normalize_path(info.source)
  local line = info.linedefined or 0
  local name = info.name or '<anonymous>'
  local zone = current_zone()
  local trace_index = nil

  if state.trace:enabled(state.config) then
    trace_index = state.trace:frame_index(name, source, line)
    state.trace:push_event('O', trace_index)
  end

  local timing = Token.open()
  timing.source = source
  timing.line = line
  timing.name = name
  timing.zone = zone
  timing.trace_index = trace_index
  state.stack[#state.stack + 1] = timing
end

local function pop_frame(info)
  local source = Utils.normalize_path(info.source)
  local line = info.linedefined or 0

  for index = #state.stack, 1, -1 do
    local frame = state.stack[index]
    if frame.source == source and frame.line == line then
      local elapsed, memory_delta_kb, self_time, self_memory_delta_kb = Token.close(frame)
      table.remove(state.stack, index)
      state.trace:push_event('C', frame.trace_index)
      record_frame(frame, elapsed, memory_delta_kb, self_time, self_memory_delta_kb)
      Token.propagate(state.stack[#state.stack], elapsed, memory_delta_kb)
      return
    end
  end
end

local function on_hook(event)
  if not state.active then
    return
  end

  local info = debug.getinfo(2, 'nS')
  if info == nil or info.what == 'C' or not SourceFilter.should_profile_source(info.source, state.config) then
    return
  end

  if event == 'call' or event == 'tail call' then
    if state.config.features.calls or state.config.features.time or
      state.config.features.memory or state.trace:enabled(state.config)
    then
      push_frame(info)
    end
    return
  end

  if event == 'return' or event == 'tail return' then
    pop_frame(info)
  end
end

local function stop_hook()
  debug.sethook()
end

local function start_hook()
  if debug == nil or type(debug.sethook) ~= 'function' then
    return nil, 'debug.sethook is unavailable'
  end

  debug.sethook(on_hook, 'cr')
  return true
end

local function start_now(config, output)
  local ok, err = start_hook()
  if not ok then
    return nil, err
  end

  state.active = true
  state.config = config
  state.counters = Counters.new()
  state.output = output or config.output or Config.default_output(config)
  state.last_output = state.output
  state.started_at = Utils.now_seconds()
  state.trace = Trace.new()
  state.stack = {}
  state.zone_stack = {}
  state.captured_frames = 0

  print(string.format('[profile] started output=%s', state.output))
  return state.output
end

local function install_frame_tick()
  if love == nil or love.update == nil then
    return
  end

  local original = love.update
  love.update = function(...)
    Profiler.frame()
    original(...)
  end
end

local function schedule_start(config)
  if config.profile_frames ~= nil and config.profile_frames <= 0 then
    return nil
  end

  local output = config.output or Config.default_output(config)
  state.pending = {
    config = config,
    output = output,
    start_at = Utils.now_seconds() + (config.delay_seconds or 0),
    delay_seconds = config.delay_seconds or 0,
    profile_frames = config.profile_frames
  }
  state.last_output = output

  install_frame_tick()

  print(string.format(
    '[profile] scheduled delay_seconds=%.3f profile_frames=%d output=%s',
    state.pending.delay_seconds,
    state.pending.profile_frames,
    output
  ))

  return output
end

function Profiler.is_available()
  return debug ~= nil and type(debug.sethook) == 'function'
end

function Profiler.is_active()
  return state.active
end

function Profiler.is_pending()
  return state.pending ~= nil
end

function Profiler.default_output(opts)
  return Config.default_output(opts)
end

function Profiler.get_output()
  return state.output
end

function Profiler.get_last_output()
  return state.last_output
end

function Profiler.start(opts)
  if state.active then
    return state.output
  end

  local config = Config.normalize(opts)
  if not config.enabled then
    return nil
  end

  if config.profile_frames ~= nil then
    return schedule_start(config)
  end

  return start_now(config)
end

function Profiler.start_from_env(opts)
  local config = Config.from_env(opts)
  if not config.enabled then
    return nil
  end

  return Profiler.start(config)
end

function Profiler.stop()
  if state.pending ~= nil and not state.active then
    state.pending = nil
    state.capture_frames = nil
    state.captured_frames = 0
    return state.last_output
  end

  if not state.active then
    return state.last_output
  end

  local output = state.output
  local elapsed_seconds = Utils.now_seconds() - (state.started_at or Utils.now_seconds())

  stop_hook()

  state.stack = {}
  state.zone_stack = {}

  Reporter.write(output, {
    elapsed_seconds = elapsed_seconds,
    format = state.config.format,
    features = state.config.features,
    counters = state.counters,
    trace = state.trace:snapshot()
  })

  state.active = false
  state.config = nil
  state.counters = nil
  state.output = nil
  state.started_at = nil
  state.trace = nil
  state.stack = nil
  state.zone_stack = nil
  state.capture_frames = nil
  state.captured_frames = 0

  print(string.format('[profile] stopped output=%s', output or 'nil'))
  return output
end

function Profiler.frame()
  if state.active and state.capture_frames ~= nil then
    state.captured_frames = state.captured_frames + 1

    if state.captured_frames >= state.capture_frames then
      Profiler.stop()

      if love ~= nil and love.event ~= nil and love.event.quit ~= nil then
        love.event.quit()
      end

      return state.last_output
    end
  end

  local pending = state.pending
  if pending == nil then
    return state.output
  end

  if Utils.now_seconds() < pending.start_at then
    return nil
  end

  state.pending = nil
  state.capture_frames = pending.profile_frames
  state.captured_frames = 0

  return start_now(pending.config, pending.output)
end

function Profiler.toggle(opts)
  if state.active or state.pending ~= nil then
    return Profiler.stop()
  end

  return Profiler.start(opts)
end

function Profiler.push_zone(name)
  if not state.active or not state.config.features.zones or name == nil then
    return nil
  end

  local token = Token.open()
  token.name = tostring(name)
  token.trace_index = nil

  if state.trace:enabled(state.config) then
    token.trace_index = state.trace:frame_index('[zone] ' .. token.name, nil, nil)
    state.trace:push_event('O', token.trace_index)
  end

  state.zone_stack[#state.zone_stack + 1] = token
  return token
end

function Profiler.pop_zone(token)
  if not state.active or token == nil then
    return nil
  end

  local stack = state.zone_stack
  if stack == nil or #stack == 0 then
    return nil
  end

  local top = stack[#stack]
  stack[#stack] = nil

  if top ~= token then
    token = top
  end

  local elapsed, memory_delta_kb, self_time, self_memory_delta_kb = Token.close(token)

  state.trace:push_event('C', token.trace_index)

  state.counters:add_call('zone', token.name, {
    zone = token.name
  }, {
    total_time = state.config.features.time and elapsed or 0,
    self_time = state.config.features.time and self_time or 0,
    memory_net_kb = state.config.features.memory and memory_delta_kb or 0,
    memory_self_net_kb = state.config.features.memory and self_memory_delta_kb or 0
  })

  Token.propagate(stack[#stack], elapsed, memory_delta_kb)

  return elapsed
end

function Profiler.measure(name, fn, ...)
  local token = Profiler.push_zone(name)
  local results = Utils.pack(pcall(fn, ...))
  Profiler.pop_zone(token)

  if not results[1] then
    error(results[2], 0)
  end

  return unpack(results, 2, results.n)
end

function Profiler.status_text()
  if state.active then
    if state.capture_frames ~= nil then
      return string.format(
        'profile on frame %d/%d -> %s',
        state.captured_frames,
        state.capture_frames,
        state.output or '?'
      )
    end

    return string.format('profile on -> %s', state.output or '?')
  end

  if state.pending ~= nil then
    return string.format(
      'profile pending delay=%.2fs frames=%d -> %s',
      math.max(0, state.pending.start_at - Utils.now_seconds()),
      state.pending.profile_frames,
      state.pending.output or '?'
    )
  end

  if state.last_output ~= nil then
    return string.format('profile off -> last %s', state.last_output)
  end

  return 'profile off'
end

return Profiler
