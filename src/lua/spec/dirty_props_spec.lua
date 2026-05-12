local luaunit = require('luaunit')
local DirtyProps = require('lib.ui.utils.dirty_props')

local TestDirtyProps = {}

-- helpers

local function make_standalone()
  return DirtyProps.create({
    x = { val = 0, groups = { 'layout' } },
    y = { val = 0, groups = { 'layout' } },
    color = { val = 0xff0000, groups = { 'appearance' } },
    name = { val = '' },
  })
end

-- create

function TestDirtyProps.test_create_sets_initial_values()
  local p = make_standalone()

  luaunit.assertEquals(p.x, 0)
  luaunit.assertEquals(p.y, 0)
  luaunit.assertEquals(p.color, 0xff0000)
  luaunit.assertEquals(p.name, '')
end

function TestDirtyProps.test_create_prop_without_groups()
  local p = DirtyProps.create({
    label = { val = 'hi' },
  })

  luaunit.assertEquals(p.label, 'hi')
end

-- init (mixin mode)

function TestDirtyProps.test_init_defines_props_on_existing_object()
  local obj = {}
  DirtyProps.init(obj, {
    x = { val = 10, groups = { 'layout' } },
    y = { val = 20, groups = { 'layout' } },
  })

  luaunit.assertEquals(obj.x, 10)
  luaunit.assertEquals(obj.y, 20)
end

function TestDirtyProps.test_init_preserves_existing_metatable()
  local Class = {}
  Class.__index = Class
  local obj = setmetatable({}, Class)

  DirtyProps.init(obj, {
    x = { val = 1 },
  })

  luaunit.assertEquals(getmetatable(obj), Class)
end

-- sync_dirty_props

function TestDirtyProps.test_sync_detects_no_changes()
  local p = make_standalone()
  p:reset_dirty_props()

  p:sync_dirty_props()

  luaunit.assertFalse(p:is_dirty('x'))
  luaunit.assertFalse(p:is_dirty('y'))
  luaunit.assertFalse(p:is_dirty('color'))
  luaunit.assertFalse(p:is_dirty('name'))
end

function TestDirtyProps.test_sync_detects_single_change()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 50
  p:sync_dirty_props()

  luaunit.assertTrue(p:is_dirty('x'))
  luaunit.assertFalse(p:is_dirty('y'))
end

function TestDirtyProps.test_sync_detects_multiple_changes()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p.color = 0x00ff00
  p:sync_dirty_props()

  luaunit.assertTrue(p:is_dirty('x'))
  luaunit.assertFalse(p:is_dirty('y'))
  luaunit.assertTrue(p:is_dirty('color'))
  luaunit.assertFalse(p:is_dirty('name'))
end

function TestDirtyProps.test_sync_not_dirty_before_sync_called()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 99

  luaunit.assertFalse(p:is_dirty('x'))
end

-- reset_dirty_props

function TestDirtyProps.test_reset_clears_dirty_after_sync()
  local p = make_standalone()
  p:reset_dirty_props()
  p.x = 50
  p:sync_dirty_props()

  luaunit.assertTrue(p:is_dirty('x'))

  p:reset_dirty_props()

  luaunit.assertFalse(p:is_dirty('x'))
end

function TestDirtyProps.test_reset_then_sync_only_flags_new_changes()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 50
  p:sync_dirty_props()
  p:reset_dirty_props()

  p:sync_dirty_props()
  luaunit.assertFalse(p:is_dirty('x'))

  p.x = 100
  p:sync_dirty_props()
  luaunit.assertTrue(p:is_dirty('x'))
end

function TestDirtyProps.test_reset_returns_self()
  local p = make_standalone()

  luaunit.assertIs(p:reset_dirty_props(), p)
end

-- is_dirty

function TestDirtyProps.test_is_dirty_with_zero_value()
  local p = DirtyProps.create({
    count = { val = 0, groups = { 'data' } },
  })
  p:reset_dirty_props()

  p.count = 5
  p:sync_dirty_props()

  luaunit.assertTrue(p:is_dirty('count'))
end

