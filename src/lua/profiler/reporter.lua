local Reporter = {}

local function ensure_parent_dir(path)
  local dir = path and path:match('^(.*)/[^/]+$') or nil
  if dir == nil or dir == '' then
    return
  end

  os.execute(string.format('mkdir -p %q', dir))
end

local function open_output(output)
  if type(output) ~= 'string' then
    return output or io.stdout, false
  end

  ensure_parent_dir(output)

  local handle, err = io.open(output, 'w')
  if handle == nil then
    error(err or ('unable to open profiler output: ' .. output), 2)
  end

  return handle, true
end

local function load_formatter(format)
  format = format or 'text'

  local module_name = 'profiler.formatters.' .. format
  local formatter = require(module_name)
  if type(formatter.write) ~= 'function' then
    error('profiler formatter must expose write(handle, report, context): ' .. module_name, 3)
  end

  return formatter
end

function Reporter.write(output, report)
  local handle, should_close = open_output(output)
  local formatter = load_formatter(report.format)

  formatter.write(handle, report, {
    output = output
  })

  if should_close then
    handle:close()
  end
end

return Reporter
