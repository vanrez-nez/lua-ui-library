local luaunit = require('luaunit')
local Rule = require('lib.ui.utils.rule')
local CustomRules = require('lib.ui.schema.custom_rules')

local TestCoreRules = {}

function TestCoreRules.test_validate_size_value_accepts_number()
  local r = CustomRules.size_value()
  Rule.validate(r, 'width', 100)
end

function TestCoreRules.test_validate_size_value_accepts_fill()
  local r = CustomRules.size_value()
  Rule.validate(r, 'width', 'fill')
end

function TestCoreRules.test_validate_size_value_accepts_percentage()
  local r = CustomRules.size_value()
  Rule.validate(r, 'width', '50%')
end

function TestCoreRules.test_validate_size_value_accepts_content_when_allowed()
  local r = CustomRules.size_value({ allow_content = true })
  Rule.validate(r, 'width', 'content')
end

function TestCoreRules.test_validate_size_value_rejects_content_when_not_allowed()
  local r = CustomRules.size_value()
  luaunit.assertError(function()
    Rule.validate(r, 'width', 'content')
  end)
end

function TestCoreRules.test_validate_size_value_rejects_invalid_string()
  local r = CustomRules.size_value()
  luaunit.assertError(function()
    Rule.validate(r, 'width', 'auto')
  end)
end

function TestCoreRules.test_validate_opacity_rejects_out_of_range_value()
  local r = CustomRules.opacity()
  luaunit.assertError(function()
    Rule.validate(r, 'opacity', 2)
  end)
end

function TestCoreRules.test_validate_color_accepts_named_color()
  local r = CustomRules.color()
  local result = Rule.validate(r, 'color', 'white')
  luaunit.assertEquals(result, { 1, 1, 1, 1 })
end

local M = {}

function M.run()
  local runner = luaunit.LuaUnit.new()
  return runner:runSuiteByInstancesNoCmdLineParsing({
    { 'TestCoreRules', TestCoreRules },
  })
end

return M
