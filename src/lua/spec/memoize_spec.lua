local luaunit = require('luaunit')
local Memoize = require('lib.ui.utils.memoize')

local TestMemoize = {}

local function pack(...)
  return {
    n = select('#', ...),
    ...
  }
end

-- Inline memoize (removed from production module, dead code outside specs)

local NIL_SENTINEL = {}
local RESULT_KEY = {}

local function walk(cache, ...)
  local n = select('#', ...)
  local node = cache
  for i = 1, n do
    local k = select(i, ...)
    if k == nil then
      k = NIL_SENTINEL
    end
    local child = node[k]
    if not child then
      child = {}
      node[k] = child
    end
    node = child
  end
  return node
end

local function memoize(fn)
  local cache = {}
  return function(...)
    local node = walk(cache, ...)
    local r = node[RESULT_KEY]
    if r == nil then
      r = fn(...)
      if r == nil then
        node[RESULT_KEY] = NIL_SENTINEL
      else
        node[RESULT_KEY] = r
      end
    end
    if r == NIL_SENTINEL then
      return nil
    end
    return r
  end
end

local function memoize_multi(fn)
  local cache = {}
  local pack_fn = function(...) return { n = select('#', ...), ... } end
  return function(...)
    local node = walk(cache, ...)
    if not node[RESULT_KEY] then
      node[RESULT_KEY] = pack_fn(fn(...))
    end
    return unpack(node[RESULT_KEY], 1, node[RESULT_KEY].n)
  end
end

function TestMemoize.test_memoize_caches_single_return_for_same_args()
  local calls = 0
  local memoized = memoize(function(a, b)
    calls = calls + 1
    return a .. ':' .. b .. ':' .. calls
  end)

  luaunit.assertEquals(memoized('left', 'right'), 'left:right:1')
  luaunit.assertEquals(memoized('left', 'right'), 'left:right:1')
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize_recomputes_for_different_args()
  local calls = 0
  local memoized = memoize(function(value)
    calls = calls + 1
    return value * 10 + calls
  end)

  luaunit.assertEquals(memoized(1), 11)
  luaunit.assertEquals(memoized(2), 22)
  luaunit.assertEquals(memoized(1), 11)
  luaunit.assertEquals(calls, 2)
end

function TestMemoize.test_memoize_treats_nil_args_as_cache_keys()
  local calls = 0
  local memoized = memoize(function(a, b)
    calls = calls + 1
    return tostring(a) .. ':' .. tostring(b) .. ':' .. calls
  end)

  luaunit.assertEquals(memoized(nil, 'x'), 'nil:x:1')
  luaunit.assertEquals(memoized(nil, 'x'), 'nil:x:1')
  luaunit.assertEquals(memoized('x', nil), 'x:nil:2')
  luaunit.assertEquals(memoized('x', nil), 'x:nil:2')
  luaunit.assertEquals(calls, 2)
end

function TestMemoize.test_memoize_caches_nil_return()
  local calls = 0
  local memoized = memoize(function()
    calls = calls + 1
    return nil
  end)

  luaunit.assertNil(memoized())
  luaunit.assertNil(memoized())
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize_caches_false_return()
  local calls = 0
  local memoized = memoize(function()
    calls = calls + 1
    return false
  end)

  luaunit.assertFalse(memoized())
  luaunit.assertFalse(memoized())
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize_handles_zero_arg_cache_entry()
  local calls = 0
  local memoized = memoize(function()
    calls = calls + 1
    return calls
  end)

  luaunit.assertEquals(memoized(), 1)
  luaunit.assertEquals(memoized(), 1)
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize_multi_caches_multiple_returns()
  local calls = 0
  local memoized = memoize_multi(function(value)
    calls = calls + 1
    return value, value + calls
  end)

  local first = pack(memoized(3))
  local second = pack(memoized(3))

  luaunit.assertEquals(first, {
    n = 2,
    3,
    4
  })
  luaunit.assertEquals(second, {
    n = 2,
    3,
    4
  })
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize_multi_preserves_nil_holes_and_count()
  local calls = 0
  local memoized = memoize_multi(function()
    calls = calls + 1
    return nil, 'middle', nil, calls
  end)

  local first = pack(memoized())
  local second = pack(memoized())

  luaunit.assertEquals(first.n, 4)
  luaunit.assertNil(first[1])
  luaunit.assertEquals(first[2], 'middle')
  luaunit.assertNil(first[3])
  luaunit.assertEquals(first[4], 1)
  luaunit.assertEquals(second.n, 4)
  luaunit.assertNil(second[1])
  luaunit.assertEquals(second[2], 'middle')
  luaunit.assertNil(second[3])
  luaunit.assertEquals(second[4], 1)
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize_multi_recomputes_for_different_args()
  local calls = 0
  local memoized = memoize_multi(function(value)
    calls = calls + 1
    return value, calls
  end)

  luaunit.assertEquals(pack(memoized('a')), {
    n = 2,
    'a',
    1
  })
  luaunit.assertEquals(pack(memoized('b')), {
    n = 2,
    'b',
    2
  })
  luaunit.assertEquals(pack(memoized('a')), {
    n = 2,
    'a',
    1
  })
  luaunit.assertEquals(calls, 2)
