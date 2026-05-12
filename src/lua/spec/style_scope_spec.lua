local luaunit = require('luaunit')
local Drawable = require('lib.ui.core.drawable')
local Styling = require('lib.ui.render.styling')
local StyleScope = require('lib.ui.render.style_scope')
local Theme = require('lib.ui.themes.theme')

local TestStyleScope = {}

function TestStyleScope.tearDown()
  Theme.set_active(nil)
end

function TestStyleScope.test_drawable_accepts_style_scope_and_variant()
  local scope = StyleScope.create('button', 'surface')
  local node = Drawable.new({
    style_scope = scope,
    style_variant = 'hovered',
  })

  luaunit.assertEquals(node.style_scope:get_component(), 'button')
  luaunit.assertEquals(node.style_scope:get_part(), 'surface')
  luaunit.assertEquals(node:resolveStyleVariant(), 'hovered')
end

function TestStyleScope.test_style_scope_rejects_invalid_segments()
  luaunit.assertErrorMsgContains('component must not be empty', function()
    StyleScope.create('', 'surface')
  end)

  luaunit.assertErrorMsgContains('part must not contain "."', function()
    StyleScope.create('button', 'surface.primary')
  end)
end

function TestStyleScope.test_style_scope_builds_token_keys()
  local scope = StyleScope.create('button', 'surface')

  luaunit.assertEquals(scope:get_token_key('backgroundColor'), 'button.surface.backgroundColor')
  luaunit.assertEquals(
    scope:get_token_key('backgroundColor', 'hovered'),
    'button.surface.backgroundColor.hovered'
  )
  luaunit.assertEquals(scope:get_token_key('backgroundColor', 'base'), 'button.surface.backgroundColor')
end

function TestStyleScope.test_style_scope_compares_by_component_and_part()
  local left = StyleScope.create('button', 'surface')
  local matching = StyleScope.create('button', 'surface')
  local different = StyleScope.create('button', 'icon')

  luaunit.assertTrue(left:equals(matching))
  luaunit.assertTrue(left == matching)
  luaunit.assertFalse(left:equals(different))
end

function TestStyleScope.test_plain_tables_are_not_style_scopes()
  luaunit.assertFalse(StyleScope.is_style_scope({
    component = 'button',
    part = 'surface',
  }))
end

function TestStyleScope.test_drawable_rejects_plain_table_style_scope()
  luaunit.assertErrorMsgContains('Drawable.style_scope must be a StyleScope', function()
    Drawable.new({
      style_scope = { part = 'surface' },
    })
  end)
end

function TestStyleScope.test_setters_update_scope_and_variant()
  local node = Drawable.new()
  local scope = StyleScope.create('modal', 'surface')

  node:setStyleScope(scope)
  node:setStyleVariant('warning')

  luaunit.assertEquals(node.style_scope:get_component(), 'modal')
  luaunit.assertEquals(node.style_scope:get_part(), 'surface')
  luaunit.assertEquals(node.style_variant, 'warning')
end

function TestStyleScope.test_assemble_props_uses_node_scope_and_variant()
  local scope = StyleScope.create('styleScopeSpec', 'surface')
  Theme.set_active(Theme.new({
    tokens = {
      ['styleScopeSpec.surface.backgroundColor.hovered'] = { 0.28, 0.62, 1.0, 1 },
    },
  }))

  local node = Drawable.new({
    style_scope = scope,
    style_variant = 'hovered',
  })

  local props = Styling.assemble_props(node)

  luaunit.assertEquals(props.backgroundColor, { 0.28, 0.62, 1.0, 1 })
end

function TestStyleScope.test_assemble_props_uses_active_theme()
  local scope = StyleScope.create('styleScopeSpec', 'surface')
  Theme.set_active(Theme.new({
    tokens = {
      ['styleScopeSpec.surface.backgroundColor.hovered'] = { 1, 0, 0, 1 },
    },
  }))

  local node = Drawable.new({
    style_scope = scope,
    style_variant = 'hovered',
  })

  local props = Styling.assemble_props(node)

  luaunit.assertEquals(props.backgroundColor, { 1, 0, 0, 1 })
end

local M = {}

function M.run()
  local runner = luaunit.LuaUnit.new()
  return runner:runSuiteByInstancesNoCmdLineParsing({
    { 'TestStyleScope', TestStyleScope },
  })
end

return M
