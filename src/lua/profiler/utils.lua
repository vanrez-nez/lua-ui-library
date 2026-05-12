local Utils = {}

function Utils.now_seconds()
  if love ~= nil and love.timer ~= nil and love.timer.getTime ~= nil then
    return love.timer.getTime()
  end

  return os.clock()
end

function Utils.heap_kb()
  return collectgarbage('count')
end

function Utils.pack(...)
  return {
    n = select('#', ...),
    ...
  }
end

function Utils.normalize_path(path)
  if path == nil then
    return nil
  end

  path = tostring(path):gsub('\\', '/')
  if path:sub(1, 1) == '@' then
    path = path:sub(2)
  end

  while path:sub(1, 2) == './' do
    path = path:sub(3)
  end

  local root = os.getenv('LUA_UI_LIBRARY_ROOT') or os.getenv('PWD')
  if root ~= nil and root ~= '' then
    root = root:gsub('\\', '/')
    if path == root then
      path = ''
    elseif path:sub(1, #root + 1) == root .. '/' then
      path = path:sub(#root + 2)
    end
  end

  return path
end

function Utils.source_matches_target(source, target)
  source = Utils.normalize_path(source)
  target = Utils.normalize_path(target)

  if source == nil or target == nil or target == '' then
    return false
  end

  return source == target or source:sub(-#target) == target
end

function Utils.function_key(source, line, name)
  name = name or '<anonymous>'
  return string.format('%s:%d:%s', source, line or 0, name)
end

return Utils
