local luaunit = require('luaunit')
local Rule = require('lib.ui.utils.rule')

local TestRule = {}

-- Rule.validate — required fields

function TestRule.test_validate_required_number_raises_on_nil()
  local r = Rule.number({ min = 0, max = 100 })
  luaunit.assertError(function()
    Rule.validate(r, 'age', nil)
  end)
end

function TestRule.test_validate_required_number_passes_on_valid_value()
  local r = Rule.number({ min = 0, max = 100 })
  Rule.validate(r, 'age', 50)
end

function TestRule.test_validate_required_number_raises_on_out_of_range()
  local r = Rule.number({ min = 0, max = 100 })
  luaunit.assertError(function()
    Rule.validate(r, 'age', 200)
  end)
end

function TestRule.test_validate_required_number_raises_on_negative_below_min()
  local r = Rule.number({ min = 1 })
  luaunit.assertError(function()
    Rule.validate(r, 'count', -1)
  end)
end

-- Rule.validate — optional fields

function TestRule.test_validate_optional_number_accepts_nil()
  local r = Rule.number({ optional = true })
  Rule.validate(r, 'bonus', nil)
end

function TestRule.test_validate_optional_number_accepts_valid_value()
  local r = Rule.number({ optional = true, min = 0 })
  Rule.validate(r, 'bonus', 10)
end

-- Rule.validate — defaulted fields

function TestRule.test_validate_number_with_default_accepts_nil()
  local r = Rule.number({ default = 0 })
  Rule.validate(r, 'x', nil)
end

function TestRule.test_validate_number_with_default_still_validates_value()
  local r = Rule.number({ default = 0, max = 10 })
  luaunit.assertError(function()
    Rule.validate(r, 'x', 20)
  end)
end

-- Rule.validate — string

function TestRule.test_validate_string_passes_on_valid_string()
  local r = Rule.string()
  Rule.validate(r, 'name', 'hello')
end

function TestRule.test_validate_string_raises_on_nil_when_required()
  local r = Rule.string()
  luaunit.assertError(function()
    Rule.validate(r, 'name', nil)
  end)
end

function TestRule.test_validate_string_optional_accepts_nil()
  local r = Rule.string({ optional = true })
  Rule.validate(r, 'name', nil)
end

function TestRule.test_validate_string_non_empty_rejects_empty()
  local r = Rule.string({ non_empty = true })
  luaunit.assertError(function()
    Rule.validate(r, 'name', '')
  end)
end

function TestRule.test_validate_string_min_len_rejects_short()
  local r = Rule.string({ min_len = 3 })
  luaunit.assertError(function()
    Rule.validate(r, 'name', 'ab')
  end)
end

function TestRule.test_validate_string_max_len_rejects_long()
  local r = Rule.string({ max_len = 5 })
  luaunit.assertError(function()
    Rule.validate(r, 'name', 'abcdef')
  end)
end

function TestRule.test_validate_string_pattern_rejects_no_match()
  local r = Rule.string({ pattern = '^%a+$' })
  luaunit.assertError(function()
    Rule.validate(r, 'name', 'abc123')
  end)
end

function TestRule.test_validate_string_pattern_accepts_match()
  local r = Rule.string({ pattern = '^%a+$' })
  Rule.validate(r, 'name', 'abc')
end

-- Rule.validate — boolean

function TestRule.test_validate_boolean_passes_on_true()
  local r = Rule.boolean()
  Rule.validate(r, 'flag', true)
end

function TestRule.test_validate_boolean_passes_on_false()
  local r = Rule.boolean()
  Rule.validate(r, 'flag', false)
end

function TestRule.test_validate_boolean_raises_on_non_boolean()
  local r = Rule.boolean()
  luaunit.assertError(function()
    Rule.validate(r, 'flag', 'yes')
  end)
end

function TestRule.test_validate_boolean_shorthand_true()
  local r = Rule.boolean(true)
  luaunit.assertEquals(r.default, true)
  luaunit.assertTrue(r.has_default)
end

function TestRule.test_validate_boolean_shorthand_false()
  local r = Rule.boolean(false)
  luaunit.assertEquals(r.default, false)
  luaunit.assertTrue(r.has_default)
end

-- Rule.validate — table

function TestRule.test_validate_table_passes_on_table()
  local r = Rule.table()
  Rule.validate(r, 'data', { 1, 2, 3 })
end

function TestRule.test_validate_table_raises_on_non_table()
  local r = Rule.table()
  luaunit.assertError(function()
    Rule.validate(r, 'data', 'not a table')
  end)
end

-- Rule.validate — enum

function TestRule.test_validate_enum_passes_on_allowed_value()
  local r = Rule.enum({ 'left', 'center', 'right' })
  Rule.validate(r, 'align', 'center')
end

function TestRule.test_validate_enum_raises_on_disallowed_value()
  local r = Rule.enum({ 'left', 'center', 'right' })
  luaunit.assertError(function()
    Rule.validate(r, 'align', 'top')
  end)
end

function TestRule.test_validate_enum_with_default_accepts_nil()
  local r = Rule.enum({ 'a', 'b' }, { default = 'a' })
  Rule.validate(r, 'choice', nil)
end

-- Rule.validate — size_value

function TestRule.test_validate_size_value_accepts_number()
  local r = Rule.size_value()
  Rule.validate(r, 'width', 100)
end

function TestRule.test_validate_size_value_accepts_fill()
  local r = Rule.size_value()
  Rule.validate(r, 'width', 'fill')
end

