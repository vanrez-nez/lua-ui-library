local TextFormatter = {}

local function sort_by_time(rows)
  table.sort(rows, function(left, right)
    if left.total_time == right.total_time then
      return left.key < right.key
    end

    return left.total_time > right.total_time
  end)
end

local function write_section(handle, title, rows)
  if #rows == 0 then
    return
  end

  sort_by_time(rows)

  handle:write('\n')
  handle:write(title)
  handle:write('\n')
  handle:write(string.format(
    '%10s    %14s    %14s    %14s    %14s    %14s    %14s    %s\n',
    'calls',
    'total_ms',
    'total_avg_ms',
    'self_us',
    'self_avg_us',
    'mem_net_kb',
    'mem_self_kb',
    'key'
  ))

  for _, row in ipairs(rows) do
    local total_ms = row.total_time * 1000
    local total_avg_ms = row.calls > 0 and (total_ms / row.calls) or 0
    local self_us = row.self_time * 1000000
    local self_avg_us = row.calls > 0 and (self_us / row.calls) or 0

    handle:write(string.format(
      '%10d    %14.3f    %14.6f    %14.3f    %14.3f    %+14.3f    %+14.3f    %s\n',
      row.calls,
      total_ms,
      total_avg_ms,
      self_us,
      self_avg_us,
      row.memory_net_kb,
      row.memory_self_net_kb,
      row.key
    ))
  end
end

function TextFormatter.write(handle, report, context)
  context = context or {}

  handle:write('profiler report\n')
  handle:write(string.format('seconds: %.6f\n', report.elapsed_seconds or 0))
  handle:write(string.format('output: %s\n', tostring(context.output or 'stdout')))
  handle:write(string.format(
    'features: calls=%s time=%s memory=%s zones=%s\n',
    tostring(report.features.calls),
    tostring(report.features.time),
    tostring(report.features.memory),
    tostring(report.features.zones)
  ))

  write_section(handle, 'files', report.counters:rows('file'))
  write_section(handle, 'functions', report.counters:rows('function'))
  write_section(handle, 'zones', report.counters:rows('zone'))
end

return TextFormatter
