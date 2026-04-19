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
  Rule.validate(r, 'color', 'white')
end

function TestCoreRules.test_validate_padding_accepts_number()
  local r = CustomRules.padding()
  Rule.validate(r, 'padding', 8)
end

function TestCoreRules.test_validate_padding_accepts_keyed_table()
  local r = CustomRules.padding()
  Rule.validate(r, 'padding', {
    top = 1,
    right = 2,
    bottom = 3,
    left = 4,
  })
end

function TestCoreRules.test_validate_padding_accepts_two_value_table()
  local r = CustomRules.padding()
  Rule.validate(r, 'padding', { 1, 2 })
end

function TestCoreRules.test_validate_padding_accepts_four_value_table()
  local r = CustomRules.padding()
  Rule.validate(r, 'padding', { 1, 2, 3, 4 })
end

function TestCoreRules.test_validate_padding_rejects_negative_member()
  local r = CustomRules.padding()
  luaunit.assertError(function()
    Rule.validate(r, 'padding', { 1, -2 })
  end)
end

function TestCoreRules.test_validate_padding_rejects_infinite_member()
  local r = CustomRules.padding()
  luaunit.assertError(function()
    Rule.validate(r, 'padding', { 1, math.huge })
  end)
end

function TestCoreRules.test_validate_padding_rejects_invalid_arity()
  local r = CustomRules.padding()
  luaunit.assertError(function()
    Rule.validate(r, 'padding', { 1, 2, 3 })
  end)
end

function TestCoreRules.test_validate_margin_accepts_negative_member()
  local r = CustomRules.margin()
  Rule.validate(r, 'margin', { top = -1 })
end

function TestCoreRules.test_validate_margin_rejects_infinite_member()
  local r = CustomRules.margin()
  luaunit.assertError(function()
    Rule.validate(r, 'margin', { top = math.huge })
  end)
end

function TestCoreRules.test_custom_rules_reject_set_option()
  luaunit.assertError(function()
    CustomRules.padding({ set = function() end })
  end)
end

local M = {}

function M.run()
  local runner = luaunit.LuaUnit.new()
  return runner:runSuiteByInstancesNoCmdLineParsing({
    { 'TestCoreRules', TestCoreRules },
  })
end

return M
