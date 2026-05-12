local SpeedscopeFormatter = {}

local function json_string(value)
  value = tostring(value or '')
  value = value:gsub('[%z\1-\31\\"]', function(char)
    if char == '"' then
      return '\\"'
    end
    if char == '\\' then
      return '\\\\'
    end
    if char == '\b' then
      return '\\b'
    end
    if char == '\f' then
      return '\\f'
    end
    if char == '\n' then
      return '\\n'
    end
    if char == '\r' then
      return '\\r'
    end
    if char == '\t' then
      return '\\t'
    end

    return string.format('\\u%04x', char:byte())
  end)

  return '"' .. value .. '"'
end

local function write_json_field(handle, name, value, comma)
  handle:write(string.format('        %s: %s', json_string(name), value))
  if comma then
    handle:write(',')
  end
  handle:write('\n')
end

local function write_frames(handle, frames)
  handle:write('    "frames": [\n')

  for index, frame in ipairs(frames or {}) do
    handle:write('      {\n')
    write_json_field(handle, 'name', json_string(frame.name), frame.file ~= nil or frame.line ~= nil)
    if frame.file ~= nil then
      write_json_field(handle, 'file', json_string(frame.file), frame.line ~= nil)
    end
    if frame.line ~= nil then
      write_json_field(handle, 'line', tostring(frame.line), false)
    end
    handle:write('      }')
    if index < #frames then
      handle:write(',')
    end
    handle:write('\n')
  end

  handle:write('    ]\n')
end

local function write_events(handle, events)
  handle:write('      "events": [\n')

  for index, event in ipairs(events or {}) do
    handle:write(string.format(
      '        {"type":%s,"at":%.6f,"frame":%d}',
      json_string(event.type),
      event.at or 0,
      event.frame or 0
    ))
    if index < #events then
      handle:write(',')
    end
    handle:write('\n')
  end

  handle:write('      ]\n')
end

function SpeedscopeFormatter.write(handle, report)
  local trace = report.trace or {}
  local elapsed_ms = (report.elapsed_seconds or 0) * 1000

  handle:write('{\n')
  handle:write('  "$schema": "https://www.speedscope.app/file-format-schema.json",\n')
  handle:write('  "name": "lua-ui-library profile",\n')
  handle:write('  "exporter": "lua-ui-library profiler",\n')
  handle:write('  "activeProfileIndex": 0,\n')
  handle:write('  "shared": {\n')
  write_frames(handle, trace.frames or {})
  handle:write('  },\n')
  handle:write('  "profiles": [\n')
  handle:write('    {\n')
  handle:write('      "type": "evented",\n')
  handle:write('      "name": "Lua debug hook",\n')
  handle:write('      "unit": "milliseconds",\n')
  handle:write('      "startValue": 0,\n')
  handle:write(string.format('      "endValue": %.6f,\n', elapsed_ms))
  write_events(handle, trace.events or {})
  handle:write('    }\n')
  handle:write('  ]\n')
  handle:write('}\n')
end

return SpeedscopeFormatter
