local Utils = {}

function Utils.copy_array(values)
  if values == nil then
      return nil
  end
  local copy = {}
  for index = 1, #values do
      copy[index] = values[index]
  end
  return copy
end

function Utils.copy_table(values)
    if values == nil then
        return nil
    end
    local copy = {}
    for key, value in pairs(values) do
        copy[key] = value
    end
    return copy
end

function Utils.clone(obj, deep, _visited)
  local out = setmetatable({}, getmetatable(obj))
  if not deep then
    for k, v in pairs(obj) do out[k] = v end
    return out
  end

  _visited = _visited or {}
  if _visited[obj] then return _visited[obj] end
  _visited[obj] = out

  for k, v in pairs(obj) do
    local ck = type(k) == 'table' and Utils.clone(k, true, _visited) or k
    local cv = type(v) == 'table' and Utils.clone(v, true, _visited) or v
    out[ck] = cv
  end

  return out
end

function Utils.merge(target, source, deep, overwrite, _visited)
  if not deep then
    for k, v in pairs(source) do
      if overwrite or target[k] == nil then target[k] = v end
    end
    return target
  end

  _visited = _visited or {}
  if _visited[source] then return target end
  _visited[source] = true

  for k, v in pairs(source) do
    if type(v) == 'table' then
      if type(target[k]) == 'table' then
        Utils.merge(target[k], v, true, overwrite, _visited)
      elseif overwrite or target[k] == nil then
        target[k] = Utils.clone(v, true, _visited)
      end
    elseif overwrite or target[k] == nil then
      target[k] = v
    end
  end

  return target
end

function Utils.merge_tables(target, source)
    if source == nil then
        return target
    end
    for k, v in pairs(source) do
        target[k] = v
    end
    return target
end

return Utils
