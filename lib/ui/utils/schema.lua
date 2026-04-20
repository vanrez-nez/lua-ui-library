--- Schema — immutable rule map for validating explicit targets
--
-- Schema owns property rules only. It does not bind to, store, or mutate a
-- host during construction. Callers pass the target table when applying
-- defaults or validating values.

local Rule = require('lib.ui.utils.rule')
local Common = require('lib.ui.utils.common')

local Schema = {}
Schema.__index = Schema

--- Creates a Schema with the given rule map.
--- The target being validated is passed later to validate_rule/validate_all.
--- @param  rules  table<string, table>  property name -> Rule descriptor
--- @return Schema
function Schema.create(rules)
  local self = setmetatable({}, Schema)
  self._rules = Common.clone(rules or {})
  return self
end

--- Creates a Schema by composing a base Schema with additional rules.
--- Rules passed in `overrides` replace base rules with the same property name.
--- @param base Schema
--- @param overrides table<string, table>?
--- @return Schema
function Schema.extend(base, overrides)
  local rules = base:get_rules()
  for property, rule in pairs(overrides or {}) do
    rules[property] = rule
  end
  return Schema.create(rules)
end

--- Returns a shallow copy of the internal rule map.
--- Safe to iterate; map mutations do not affect the Schema.
--- @return table<string, table>
function Schema:get_rules()
  return Common.clone(self._rules)
end

--- Returns the Rule descriptor for a named property, or nil if not registered.
--- @param  property  string
--- @return table|nil
function Schema:get_rule(property)
  return self._rules[property]
end

--- Validates one property from the passed target against its rule.
--- Raises on failure.
--- @param property string
--- @param target table
function Schema:validate_rule(property, target)
  local rule = self._rules[property]
  if rule == nil then
    error('schema rule not found: ' .. tostring(property), 2)
  end
  Rule.validate(rule, property, target[property])
end

--- Validates every schema property against values in the passed target.
--- Raises on the first failure (iteration order is unspecified).
--- @param target table
function Schema:validate_all(target)
  for property in pairs(self._rules) do
    self:validate_rule(property, target)
  end
end

--- Applies rule defaults to the passed target.
--- @param target table
--- @param force boolean?  if true, overwrites existing non-nil values
function Schema:set_defaults(target, force)
  for property, rule in pairs(self._rules) do
    if rule.has_default and (force or target[property] == nil) then
      rawset(target, property, rule.default)
    end
  end
end

return Schema
