# Task 02: Props Assembly And Resolution Cascade

## Goal

Implement the props assembly function that produces the resolved `props` table passed to `Styling.draw`. For each key in `STYLING_KEYS`, resolve the value following the four-level cascade: instance property → skin → token → library default. Handle boolean properties correctly with explicit nil checks rather than the `or` idiom.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §4B` — four-level resolution cascade
- `docs/spec/ui-styling-spec.md §10` — skin and token interaction with styling properties

## Scope

- Modify `lib/ui/render/styling.lua` or `lib/ui/core/drawable.lua`
- Add a function `assemble_styling_props(node, resolver_context)` that returns the resolved props table
- This function is called by the draw cycle wiring in Task 03

## Concrete Module Targets

- `lib/ui/render/styling.lua` — preferred location for `assemble_styling_props` (co-located with `STYLING_KEYS`)

## Implementation Guidance

**Function signature:**

`assemble_styling_props(node, resolver_context)` returns a plain table with resolved values for all 29 styling keys. The `resolver_context` is whatever shape `resolver.resolve` expects (part name, control type, etc.) — pass through from the draw cycle caller.

**General case (non-boolean properties):**

```
props[key] = node[key] or resolver.resolve({ property = key, context = resolver_context })
```

If the resolver returns nil for a property that has no skin, token, or library default value, the entry in `props` will be nil. `Styling.draw` handles nil entries as "not set" — this is correct behavior.

**Boolean properties — explicit nil check:**

For `backgroundRepeatX`, `backgroundRepeatY`, and `shadowInset`, the `or` pattern fails when the value is `false`. Use:

```
local v = node[key]
if v == nil then
    v = resolver.resolve({ property = key, context = resolver_context })
end
props[key] = v
```

This ensures `shadowInset = false` on a node is not overridden by a resolver result.

**Iteration:**

```
local props = {}
for _, key in ipairs(STYLING_KEYS) do
    -- per-key resolution (general or boolean case)
end
return props
```

**Library defaults:**

The spec does not document default values for most styling properties — nil is the correct default for almost all of them, meaning "not set." Verify whether the library defaults table defines any styling property defaults. If none are defined, the resolver falls through to nil for all styling keys, which is correct.

If a library default is needed for any property (for example, `borderStyle = "smooth"` as a default), add it to the defaults table rather than hardcoding it in this function.

**Resolver contract:**

The resolver already handles unknown keys gracefully (returns nil). No special handling is needed for keys that have no skin, token, or default entry.

## Required Behavior

- Node with `backgroundColor = {1, 0, 0, 1}` set directly → `props.backgroundColor == {1, 0, 0, 1}`
- Node with no `backgroundColor` but skin providing `backgroundColor` → `props.backgroundColor` equals the skin value
- Node with no direct property and no skin but a token for `backgroundColor` → `props.backgroundColor` equals the token value
- Node with no property, skin, token, or default for `backgroundColor` → `props.backgroundColor == nil`
- Node with `shadowInset = false` explicitly → `props.shadowInset == false` (not overridden by resolver)
- Node with `backgroundRepeatX = false` explicitly → `props.backgroundRepeatX == false`
- Result table has exactly the keys present in `STYLING_KEYS` that resolved to non-nil values

## Non-Goals

- No caching of the props table on the node. The function always builds a fresh table.
- No validation of resolved values — values from skin or tokens are trusted to match the schema.
- No partial resolution — all 29 keys are iterated every call.

## Acceptance Checks

- Direct instance property takes priority over resolver result.
- Boolean `false` is not treated as absent — resolver is not called when instance property is `false`.
- Nil resolver result produces nil in `props` (not an error).
- All 29 keys are iterated — no key is skipped.
- Function returns a plain table, not the node itself.
