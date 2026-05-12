local luaunit = require('luaunit')
local Reactive = require('lib.ui.utils.reactive')

local TestReactive = {}

-- create

function TestReactive.test_create_hook_free_property_stores_raw_on_obj()
  local obj = Reactive.create({
    x = { val = 10 },
  })

  luaunit.assertEquals(obj.x, 10)
  luaunit.assertTrue(rawget(obj, 'x') ~= nil)
end

function TestReactive.test_create_hooked_property_stores_in_state()
  local obj = Reactive.create({
    x = {
      val = 10,
      get = function(_, v) return v end,
      set = function(_, v, _) return v end,
    },
  })

  luaunit.assertEquals(obj.x, 10)
  luaunit.assertNil(rawget(obj, 'x'))
end

function TestReactive.test_create_multiple_properties()
  local obj = Reactive.create({
    a = { val = 1 },
    b = { val = 2 },
    c = { val = 3 },
  })

  luaunit.assertEquals(obj.a, 1)
  luaunit.assertEquals(obj.b, 2)
  luaunit.assertEquals(obj.c, 3)
end

-- __index — getter dispatch

function TestReactive.test_getter_transforms_read()
  local obj = Reactive.create({
    x = {
      val = 10,
      get = function(_, v) return v * 2 end,
    },
  })

  luaunit.assertEquals(obj.x, 20)
end

function TestReactive.test_getter_receives_self_and_value()
  local captured_self = nil
  local captured_v = nil
  local obj = Reactive.create({
    x = {
      val = 42,
      get = function(self, v)
        captured_self = self
        captured_v = v
        return v
      end,
    },
  })

  local _ = obj.x
  luaunit.assertIs(captured_self, obj)
  luaunit.assertEquals(captured_v, 42)
end

function TestReactive.test_no_getter_returns_value_directly()
  local obj = Reactive.create({
    x = {
      val = 7,
      set = function(_, v, _) return v end,
    },
  })

  luaunit.assertEquals(obj.x, 7)
end

-- __newindex — setter dispatch

function TestReactive.test_setter_transforms_write()
  local obj = Reactive.create({
    x = {
      val = 0,
      set = function(_, v, old) return v + old end,
    },
  })

  obj.x = 5
  luaunit.assertEquals(obj.x, 5)
end

function TestReactive.test_setter_receives_self_new_and_old()
  local captured = {}
  local obj = Reactive.create({
    x = {
      val = 10,
      set = function(self, v, old)
        captured.self = self
        captured.new = v
        captured.old = old
        return v
      end,
    },
  })

  obj.x = 20
  luaunit.assertIs(captured.self, obj)
  luaunit.assertEquals(captured.new, 20)
  luaunit.assertEquals(captured.old, 10)
end

function TestReactive.test_setter_must_return_non_nil()
  local obj = Reactive.create({
    x = {
      val = 1,
      set = function() return nil end,
    },
  })

  luaunit.assertError(function()
    obj.x = 2
  end)
end

-- __newindex — equality short-circuit

function TestReactive.test_same_value_write_is_noop()
  local called = false
  local obj = Reactive.create({
    x = {
      val = 5,
      set = function(_, v)
        called = true
        return v
      end,
    },
  })

  obj.x = 5

  luaunit.assertFalse(called)
end

function TestReactive.test_different_value_write_calls_setter()
  local called = false
  local obj = Reactive.create({
    x = {
      val = 5,
      set = function(_, v)
        called = true
        return v
      end,
    },
  })

  obj.x = 6

  luaunit.assertTrue(called)
end

-- __newindex — hook-free write

function TestReactive.test_hook_free_write_stores_raw()
  local obj = Reactive.create({
    x = { val = 1 },
  })

  obj.x = 99
  luaunit.assertEquals(rawget(obj, 'x'), 99)
end

-- __newindex — transitioning from hook-free to hooked

function TestReactive.test_write_to_hooked_with_no_setter_and_no_getter_stores_raw()
  local obj = Reactive.create({
    x = { val = 1 },
  })

  obj.x = 50
  luaunit.assertEquals(rawget(obj, 'x'), 50)
end

-- define_property

function TestReactive.test_define_property_hooked()
  local obj = {}
  Reactive.define_property(obj, 'x', {
    val = 10,
    get = function(_, v) return v end,
    set = function(_, v, _) return v end,
  })

  luaunit.assertEquals(obj.x, 10)
  luaunit.assertNil(rawget(obj, 'x'))
end

function TestReactive.test_define_property_hook_free()
  local obj = {}
  Reactive.define_property(obj, 'x', { val = 10 })

  luaunit.assertEquals(obj.x, 10)
  luaunit.assertTrue(rawget(obj, 'x') ~= nil)
end

function TestReactive.test_define_property_redefine_hooked_to_hook_free()
  local obj = Reactive.create({
    x = {
      val = 10,
      get = function(_, v) return v * 2 end,
    },
  })

  luaunit.assertEquals(obj.x, 20)

  Reactive.define_property(obj, 'x', { val = 30 })

  luaunit.assertEquals(obj.x, 30)
  luaunit.assertTrue(rawget(obj, 'x') ~= nil)
end

function TestReactive.test_define_property_redefine_hook_free_to_hooked()
  local obj = Reactive.create({
    x = { val = 10 },
  })

  Reactive.define_property(obj, 'x', {
    val = 20,
    get = function(_, v) return v + 1 end,
  })

  luaunit.assertEquals(obj.x, 21)
  luaunit.assertNil(rawget(obj, 'x'))
end

function TestReactive.test_define_property_get_must_be_function()
  local obj = {}

  luaunit.assertError(function()
    Reactive.define_property(obj, 'x', {
      val = 1,
      get = 'not a function',
    })
  end)
end

