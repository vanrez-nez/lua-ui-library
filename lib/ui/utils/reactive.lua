local Proxy = require('lib.ui.utils.proxy')

local Reactive = {}
Reactive.__index = Reactive

function Reactive:define(prop_defs)
  local instance = self._instance
  for key, def in pairs(prop_defs) do
    Proxy.declare(instance, key, { default = def.default })
    if def.get then
      Proxy.on_read(instance, key, def.get)
    end
  end
end

function Reactive:watch(key, fn)
  Proxy.on_change(self._instance, key, fn)
end

function Reactive:unwatch(key, fn)
  Proxy.off_change(self._instance, key, fn)
end

function Reactive:raw_get(key)
  return Proxy.raw_get(self._instance, key)
end

function Reactive:raw_set(key, value)
  Proxy.raw_set(self._instance, key, value)
end

return setmetatable(Reactive, {
  __call = function(cls, instance)
    return setmetatable({ _instance = instance }, cls)
  end,
})
