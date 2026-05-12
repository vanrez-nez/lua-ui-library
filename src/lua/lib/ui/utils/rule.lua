--- Rule — declarative validation rule descriptors
--
-- A Rule is a plain table describing how a single value should be validated
-- and resolved. Rules are stateless descriptors — they carry no value
-- themselves. Pass them to Rule.validate() or bind them to a host via Schema.
--
-- Every rule descriptor shares three base fields:
--   kind        string   identifies which validator to dispatch to
--   optional    boolean  if true, nil is accepted without error
--   has_default boolean  if true, Rule.resolve() returns `default` for nil
--   default     any      the fallback value (only meaningful when has_default)
--
-- Usage:
--   local r = Rule.number({ min = 0, max = 1, default = 0.5 })
--   Rule.validate(r, 'alpha', 0.8)   -- ok
--   Rule.validate(r, 'alpha', 2.0)   -- error: out of range
--
--   local v = Rule.resolve(r, nil)   -- returns 0.5

local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local Rule = {}

local function check_opts(opts, allowed)
  for k in pairs(opts) do
    if not allowed[k] then
      Assert.fail('Rule: unknown option "' .. tostring(k) .. '"', 3)
    end
  end
end

local BASE_OPTS = {
  optional = true,
  default = true,
}

local validators = {}