function TestReactive.test_define_property_set_must_be_function()
  local obj = {}

  luaunit.assertError(function()
    Reactive.define_property(obj, 'x', {
      val = 1,
      set = 42,
    })
  end)
end

-- remove_property

function TestReactive.test_remove_property_hooked()
  local obj = Reactive.create({
    x = {
      val = 10,
      get = function(_, v) return v end,
    },
  })

  Reactive.remove_property(obj, 'x')

  luaunit.assertNil(obj.x)
end

function TestReactive.test_remove_property_hook_free()
  local obj = Reactive.create({
    x = { val = 10 },
  })

  Reactive.remove_property(obj, 'x')

  luaunit.assertNil(rawget(obj, 'x'))
end

function TestReactive.test_remove_property_cleans_both_tiers()
  local obj = Reactive.create({
    x = {
      val = 10,
      set = function(_, v, _) return v end,
    },
  })

  Reactive.remove_property(obj, 'x')
  Reactive.define_property(obj, 'x', { val = 99 })

  luaunit.assertEquals(obj.x, 99)
  luaunit.assertTrue(rawget(obj, 'x') ~= nil)
end

function TestReactive.test_remove_property_on_uninitialized_obj()
  local obj = {}
  Reactive.remove_property(obj, 'x')

  luaunit.assertNil(obj.x)
end

-- raw_get

function TestReactive.test_raw_get_hooked_bypasses_getter()
  local obj = Reactive.create({
    x = {
      val = 10,
      get = function(_, v) return v * 100 end,
    },
  })

  luaunit.assertEquals(Reactive.raw_get(obj, 'x'), 10)
  luaunit.assertEquals(obj.x, 1000)
end

function TestReactive.test_raw_get_hook_free_reads_raw()
  local obj = Reactive.create({
    x = { val = 5 },
  })

  luaunit.assertEquals(Reactive.raw_get(obj, 'x'), 5)
end

function TestReactive.test_raw_get_on_uninitialized_obj()
  local obj = {}
  luaunit.assertNil(Reactive.raw_get(obj, 'x'))
end

-- raw_set

function TestReactive.test_raw_set_hooked_bypasses_setter()
  local called = false
  local obj = Reactive.create({
    x = {
      val = 10,
      set = function(_, v)
        called = true
        return v
      end,
    },
  })

  Reactive.raw_set(obj, 'x', 20)

  luaunit.assertFalse(called)
  luaunit.assertEquals(Reactive.raw_get(obj, 'x'), 20)
end

function TestReactive.test_raw_set_hook_free_writes_raw()
  local obj = Reactive.create({
    x = { val = 5 },
  })

  Reactive.raw_set(obj, 'x', 99)

  luaunit.assertEquals(rawget(obj, 'x'), 99)
end

function TestReactive.test_raw_set_rejects_nil()
  local obj = Reactive.create({
    x = { val = 1 },
  })

  luaunit.assertError(function()
    Reactive.raw_set(obj, 'x', nil)
  end)
end

-- __pairs (note: LuaJIT pairs() does not use __pairs; these test the metamethod directly)

function TestReactive.test_pairs_merges_both_tiers()
  local obj = Reactive.create({
    a = { val = 1 },
    b = {
      val = 2,
      get = function(_, v) return v end,
    },
  })

  local result = {}
  local mt = getmetatable(obj)
  local fn, tbl, state = mt.__pairs(obj)
  local k, v = fn(tbl, state)
  while k do
    result[k] = v
    k, v = fn(tbl, k)
  end

  luaunit.assertEquals(result.a, 1)
  luaunit.assertEquals(result.b, 2)
end

function TestReactive.test_pairs_excludes_accessor_key()
  local obj = Reactive.create({
    x = { val = 1 },
  })

  local keys = {}
  local mt = getmetatable(obj)
  local fn, tbl, state = mt.__pairs(obj)
  local k = fn(tbl, state)
  while k do
    keys[#keys + 1] = type(k)
    k = fn(tbl, k)
  end

  for _, t in ipairs(keys) do
    luaunit.assertEquals(t, 'string')
  end
end

-- two-tier storage invariants

function TestReactive.test_hooked_key_absent_from_raw_obj()
  local obj = Reactive.create({
    x = {
      val = 10,
      get = function(_, v) return v end,
    },
  })

  luaunit.assertNil(rawget(obj, 'x'))
  luaunit.assertEquals(obj.x, 10)
end

function TestReactive.test_hook_free_key_present_on_raw_obj()
  local obj = Reactive.create({
    x = { val = 10 },
  })

  luaunit.assertEquals(rawget(obj, 'x'), 10)
end

function TestReactive.test_setter_only_key_stores_in_state()
  local obj = Reactive.create({
    x = {
      val = 10,
      set = function(_, v, _) return v end,
    },
  })

  luaunit.assertNil(rawget(obj, 'x'))
  luaunit.assertEquals(obj.x, 10)
end

-- multiple objects share metatable

function TestReactive.test_shared_metatable()
  local a = Reactive.create({ x = { val = 1 } })
  local b = Reactive.create({ y = { val = 2 } })

  luaunit.assertIs(getmetatable(a), getmetatable(b))
end

-- write before init

function TestReactive.test_write_to_uninitialized_obj_stores_raw()
  local obj = {}
  setmetatable(obj, {
    __newindex = function(self, key, val)
      rawset(self, key, val)
    end,
  })

  Reactive.define_property(obj, 'x', { val = 1 })

  obj.x = 10
  luaunit.assertEquals(obj.x, 10)
end

local M = {}

function M.run()
  local runner = luaunit.LuaUnit.new()
  return runner:runSuiteByInstancesNoCmdLineParsing({
    { 'TestReactive', TestReactive },
  })
end

return M