function TestRule.test_validate_size_value_accepts_percentage()
  local r = Rule.size_value()
  Rule.validate(r, 'width', '50%')
end

function TestRule.test_validate_size_value_accepts_content_when_allowed()
  local r = Rule.size_value({ allow_content = true })
  Rule.validate(r, 'width', 'content')
end

function TestRule.test_validate_size_value_rejects_content_when_not_allowed()
  local r = Rule.size_value()
  luaunit.assertError(function()
    Rule.validate(r, 'width', 'content')
  end)
end

function TestRule.test_validate_size_value_rejects_invalid_string()
  local r = Rule.size_value()
  luaunit.assertError(function()
    Rule.validate(r, 'width', 'auto')
  end)
end

-- Rule.validate — any_of

function TestRule.test_validate_any_of_passes_on_first_match()
  local r = Rule.any_of({ Rule.number(), Rule.string() })
  Rule.validate(r, 'value', 42)
end

function TestRule.test_validate_any_of_passes_on_second_match()
  local r = Rule.any_of({ Rule.number(), Rule.string() })
  Rule.validate(r, 'value', 'hello')
end

function TestRule.test_validate_any_of_raises_on_no_match()
  local r = Rule.any_of({ Rule.number(), Rule.string() })
  luaunit.assertError(function()
    Rule.validate(r, 'value', true)
  end)
end

-- Rule.validate — all_of

function TestRule.test_validate_all_of_passes_when_all_match()
  local r = Rule.all_of({
    Rule.string({ min_len = 2 }),
    Rule.string({ max_len = 10 }),
  })
  Rule.validate(r, 'name', 'abc')
end

function TestRule.test_validate_all_of_raises_when_one_fails()
  local r = Rule.all_of({
    Rule.string({ min_len = 5 }),
    Rule.string({ max_len = 10 }),
  })
  luaunit.assertError(function()
    Rule.validate(r, 'name', 'ab')
  end)
end

-- Rule.resolve

function TestRule.test_resolve_returns_value_when_non_nil()
  local r = Rule.number({ default = 0 })
  local v = Rule.resolve(r, 42)
  luaunit.assertEquals(v, 42)
end

function TestRule.test_resolve_returns_default_when_nil()
  local r = Rule.number({ default = 99 })
  local v = Rule.resolve(r, nil)
  luaunit.assertEquals(v, 99)
end

function TestRule.test_resolve_returns_nil_for_optional()
  local r = Rule.string({ optional = true })
  local v = Rule.resolve(r, nil)
  luaunit.assertNil(v)
end

function TestRule.test_resolve_returns_nil_and_required_for_required_no_default()
  local r = Rule.string()
  local v, err = Rule.resolve(r, nil)
  luaunit.assertNil(v)
  luaunit.assertEquals(err, 'is required')
end

-- Rule.optional

function TestRule.test_optional_makes_required_rule_optional()
  local base = Rule.number({ min = 0, max = 100 })
  local opt = Rule.optional(base)

  luaunit.assertTrue(opt.optional)
  luaunit.assertFalse(opt.has_default)
  luaunit.assertNil(opt.default)
  luaunit.assertEquals(opt.min, 0)
  luaunit.assertEquals(opt.max, 100)
end

function TestRule.test_optional_rule_accepts_nil()
  local base = Rule.number({ min = 0, max = 100 })
  local opt = Rule.optional(base)
  Rule.validate(opt, 'score', nil)
end

function TestRule.test_optional_rule_still_validates_value()
  local base = Rule.number({ min = 0, max = 100 })
  local opt = Rule.optional(base)
  luaunit.assertError(function()
    Rule.validate(opt, 'score', 200)
  end)
end

-- Rule factory — check_opts rejects unknown keys

function TestRule.test_number_rejects_unknown_opts()
  luaunit.assertError(function()
    Rule.number({ min = 0, unknown = true })
  end)
end

function TestRule.test_string_rejects_unknown_opts()
  luaunit.assertError(function()
    Rule.string({ non_empty = true, bogus = 1 })
  end)
end

-- Rule factory — default propagation

function TestRule.test_number_default_sets_has_default()
  local r = Rule.number({ default = 5 })
  luaunit.assertTrue(r.has_default)
  luaunit.assertEquals(r.default, 5)
end

function TestRule.test_number_no_default_means_has_default_false()
  local r = Rule.number({ min = 0 })
  luaunit.assertFalse(r.has_default)
  luaunit.assertNil(r.default)
end

function TestRule.test_string_default_sets_has_default()
  local r = Rule.string({ default = 'hello' })
  luaunit.assertTrue(r.has_default)
  luaunit.assertEquals(r.default, 'hello')
end

-- Rule.number — integer constraint

function TestRule.test_number_integer_rejects_float()
  local r = Rule.number({ integer = true })
  luaunit.assertError(function()
    Rule.validate(r, 'count', 3.14)
  end)
end

function TestRule.test_number_integer_accepts_whole_number()
  local r = Rule.number({ integer = true })
  Rule.validate(r, 'count', 5)
end

-- Rule.number — finite constraint

function TestRule.test_number_finite_rejects_inf_by_default()
  local r = Rule.number()
  luaunit.assertError(function()
    Rule.validate(r, 'x', math.huge)
  end)
end

function TestRule.test_number_finite_false_allows_inf()
  local r = Rule.number({ finite = false })
  Rule.validate(r, 'x', math.huge)
end

local M = {}

function M.run()
  local runner = luaunit.LuaUnit.new()
  return runner:runSuiteByInstancesNoCmdLineParsing({
    { 'TestRule', TestRule },
  })
end

return M