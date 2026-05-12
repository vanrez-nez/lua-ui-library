local Memoize = {}

local NIL = {}

local function make1(fn)
  local cache = {}
  return function(a)
    local key = a
    if key == nil then key = NIL end
    local r = cache[key]
    if r == nil then
      r = fn(a)
      if r == nil then
        cache[key] = NIL
      else
        cache[key] = r
      end
    end
    if r == NIL then return nil end
    return r
  end
end

local function make2(fn)
  local cache = {}
  return function(a, b)
    local ka = a; if ka == nil then ka = NIL end
    local kb = b; if kb == nil then kb = NIL end
    local sub = cache[ka]
    if not sub then
      sub = {}
      cache[ka] = sub
    end
    local r = sub[kb]
    if r == nil then
      r = fn(a, b)
      if r == nil then
        sub[kb] = NIL
      else
        sub[kb] = r
      end
    end
    if r == NIL then return nil end
    return r
  end
end

local function make3(fn)
  local cache = {}
  return function(a, b, c)
    local ka = a; if ka == nil then ka = NIL end
    local kb = b; if kb == nil then kb = NIL end
    local kc = c; if kc == nil then kc = NIL end
    local s1 = cache[ka]
    if not s1 then s1 = {}; cache[ka] = s1 end
    local s2 = s1[kb]
    if not s2 then s2 = {}; s1[kb] = s2 end
    local r = s2[kc]
    if r == nil then
      r = fn(a, b, c)
      if r == nil then
        s2[kc] = NIL
      else
        s2[kc] = r
      end
    end
    if r == NIL then return nil end
    return r
  end
end

function Memoize.memoize(fn, n)
  n = n or 1
  if n == 1 then return make1(fn) end
  if n == 2 then return make2(fn) end
  if n == 3 then return make3(fn) end
  error("memoize: arity must be 1, 2, or 3, got " .. tostring(n), 2)
end

return Memoize