validators.string = function(r, name, v)
  Assert.string(name, v, 2)
  if r.non_empty and #v == 0 then Assert.fail(name .. ': must not be empty', 2) end
  if r.min_len then Assert.range(name, #v, r.min_len, nil, 2) end
  if r.max_len then Assert.range(name, #v, nil, r.max_len, 2) end
  if r.pattern then Assert.pattern(name, v, r.pattern, 2) end
end

validators.number = function(r, name, v)
  Assert.number(name, v, 2)
  if r.finite then Assert.finite(name, v, 2) end
  if r.integer then Assert.integer(name, v, 2) end
  Assert.range(name, v, r.min, r.max, 2)
end

validators.boolean = function(_, name, v)
  Assert.boolean(name, v, 2)
end

validators.table = function(r, name, v)
  Assert.table(name, v, 2)
  if r.items then
    for key, item in pairs(v) do
      Rule.validate(r.items, name .. '[' .. tostring(key) .. ']', item)
    end
  end
end

validators.func = function(_, name, v)
  Assert.func(name, v, 2)
end

--- Accepts only values present in the pre-built `allowed` lookup set.
validators.enum = function(r, name, v)
  if not r.allowed[v] then Assert.fail(name .. ': must be one of: ' .. r.display, 2) end
end

--- Accepts only one exact non-nil value.
validators.literal = function(r, name, v)
  if v ~= r.value then Assert.fail(name .. ': must be ' .. r.display, 2) end
end

validators.custom = function(r, name, v)
  r.fn(name, v, 2)
end

--- Passes if the value satisfies ANY inner rule (first-match, short-circuit).
validators.any_of = function(r, name, v)
  for _, inner in ipairs(r.rules) do
    if pcall(Rule.validate, inner, name, v) then return end
  end
  Assert.fail(name .. ': did not match any allowed type', 2)
end

--- Passes only if the value satisfies ALL inner rules.
validators.all_of = function(r, name, v)
  for _, inner in ipairs(r.rules) do Rule.validate(inner, name, v) end
end


validators.instance = function(r, name, v)
  Assert.is_instance(name, v, r.class, r.class_name, 2)
end

--- Validates `value` against `rule`, raising on failure.
--- nil is accepted when the rule is optional or has a default; otherwise raises.
--- @param rule   table   a Rule descriptor
--- @param name   string  field name used in error messages
--- @param value  any     the value to validate
function Rule.validate(rule, name, value)
  if value == nil then
    if not rule.optional and not rule.has_default then
      Assert.fail(name .. ': is required', 2)
    end
    return
  end
  validators[rule.kind](rule, name, value)
end

--- Resolves an effective value from a rule and raw input.
--- Returns `value` if non-nil, `rule.default` if the rule has one, or nil.
--- Returns nil + 'is required' as a second value if the rule is neither
--- optional nor defaulted — the caller decides how to surface the error.
--- @param  rule   table  a Rule descriptor
--- @param  value  any    the raw input (may be nil)
--- @return any, string?
function Rule.resolve(rule, value)
  if value ~= nil then return value end
  if rule.has_default then return rule.default end
  if rule.optional then return nil end
  return nil, 'is required'
end

--- Creates a string rule.
--- @param opts table?
---   optional  boolean
---   default   string
---   non_empty boolean  reject empty strings
---   min_len   number   minimum character count
---   max_len   number   maximum character count
---   pattern   string   Lua pattern the value must match
--- @return table
function Rule.string(opts)
  opts = opts or {}
  check_opts(opts, {
    optional = true,
    default = true,
    non_empty = true,
    min_len = true,
    max_len = true,
    pattern = true,
  })
  return {
    kind = 'string',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
    non_empty = opts.non_empty,
    min_len = opts.min_len,
    max_len = opts.max_len,
    pattern = opts.pattern,
  }
end

--- Creates a number rule.
--- Note: `finite` defaults to true — set to false explicitly to allow inf/nan.
--- @param opts table?
---   optional  boolean
---   default   number
---   min       number   inclusive lower bound
---   max       number   inclusive upper bound
---   integer   boolean  reject non-integer values
---   finite    boolean  reject inf/nan (default true)
--- @return table
function Rule.number(opts)
  opts = opts or {}
  check_opts(opts, {
    optional = true,
    default = true,
    min = true,
    max = true,
    integer = true,
    finite = true,
  })
  return {
    kind = 'number',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
    min = opts.min,
    max = opts.max,
    integer = opts.integer or false,
    finite = opts.finite ~= false,
  }
end

--- Creates a boolean rule.
--- Shorthand: Rule.boolean(true) == Rule.boolean({ default = true }).
--- @param opts table|boolean|nil
--- @return table
function Rule.boolean(opts)
  if not Types.is_table(opts) then opts = { default = opts } end
  check_opts(opts, BASE_OPTS)
  return {
    kind = 'boolean',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
  }
end

--- Creates a table rule.
--- @param opts table?  optional, default, items
--- @return table
function Rule.table(opts)
  opts = opts or {}
  check_opts(opts, {
    optional = true,
    default = true,
    items = true,
  })
  return {
    kind = 'table',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
    items = opts.items,
  }
end

--- Creates a function rule. Accepts any callable value.
--- Commonly used for callbacks and event handlers.
--- Example:
---   on_press = Rule.func({ optional = true })
--- @param opts table?  optional, default
--- @return table
function Rule.func(opts)
  opts = opts or {}
  check_opts(opts, BASE_OPTS)
  return {
    kind = 'func',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
  }
end

--- Creates an enum rule from an ordered list of allowed string values.
--- Membership is tested via a pre-built lookup set for O(1) checks.
--- Example:
---   Rule.enum({ 'left', 'center', 'right' }, { default = 'left' })
--- @param values string[]  allowed values
--- @param opts table?    optional, default
--- @return table
function Rule.enum(values, opts)
  opts = opts or {}
  check_opts(opts, BASE_OPTS)
  local allowed = {}
  for _, v in ipairs(values) do allowed[v] = true end
  return {
    kind = 'enum',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
    allowed = allowed,
    display = table.concat(values, ', '),
  }
end

--- Creates a literal rule for one exact non-nil value.
--- Use `optional = true` to accept nil; nil literals are not supported.
--- Example:
---   Rule.literal('indeterminate')
--- @param value any  exact value accepted by the rule; must not be nil
--- @param opts table?    optional, default
--- @return table
function Rule.literal(value, opts)
  if value == nil then
    Assert.fail('Rule.literal: nil literal is not supported; use optional = true', 2)
  end
  opts = opts or {}
  check_opts(opts, BASE_OPTS)
  return {
    kind = 'literal',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
    value = value,
    display = tostring(value),
  }
end

-- Rule.instance(class, class_name, opts)
--- @param class table the class to check against
--- @param class_name string  used in error messages
--- @param opts table?  optional, default
function Rule.instance(class, class_name, opts)
  opts = opts or {}
  check_opts(opts, BASE_OPTS)
  return {
    kind = 'instance',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
    class = class,
    class_name = class_name,
  }
end

--- Rule.custom(fn, opts)
--- @param fn custom validator function receiving name, value and level as args
function Rule.custom(fn, opts)
  opts = opts or {}
  check_opts(opts, BASE_OPTS)
  return {
    kind = 'custom',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
    fn = fn,
  }
end

--- Derives a copy of an existing rule promoted to optional with no default.
--- Useful for reusing constraints without re-declaring them.
--- Example:
---   local base = Rule.number({ min = 0, max = 100 })
---   local opt  = Rule.optional(base)   -- same constraints, nil accepted
--- @param  rule  table  any Rule descriptor
--- @return table
function Rule.optional(rule)
  local r = {}
  for k, v in pairs(rule) do r[k] = v end
  r.optional = true
  r.has_default = false
  r.default = nil
  return r
end

--- Creates a composite rule that passes if the value satisfies ANY inner rule.
--- Rules are tried in order; the first success short-circuits.
--- Example:
---   Rule.any_of({ Rule.number(), Rule.string() })
--- @param rules  table[]  list of Rule descriptors
--- @param opts   table?   optional, default
--- @return table
function Rule.any_of(rules, opts)
  opts = opts or {}
  check_opts(opts, BASE_OPTS)
  return {
    kind = 'any_of',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
    rules = rules,
  }
end

--- Creates a composite rule that passes only if the value satisfies ALL inner rules.
--- All rules are evaluated regardless of prior failures.
--- Example:
---   Rule.all_of({ Rule.string(), Rule.string({ pattern = '^%a+$' }) })
--- @param rules  table[]  list of Rule descriptors
--- @param opts   table?   optional, default
--- @return table
function Rule.all_of(rules, opts)
  opts = opts or {}
  check_opts(opts, BASE_OPTS)
  return {
    kind = 'all_of',
    optional = opts.optional or false,
    has_default = opts.default ~= nil,
    default = opts.default,
    rules = rules,
  }
end

return Rule
