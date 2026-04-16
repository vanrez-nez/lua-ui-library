--- Schema — binds a Rule set to a host table for validation and defaulting
--
-- Schema couples a plain table (the "host") with a map of Rule descriptors,
-- creating one Binding per property. The host owns its values; Schema
-- operates on them in-place through the bindings.
--
-- Typical lifecycle:
--   1. Schema.create(host, rules)   attach rules to the host at construction
--   2. schema:set_defaults()        write missing values from rule defaults
--   3. schema:validate()            assert all properties are well-formed
--   4. schema:copy_from(other)      merge a parent/mixin's bindings in
--
-- Usage:
--   local host = { width = '50%' }
--
--   local schema = Schema.create(host, {
--     width  = Rule.size_value({ default = 'fill' }),
--     height = Rule.size_value({ default = 'fill' }),
--     label  = Rule.string({ optional = true }),
--     alpha  = Rule.number({ min = 0, max = 1, default = 1 }),
--   })
--
--   schema:set_defaults()   -- host.height = 'fill', host.alpha = 1
--   schema:validate()       -- ok; host.width '50%' passes size_value
--
--   host.alpha = 2
--   schema:validate()       -- error: alpha out of range [0, 1]

local Rule   = require('lib.ui.utils.rule')
local Common = require('lib.ui.utils.common')

local Binding = {}
Binding.__index = Binding

--- Validates the current value of this property on the host.
--- Raises if the value fails the rule. nil is accepted for optional/defaulted rules.
function Binding:validate()
  Rule.validate(self.rule, self.property, self.host[self.property])
end

--- Writes the rule's default value to the host property.
--- @param force boolean?  if true, overwrites even a non-nil value (default false)
function Binding:set_default(force)
  if self.rule.has_default and (force or self.host[self.property] == nil) then
    self.host[self.property] = self.rule.default
  end
end

local Schema = {}
Schema.__index = Schema

--- Creates a Schema bound to `host` with the given rule map.
--- One Binding is created per property; the host is not mutated yet.
--- Call set_defaults() and validate() explicitly after construction.
--- @param  host   table                 the table whose properties will be managed
--- @param  rules  table<string, table>  property name → Rule descriptor
--- @return Schema
function Schema.create(host, rules)
  local self = setmetatable({}, Schema)
  self._host = host
  self._bindings = {}
  for property, rule in pairs(rules) do
    self._bindings[property] = setmetatable({
      property = property,
      rule = rule,
      host = host,
    }, Binding)
  end
  return self
end

--- Returns a shallow copy of the internal bindings map.
--- Safe to iterate; mutations do not affect the Schema.
--- @return table<string, Binding>
function Schema:get_bindings()
  return Common.clone(self._bindings)
end

--- Returns the Binding for a named property, or nil if not registered.
--- @param  name  string
--- @return Binding|nil
function Schema:get_rule(name)
  return self._bindings[name]
end

--- Validates every bound property against its rule.
--- Raises on the first failure (iteration order is unspecified).
function Schema:validate()
  for _, binding in pairs(self._bindings) do
    binding:validate()
  end
end

--- Applies rule defaults to the host for every binding.
--- @param force boolean?  if true, overwrites existing non-nil values (default false)
function Schema:set_defaults(force)
  for _, binding in pairs(self._bindings) do
    binding:set_default(force)
  end
end

--- Merges bindings from another Schema into this one.
--- Useful for composing a child schema with a parent's or mixin's rules.
--- @param schema     Schema   source schema to copy bindings from
--- @param overwrite  boolean? if true, existing bindings are replaced (default false)
function Schema:copy_from(schema, overwrite)
  local bindings = schema:get_bindings()
  self._bindings = Common.merge(self._bindings, bindings, false, overwrite)
end

return Schema