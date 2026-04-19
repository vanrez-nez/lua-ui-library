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
  local rule_opts = {
    optional = opts.optional,
    default = opts.default,
    set = opts.set,
  }
  return Rule.custom(size_value_validator(allow_content), rule_opts)
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

return CustomRules
