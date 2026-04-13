local Proxy = {}

local PDATA  = '_pdata'
local PHOOKS = '_phooks'
local PRFNS  = '_prfns'
local PCLASS = '_pclass'
local PKEYS  = '_pkeys'

local instance_queue = {}
local instance_queue_size = 0
local flushing = false

local function enqueue(instance, key)
  local pkeys = rawget(instance, PKEYS)
  -- If pkeys is empty, this instance is not currently in the queue
  if next(pkeys) == nil then
    instance_queue_size = instance_queue_size + 1
    instance_queue[instance_queue_size] = instance
  end
  pkeys[key] = true
end

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
  local pkeys    = {}
  local cls      = getmetatable(instance)

  rawset(instance, PDATA,  data)
  rawset(instance, PHOOKS, hooks)
  rawset(instance, PRFNS,  read_fns)
  rawset(instance, PKEYS,  pkeys)
  rawset(instance, PCLASS, cls)

  local proxy_mt = {
    __index = function(t, k)
      local rf = read_fns[k]
      if rf then return rf(data[k], k, t) end
      
      local v = data[k]
      if v ~= nil then return v end
      
      return cls[k]
    end,

    __newindex = function(t, k, v)
      local h = hooks[k]
      
      if data[k] ~= nil or h then
        local old = data[k]
        data[k] = v
        
        if h then
          if h.on_write then
            for i = 1, #h.on_write do h.on_write[i](v, k, t) end
          end
          
          -- if h.deferred then
          --   enqueue(t, k)
          -- else
            local oc = h.on_change
            if oc and v ~= old then
              for i = 1, #oc do oc[i](v, old, k, t) end
            end
          -- end
        end
      else
        rawset(t, k, v)
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
  local h = get_or_create_hook(rawget(instance, PHOOKS), key)
  if opts and opts.deferred then h.deferred = true end
  
  local data = rawget(instance, PDATA)
  if opts and opts.default ~= nil and data[key] == nil then
    data[key] = opts.default
  end
end

function Proxy.on_read(instance, key, fn)
  install(instance)
  rawget(instance, PRFNS)[key] = fn
end

function Proxy.on_pre_write() end -- Mocked: user requested to not handle pre_write

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
  if data then data[key] = value else rawset(instance, key, value) end
end

function Proxy.raw_get(instance, key)
  local data = rawget(instance, PDATA)
  return (data and data[key]) or rawget(instance, key)
end

function Proxy.is_installed(instance)
  return rawget(instance, PDATA) ~= nil
end

function Proxy.read(instance, key)
  local rf = rawget(instance, PRFNS)
  rf = rf and rf[key]
  
  local data = rawget(instance, PDATA)
  local v = data and data[key]
  if v == nil then v = rawget(instance, key) end
  
  if rf then return true, rf(v, key, instance) end
  if v ~= nil then return true, v end
  return false, nil
end

function Proxy.write(instance, key, value)
  local hooks = rawget(instance, PHOOKS)
  local h = hooks and hooks[key]
  
  local data = rawget(instance, PDATA)
  if data == nil and h == nil then
    rawset(instance, key, value)
    return true
  end

  local old = Proxy.raw_get(instance, key)
  if data then data[key] = value else rawset(instance, key, value) end
  
  if h then
    if h.on_write then
      for i = 1, #h.on_write do h.on_write[i](value, key, instance) end
    end
    
    -- if h.deferred then
    --   enqueue(instance, key)
    -- else
      local oc = h.on_change
      if oc and value ~= old then
        for i = 1, #oc do oc[i](value, old, key, instance) end
      end
    -- end
  end
  
  return true
end

function Proxy.flush(handler)
  if flushing then return end
  flushing = true
  
  for i = 1, instance_queue_size do
    local inst = instance_queue[i]
    local pkeys = rawget(inst, PKEYS)
    
    handler(inst, pkeys)
    
    -- Clear pkeys for next frame reuse
    for k in pairs(pkeys) do
      pkeys[k] = nil
    end
    -- Clear queue reference
    instance_queue[i] = nil
  end
  
  instance_queue_size = 0
  flushing = false
end

return Proxy