function TestDirtyProps.test_is_dirty_setting_same_value()
  local p = DirtyProps.create({
    x = { val = 10, groups = { 'layout' } },
  })
  p:reset_dirty_props()

  p.x = 10
  p:sync_dirty_props()

  luaunit.assertFalse(p:is_dirty('x'))
end

-- any_dirty / all_dirty

function TestDirtyProps.test_any_dirty_true_when_one_dirty()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p:sync_dirty_props()

  luaunit.assertTrue(p:any_dirty('x', 'y'))
end

function TestDirtyProps.test_any_dirty_false_when_none_dirty()
  local p = make_standalone()
  p:reset_dirty_props()

  p:sync_dirty_props()

  luaunit.assertFalse(p:any_dirty('x', 'y'))
end

function TestDirtyProps.test_all_dirty_true_when_all_dirty()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p.y = 2
  p:sync_dirty_props()

  luaunit.assertTrue(p:all_dirty('x', 'y'))
end

function TestDirtyProps.test_all_dirty_false_when_partial()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p:sync_dirty_props()

  luaunit.assertFalse(p:all_dirty('x', 'y'))
end

-- groups

function TestDirtyProps.test_group_dirty_true_when_member_changed()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 5
  p:sync_dirty_props()

  luaunit.assertTrue(p:group_dirty('layout'))
end

function TestDirtyProps.test_group_dirty_false_when_no_member_changed()
  local p = make_standalone()
  p:reset_dirty_props()

  p:sync_dirty_props()

  luaunit.assertFalse(p:group_dirty('layout'))
end

function TestDirtyProps.test_group_dirty_independent_groups()
  local p = make_standalone()
  p:reset_dirty_props()

  p.color = 0
  p:sync_dirty_props()

  luaunit.assertFalse(p:group_dirty('layout'))
  luaunit.assertTrue(p:group_dirty('appearance'))
end

function TestDirtyProps.test_prop_in_multiple_groups()
  local p = DirtyProps.create({
    x = { val = 0, groups = { 'layout', 'geometry' } },
  })
  p:reset_dirty_props()

  p.x = 10
  p:sync_dirty_props()

  luaunit.assertTrue(p:group_dirty('layout'))
  luaunit.assertTrue(p:group_dirty('geometry'))
end

function TestDirtyProps.test_prop_with_no_groups_never_affects_groups()
  local p = make_standalone()
  p:reset_dirty_props()

  p.name = 'new'
  p:sync_dirty_props()

  luaunit.assertFalse(p:group_dirty('layout'))
  luaunit.assertFalse(p:group_dirty('appearance'))
end

-- group_any_dirty / group_all_dirty

function TestDirtyProps.test_group_any_dirty_true_when_one_group_dirty()
  local p = make_standalone()
  p:reset_dirty_props()

  p.color = 0
  p:sync_dirty_props()

  luaunit.assertTrue(p:group_any_dirty('layout', 'appearance'))
end

function TestDirtyProps.test_group_any_dirty_false_when_none_dirty()
  local p = make_standalone()
  p:reset_dirty_props()

  p:sync_dirty_props()

  luaunit.assertFalse(p:group_any_dirty('layout', 'appearance'))
end

function TestDirtyProps.test_group_all_dirty_true_when_all_dirty()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p.color = 0
  p:sync_dirty_props()

  luaunit.assertTrue(p:group_all_dirty('layout', 'appearance'))
end

function TestDirtyProps.test_group_all_dirty_false_when_partial()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p:sync_dirty_props()

  luaunit.assertFalse(p:group_all_dirty('layout', 'appearance'))
end

-- mark_dirty

function TestDirtyProps.test_mark_dirty_manually_flags_group()
  local p = make_standalone()
  p:reset_dirty_props()
  p:sync_dirty_props()

  p:mark_dirty('layout')

  luaunit.assertTrue(p:group_dirty('layout'))
  luaunit.assertFalse(p:group_dirty('appearance'))
end

function TestDirtyProps.test_mark_dirty_multiple_groups()
  local p = make_standalone()
  p:reset_dirty_props()
  p:sync_dirty_props()

  p:mark_dirty('layout', 'appearance')

  luaunit.assertTrue(p:group_dirty('layout'))
  luaunit.assertTrue(p:group_dirty('appearance'))
