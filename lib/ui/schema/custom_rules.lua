local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Rule = require('lib.ui.utils.rule')
local Constants = require('lib.ui.core.constants')
local Color = require('lib.ui.render.color')

local CustomRules = {}

local SIDE_KEYS   = {
  Constants.EDGE_LEFT,
  Constants.EDGE_RIGHT,
  Constants.EDGE_TOP,
  Constants.EDGE_BOTTOM
}

local CORNER_KEYS = {
  Constants.TOP_LEFT,
  Constants.TOP_RIGHT,
  Constants.BOTTOM_RIGHT,
  Constants.BOTTOM_LEFT
}

local function validate_side(name, value)
  Assert.table(name, value, 2)
  for _, k in ipairs(SIDE_KEYS) do
    if value[k] ~= nil then
      for _, kk in ipairs(SIDE_KEYS) do
        if value[kk] ~= nil then Assert.number(name .. '.' .. kk, value[kk], 2) end
      end
      return
    end
  end
  if #value == 2 or #value == 4 then
    for i = 1, #value do Assert.number(name .. '[' .. i .. ']', value[i], 2) end
    return
  end
  Assert.fail(name .. ': must be a keyed table or contain 2 or 4 values', 2)
end

local function validate_corner(name, value)
  Assert.table(name, value, 2)
  for _, k in ipairs(CORNER_KEYS) do
    if value[k] ~= nil then
      for _, kk in ipairs(CORNER_KEYS) do
        if value[kk] ~= nil then Assert.number(name .. '.' .. kk, value[kk], 2) end
      end
      return
    end
  end
  if #value == 4 then
    for i = 1, 4 do Assert.number(name .. '[' .. i .. ']', value[i], 2) end
    return
  end
  Assert.fail(name .. ': must be a keyed table or contain 4 values', 2)
end

local function validate_padding(name, value)
  if Types.is_number(value) then
    Assert.range(name, value, 0, nil, 2)
    return
  end
  validate_side(name, value)
  for _, k in ipairs(SIDE_KEYS) do
    if value[k] ~= nil then Assert.range(name .. '.' .. k, value[k], 0, nil, 2) end
  end
end

local function validate_margin(name, value)
  if Types.is_number(value) then return end
  validate_side(name, value)
end

local function validate_size(name, value, allow_content)
  if Types.is_number(value)              then return end
  if value == Constants.SIZE_MODE_FILL   then return end
  if Types.is_percentage(value)          then return end
  if value == Constants.SIZE_MODE_CONTENT then
    if allow_content then return end
    Assert.fail(name .. ': "content" requires an intrinsic measurement rule', 2)
  end
  Assert.fail(name .. ': must be a number, "fill", "content", or a percentage string', 2)
end

local function validate_color(name, value)
  local ok, result = pcall(Color.resolve, value)
  if not ok then Assert.fail(name .. ': ' .. tostring(result), 2) end
end

function CustomRules.size_value(opts)
  opts = opts or {}
  local allow_content = opts.allow_content == true
  return Rule.custom(function(name, value)
    validate_size(name, value, allow_content)
  end, { optional = opts.optional, default = opts.default })
end

function CustomRules.color(opts)
  if opts ~= nil and not Types.is_table(opts) then opts = { default = opts } end
  return Rule.custom(validate_color, opts)
end

function CustomRules.padding(opts)
  return Rule.custom(validate_padding, opts)
end

function CustomRules.margin(opts)
  return Rule.custom(validate_margin, opts)
end

function CustomRules.corner_quad(opts)
  return Rule.custom(validate_corner, opts)
end

return CustomRules