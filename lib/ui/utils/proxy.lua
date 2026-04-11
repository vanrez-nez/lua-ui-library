local Proxy = {}

local PDATA  = '_pdata'
local PHOOKS = '_phooks'
local PCLASS = '_pclass'

local function get_or_create_hook(hooks, key)
  local h = hooks[key]
  if not h then h = {}; hooks[key] = h end
  return h
end

local function read_declared(instance, key)
  local hooks = rawget(instance, PHOOKS)
  local h = hooks and hooks[key]
  if not h then
    return false, nil
  end

  local v = rawget(instance, PDATA)[key]
  if h.read then
    return true, h.read(v, key, instance)
  end

  return true, v
end

local function write_declared(instance, key, value)
  local hooks = rawget(instance, PHOOKS)
  local h = hooks and hooks[key]
  if not h then
    return false, value
  end

  local data = rawget(instance, PDATA)
  local old = data[key]
  local v = value

  local pre = h.pre_write
  if pre then
    for i = 1, #pre do
      v = pre[i](key, v, instance) or v
    end
  end

  data[key] = v

  local ow = h.on_write
  if ow then
    for i = 1, #ow do
      ow[i](v, key, instance)
    end
  end

  local oc = h.on_change
  if oc and v ~= old then
    for i = 1, #oc do
      oc[i](v, old, key, instance)
    end
  end

  return true, v
end

local function resolve_class_lookup(instance, key, cls)
  if cls == nil then
    return nil
  end

  local class_index = rawget(cls, '__index')
  if type(class_index) == 'function' and class_index ~= cls then
    local value = class_index(instance, key)
    if value ~= nil then
      return value
    end
  end

  local current = cls
  while current do
    local value = rawget(current, key)
    if value ~= nil then
      return value
    end
    current = rawget(current, 'super') or getmetatable(current)
  end

  return nil
end

local function install(instance)
  if rawget(instance, PDATA) then return end
  rawset(instance, PDATA,  {})
  rawset(instance, PHOOKS, {})
  rawset(instance, PCLASS, getmetatable(instance))

  local proxy_meta = {
    __index = function(t, k)
      local handled, value = read_declared(t, k)
      if handled then
        return value
      end
      local direct = rawget(t, k)
      if direct ~= nil then
        return direct
      end
      return resolve_class_lookup(t, k, rawget(t, PCLASS))
    end,

    __newindex = function(t, k, v)
      local handled = write_declared(t, k, v)
      if not handled then
        local cls = rawget(t, PCLASS)
        local class_newindex = cls and rawget(cls, '__newindex') or nil
        if type(class_newindex) == 'function' and class_newindex ~= cls then
          class_newindex(t, k, v)
        else
          rawset(t, k, v)
        end
      end
    end,
  }

  setmetatable(proxy_meta, rawget(instance, PCLASS))
  setmetatable(instance, proxy_meta)
end

function Proxy.declare(instance, key, opts)
  install(instance)
  get_or_create_hook(rawget(instance, PHOOKS), key)
  if opts and opts.default ~= nil then
    local data = rawget(instance, PDATA)
    if data[key] == nil then instance[key] = opts.default end
  end
end

function Proxy.on_read(instance, key, fn)
  install(instance)
  get_or_create_hook(rawget(instance, PHOOKS), key).read = fn
end

function Proxy.on_pre_write(instance, key, fn)
  install(instance)
  local h = get_or_create_hook(rawget(instance, PHOOKS), key)
  if not h.pre_write then h.pre_write = {} end
  table.insert(h.pre_write, fn)
end

function Proxy.on_write(instance, key, fn)
  install(instance)
  local h = get_or_create_hook(rawget(instance, PHOOKS), key)
  if not h.on_write then h.on_write = {} end
  table.insert(h.on_write, fn)
end

function Proxy.on_change(instance, key, fn)
  install(instance)
  local h = get_or_create_hook(rawget(instance, PHOOKS), key)
  if not h.on_change then h.on_change = {} end
  table.insert(h.on_change, fn)
end

function Proxy.off_change(instance, key, fn)
  local hooks = rawget(instance, PHOOKS)
  if not (hooks and hooks[key] and hooks[key].on_change) then return end
  local oc = hooks[key].on_change
  for i = #oc, 1, -1 do
    if oc[i] == fn then table.remove(oc, i) end
  end
end

function Proxy.raw_set(instance, key, value)
  local data = rawget(instance, PDATA)
  if data then data[key] = value end
end

function Proxy.raw_get(instance, key)
  local data = rawget(instance, PDATA)
  return data and data[key]
end

function Proxy.is_installed(instance)
  return rawget(instance, PDATA) ~= nil
end

function Proxy.read(instance, key)
  return read_declared(instance, key)
end

function Proxy.write(instance, key, value)
  return write_declared(instance, key, value)
end

return Proxy