end

function TestDirtyProps.test_mark_dirty_combines_with_sync()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p:sync_dirty_props()
  p:mark_dirty('appearance')

  luaunit.assertTrue(p:group_dirty('layout'))
  luaunit.assertTrue(p:group_dirty('appearance'))
end

function TestDirtyProps.test_mark_dirty_returns_self()
  local p = make_standalone()

  luaunit.assertIs(p:mark_dirty('layout'), p)
end

-- clear_dirty

function TestDirtyProps.test_clear_dirty_clears_group()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p.color = 0
  p:sync_dirty_props()

  luaunit.assertTrue(p:group_dirty('layout'))
  luaunit.assertTrue(p:group_dirty('appearance'))

  p:clear_dirty('layout')

  luaunit.assertFalse(p:group_dirty('layout'))
  luaunit.assertTrue(p:group_dirty('appearance'))
end

function TestDirtyProps.test_clear_dirty_multiple_groups()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p.color = 0
  p:sync_dirty_props()

  p:clear_dirty('layout', 'appearance')

  luaunit.assertFalse(p:group_dirty('layout'))
  luaunit.assertFalse(p:group_dirty('appearance'))
end

function TestDirtyProps.test_clear_dirty_noop_on_clean_group()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p:sync_dirty_props()

  p:clear_dirty('appearance')

  luaunit.assertTrue(p:group_dirty('layout'))
  luaunit.assertFalse(p:group_dirty('appearance'))
end

function TestDirtyProps.test_clear_dirty_unknown_group_is_noop()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 1
  p:sync_dirty_props()

  p:clear_dirty('nonexistent')

  luaunit.assertTrue(p:group_dirty('layout'))
end

function TestDirtyProps.test_clear_dirty_returns_self()
  local p = make_standalone()

  luaunit.assertIs(p:clear_dirty('layout'), p)
end

-- get_dirty_props

function TestDirtyProps.test_get_dirty_props_returns_map()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 5
  p.color = 0
  p:sync_dirty_props()

  local map = p:get_dirty_props()

  luaunit.assertTrue(map.x)
  luaunit.assertFalse(map.y)
  luaunit.assertTrue(map.color)
  luaunit.assertFalse(map.name)
end

function TestDirtyProps.test_get_dirty_props_returns_copy()
  local p = make_standalone()
  p:reset_dirty_props()
  p:sync_dirty_props()

  local map = p:get_dirty_props()
  map.x = true

  luaunit.assertFalse(p:is_dirty('x'))
end

-- get_dirty_groups

function TestDirtyProps.test_get_dirty_groups_returns_map()
  local p = make_standalone()
  p:reset_dirty_props()

  p.x = 5
  p:sync_dirty_props()

  local map = p:get_dirty_groups()

  luaunit.assertTrue(map.layout)
  luaunit.assertFalse(map.appearance)
end

function TestDirtyProps.test_get_dirty_groups_returns_copy()
  local p = make_standalone()
  p:reset_dirty_props()
  p:sync_dirty_props()

  local map = p:get_dirty_groups()
  map.layout = false

  luaunit.assertTrue(p:group_dirty('layout') == false)
end

-- mixin mode full lifecycle

function TestDirtyProps.test_mixin_full_lifecycle()
  local obj = {}
  DirtyProps.init(obj, {
    x = { val = 0, groups = { 'layout' } },
    y = { val = 0, groups = { 'layout' } },
  })
  setmetatable(obj, DirtyProps)

  obj:reset_dirty_props()

  obj.x = 10
  obj:sync_dirty_props()

  luaunit.assertTrue(obj:is_dirty('x'))
  luaunit.assertFalse(obj:is_dirty('y'))
  luaunit.assertTrue(obj:group_dirty('layout'))

  obj:reset_dirty_props()
  luaunit.assertFalse(obj:is_dirty('x'))
end

local M = {}

function M.run()
  local runner = luaunit.LuaUnit.new()
  return runner:runSuiteByInstancesNoCmdLineParsing({
    {
      'TestDirtyProps',
      TestDirtyProps
    }
  })
end

return M