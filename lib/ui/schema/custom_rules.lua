local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local Constants = require('lib.ui.core.constants')
local Color = require('lib.ui.render.color')

local CustomRules = {}

local function uses_rule_opts(value)
  return Types.is_table(value) and (
    value.optional ~= nil or
    value.default ~= nil or
    value.set ~= nil
  )
end

local function rule_opts(opts)
  opts = opts or {}
  if opts.set ~= nil then
    Assert.fail('CustomRules: set option is not supported', 3)
  end
  return {
    optional = opts.optional,
    default = opts.default,
  }
end

function CustomRules.validate_finite_number(name, value, level)
  Assert.number(name, value, level or 1)
  Assert.finite(name, value, level or 1)
  return value
end

function CustomRules.validate_non_negative_finite(name, value, level)
  CustomRules.validate_finite_number(name, value, level or 1)
  if value < 0 then
    Assert.fail(name .. ' must be >= 0', level or 1)
  end
  return value
end

local function finite_number_validator(opts)
  opts = opts or {}
  return function(name, value)
    CustomRules.validate_finite_number(name, value, 2)
    if opts.min ~= nil and value < opts.min then
      Assert.fail(name .. ' must be >= ' .. opts.min, 2)
    end
    if opts.max ~= nil and value > opts.max then
      Assert.fail(name .. ' must be <= ' .. opts.max, 2)
    end
  end
end

local function positive_finite_validator(opts)
  opts = opts or {}
  return function(name, value)
    CustomRules.validate_finite_number(name, value, 2)
    if value <= 0 then
      Assert.fail(name .. ' must be > 0', 2)
    end
    if opts.max ~= nil and value > opts.max then
      Assert.fail(name .. ' must be <= ' .. opts.max, 2)
    end
  end
end

local function validate_side_members(name, value, member_validator, level)
  if value.top ~= nil or value.right ~= nil or value.bottom ~= nil or value.left ~= nil then
    if value.top ~= nil then member_validator(name .. '.top', value.top, level) end
    if value.right ~= nil then member_validator(name .. '.right', value.right, level) end
    if value.bottom ~= nil then member_validator(name .. '.bottom', value.bottom, level) end
    if value.left ~= nil then member_validator(name .. '.left', value.left, level) end
    return
  end

  if #value == 2 then
    member_validator(name .. '[1]', value[1], level)
    member_validator(name .. '[2]', value[2], level)
    return
  end

  if #value == 4 then
    member_validator(name .. '[1]', value[1], level)
    member_validator(name .. '[2]', value[2], level)
    member_validator(name .. '[3]', value[3], level)
    member_validator(name .. '[4]', value[4], level)
    return
  end

  Assert.fail(name .. ' must be a number, a keyed table, or contain 2 or 4 values', level or 1)
end

local function validate_corner_members(name, value, member_validator, level)
  if value.topLeft ~= nil or value.topRight ~= nil or
      value.bottomRight ~= nil or value.bottomLeft ~= nil then
    if value.topLeft ~= nil then member_validator(name .. '.topLeft', value.topLeft, level) end
    if value.topRight ~= nil then member_validator(name .. '.topRight', value.topRight, level) end
    if value.bottomRight ~= nil then member_validator(name .. '.bottomRight', value.bottomRight, level) end
    if value.bottomLeft ~= nil then member_validator(name .. '.bottomLeft', value.bottomLeft, level) end
    return
  end

  if #value == 4 then
    member_validator(name .. '[1]', value[1], level)
    member_validator(name .. '[2]', value[2], level)
    member_validator(name .. '[3]', value[3], level)
    member_validator(name .. '[4]', value[4], level)
    return
  end

  Assert.fail(name .. ' must be a number, a keyed table, or contain 4 values', level or 1)
end

function CustomRules.validate_side_quad(name, value, member_validator, level)
  level = level or 1

  if Types.is_number(value) then
    member_validator(name, value, level)
    return
  end

  if Types.is_table(value) then
    validate_side_members(name, value, member_validator, level)
    return
  end

  Assert.fail(name .. ' must be a number or a table', level)
end

function CustomRules.validate_corner_quad(name, value, member_validator, level)
  level = level or 1

  if Types.is_number(value) then
    member_validator(name, value, level)
    return
  end

  if Types.is_table(value) then
    validate_corner_members(name, value, member_validator, level)
    return
  end

  Assert.fail(name .. ' must be a number or a table', level)
end

local function side_quad_validator(member_validator)
  return function(name, value)
    CustomRules.validate_side_quad(name, value, member_validator, 2)
  end
end

local function size_value_validator(allow_content)
  return function(name, value)
    if Types.is_number(value) then return value end
    if value == Constants.SIZE_MODE_FILL then return value end
    if Types.is_percentage(value) then return value end

    if value == Constants.SIZE_MODE_CONTENT then
      if allow_content then return value end
      Assert.fail(name .. ': "content" requires an intrinsic measurement rule', 2)
    end

    Assert.fail(
      name .. ': must be a number, "fill", "content", or a percentage string',
      2
    )
  end
end

function CustomRules.size_value(opts)
  opts = opts or {}
  local allow_content = opts.allow_content == true
  return Rule.custom(size_value_validator(allow_content), rule_opts(opts))
end

function CustomRules.color(opts)
  if opts ~= nil and not uses_rule_opts(opts) then
    opts = { default = opts }
  end
  return Rule.custom(function(name, value)
    local ok, result = pcall(Color.resolve, value)
    if ok then return result end
    Assert.fail(name .. ': ' .. tostring(result), 2)
  end, opts)
end

function CustomRules.opacity(opts)
  if opts ~= nil and not uses_rule_opts(opts) then
    opts = { default = opts }
  end
  return Rule.custom(function(name, value)
    Assert.number(name, value, 2)
    Assert.finite(name, value, 2)
    if value < 0 or value > 1 then
      Assert.fail(name .. ' must be in [0, 1], got ' .. value, 2)
    end
    return value
  end, opts)
end

function CustomRules.finite_number(opts)
  return Rule.custom(finite_number_validator(opts), rule_opts(opts))
end

function CustomRules.non_negative_finite(opts)
  opts = opts or {}
  local validator = finite_number_validator({
    min = 0,
    max = opts.max,
  })
  return Rule.custom(validator, rule_opts(opts))
end

function CustomRules.positive_finite(opts)
  return Rule.custom(positive_finite_validator(opts), rule_opts(opts))
end

function CustomRules.padding(opts)
  return Rule.custom(
    side_quad_validator(CustomRules.validate_non_negative_finite),
    rule_opts(opts)
  )
end

function CustomRules.margin(opts)
  return Rule.custom(
    side_quad_validator(CustomRules.validate_finite_number),
    rule_opts(opts)
  )
end

return CustomRules