end

-- memoize1 tests (unary fast path)

function TestMemoize.test_memoize1_caches_single_arg()
  local calls = 0
  local memoized = Memoize.memoize(function(a)
    calls = calls + 1
    return a .. ':' .. calls
  end, 1)

  luaunit.assertEquals(memoized('x'), 'x:1')
  luaunit.assertEquals(memoized('x'), 'x:1')
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize1_caches_nil_arg()
  local calls = 0
  local memoized = Memoize.memoize(function(a)
    calls = calls + 1
    return tostring(a) .. ':' .. calls
  end, 1)

  luaunit.assertEquals(memoized(nil), 'nil:1')
  luaunit.assertEquals(memoized(nil), 'nil:1')
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize1_caches_nil_return()
  local calls = 0
  local memoized = Memoize.memoize(function()
    calls = calls + 1
    return nil
  end, 1)

  luaunit.assertNil(memoized())
  luaunit.assertNil(memoized())
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize1_caches_false_return()
  local calls = 0
  local memoized = Memoize.memoize(function()
    calls = calls + 1
    return false
  end, 1)

  luaunit.assertFalse(memoized())
  luaunit.assertFalse(memoized())
  luaunit.assertEquals(calls, 1)
end

-- memoize2 tests (binary fast path)

function TestMemoize.test_memoize2_caches_two_args()
  local calls = 0
  local memoized = Memoize.memoize(function(a, b)
    calls = calls + 1
    return a .. ':' .. b .. ':' .. calls
  end, 2)

  luaunit.assertEquals(memoized('a', 'b'), 'a:b:1')
  luaunit.assertEquals(memoized('a', 'b'), 'a:b:1')
  luaunit.assertEquals(memoized('a', 'c'), 'a:c:2')
  luaunit.assertEquals(calls, 2)
end

function TestMemoize.test_memoize2_caches_nil_args()
  local calls = 0
  local memoized = Memoize.memoize(function(a, b)
    calls = calls + 1
    return tostring(a) .. ':' .. tostring(b) .. ':' .. calls
  end, 2)

  luaunit.assertEquals(memoized(nil, 'x'), 'nil:x:1')
  luaunit.assertEquals(memoized(nil, 'x'), 'nil:x:1')
  luaunit.assertEquals(memoized('x', nil), 'x:nil:2')
  luaunit.assertEquals(calls, 2)
end

function TestMemoize.test_memoize2_caches_nil_return()
  local calls = 0
  local memoized = Memoize.memoize(function()
    calls = calls + 1
    return nil
  end, 2)

  luaunit.assertNil(memoized())
  luaunit.assertNil(memoized())
  luaunit.assertEquals(calls, 1)
end

-- memoize3 tests (ternary fast path)

function TestMemoize.test_memoize3_caches_three_args()
  local calls = 0
  local memoized = Memoize.memoize(function(a, b, c)
    calls = calls + 1
    return a .. ':' .. b .. ':' .. c .. ':' .. calls
  end, 3)

  luaunit.assertEquals(memoized('a', 'b', 'c'), 'a:b:c:1')
  luaunit.assertEquals(memoized('a', 'b', 'c'), 'a:b:c:1')
  luaunit.assertEquals(memoized('a', 'b', 'd'), 'a:b:d:2')
  luaunit.assertEquals(calls, 2)
end

-- memoize default arity (n=1)

function TestMemoize.test_memoize_default_arity_caches_single_arg()
  local calls = 0
  local memoized = Memoize.memoize(function(value)
    calls = calls + 1
    return value .. ':' .. calls
  end)

  luaunit.assertEquals(memoized('x'), 'x:1')
  luaunit.assertEquals(memoized('x'), 'x:1')
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize_explicit_arity2_caches_two_args()
  local calls = 0
  local memoized = Memoize.memoize(function(a, b)
    calls = calls + 1
    return a .. ':' .. b .. ':' .. calls
  end, 2)

  luaunit.assertEquals(memoized('a', 'b'), 'a:b:1')
  luaunit.assertEquals(memoized('a', 'b'), 'a:b:1')
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize_default_arity_caches_nil_return()
  local calls = 0
  local memoized = Memoize.memoize(function()
    calls = calls + 1
    return nil
  end)

  luaunit.assertNil(memoized())
  luaunit.assertNil(memoized())
  luaunit.assertEquals(calls, 1)
end

function TestMemoize.test_memoize_default_arity_caches_false_return()
  local calls = 0
  local memoized = Memoize.memoize(function()
    calls = calls + 1
    return false
  end)

  luaunit.assertFalse(memoized())
  luaunit.assertFalse(memoized())
  luaunit.assertEquals(calls, 1)
end

local M = {}

function M.run()
  local runner = luaunit.LuaUnit.new()
  return runner:runSuiteByInstancesNoCmdLineParsing({
    {
      'TestMemoize',
      TestMemoize
    }
  })
end

return M