local Proxy = {}

local PDATA  = '_pdata'
local PHOOKS = '_phooks'
local PCLASS = '_pclass'
local PRFNS  = '_prfns'

local function get_or_create_hook(hooks, key)
  local h = hooks[key]
  if not h then h = {}; hooks[key] = h end
  return h
end

local function install(instance)
  if rawget(instance, PDATA) then return end

  local data     = {}
  local hooks    = {}
  local read_fns = {}
  local cls      = getmetatable(instance)

  rawset(instance, PDATA,  data)
  rawset(instance, PHOOKS, hooks)
  rawset(instance, PRFNS,  read_fns)
  rawset(instance, PCLASS, cls)

  local proxy_mt = {
    __index = function(t, k)
      local rf = read_fns[k]
      if rf ~= nil then
        local v = data[k]
        if rf then return rf(v, k, t) end
        return v
      end
      return cls[k]
    end,

    __newindex = function(t, k, v)
      local h = hooks[k]
      if not h then rawset(t, k, v); return end

      local old = data[k]

      local pre = h.pre_write
      if pre then
        for i = 1, #pre do v = pre[i](k, v, t) or v end
      end

      data[k] = v

      local ow = h.on_write
      if ow then
        for i = 1, #ow do ow[i](v, k, t) end
      end

      local oc = h.on_change
      if oc and v ~= old then
        for i = 1, #oc do oc[i](v, old, k, t) end
      end
    end,
  }

  if cls ~= nil then
    setmetatable(proxy_mt, cls)
  end

  setmetatable(instance, proxy_mt)
end

function Proxy.declare(instance, key, opts)
  install(instance)
  get_or_create_hook(rawget(instance, PHOOKS), key)
  local read_fns = rawget(instance, PRFNS)
  if read_fns[key] == nil then read_fns[key] = false end
  if opts and opts.default ~= nil then
    local data = rawget(instance, PDATA)
    if data[key] == nil then instance[key] = opts.default end
  end
end

function Proxy.on_read(instance, key, fn)
  install(instance)
  get_or_create_hook(rawget(instance, PHOOKS), key)
  rawget(instance, PRFNS)[key] = fn
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
  local read_fns = rawget(instance, PRFNS)
  local rf = read_fns and read_fns[key]
  if rf == nil then return false, nil end
  local v = rawget(instance, PDATA)[key]
  if rf then return true, rf(v, key, instance) end
  return true, v
end

function Proxy.write(instance, key, value)
  local hooks = rawget(instance, PHOOKS)
  local h = hooks and hooks[key]
  if not h then return false end

  local data = rawget(instance, PDATA)
  local old  = data[key]
  local v    = value

  local pre = h.pre_write
  if pre then
    for i = 1, #pre do v = pre[i](key, v, instance) or v end
  end

  data[key] = v

  local ow = h.on_write
  if ow then
    for i = 1, #ow do ow[i](v, key, instance) end
  end

  local oc = h.on_change
  if oc and v ~= old then
    for i = 1, #oc do oc[i](v, old, key, instance) end
  end

  return true
end

return Proxy
