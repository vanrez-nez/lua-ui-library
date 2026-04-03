# Phase 14: Styling Draw Cycle Integration

## Purpose

Wire the styling paint pipeline (Phase 13) into the existing draw cycle. Implement the full property resolution cascade so that flat instance properties, skin values, token fallbacks, and library defaults all participate correctly per the spec. After this phase, any Drawable or control can be fully styled through the flat property surface without touching the skin or token system.

## Authority

- `docs/spec/ui-styling-spec.md` §4B Styling Resolution Model
- `docs/spec/ui-styling-spec.md` §10 Skin, Tokens, And Styling
- `docs/spec/ui-foundation-spec.md` §8.3 Customization Mechanism

This document is sequencing and scoping context only.

---

## Scope

### Files Modified

- `lib/ui/core/drawable.lua` — call `Styling.draw` in the draw cycle
- `lib/ui/render/styling.lua` — add property resolution helper (or co-locate in drawable)

---

## Resolution Cascade

For each styling property, resolution follows the spec §4B precedence order:

```
1. direct instance property (e.g., node.backgroundColor)
2. resolved skin value for the same property
3. active token or theme-provided fallback
4. library default fallback when documented
```

This maps to the existing `resolver.lua` infrastructure:

```
resolved = node.backgroundColor                                    -- level 1
  or resolver.resolve({ part="root", property="backgroundColor", ... })  -- levels 2-4
```

Level 1 is a direct table read from the Drawable instance — already possible after Phase 12.

Levels 2–4 are already implemented by `lib/ui/themes/resolver.lua`. The resolver returns the skin-provided value if the property exists in the skin table, otherwise falls through to active theme token, otherwise falls through to the library default table.

### Assembled Props Table

Before calling `Styling.draw`, assemble a resolved props table for all styling properties:

```lua
local props = {}
for _, key in ipairs(STYLING_KEYS) do
    props[key] = node[key] or resolver.resolve({ property = key, ... })
end
```

`STYLING_KEYS` is the full list of styling properties introduced in Phase 12. This table is assembled once per draw pass and passed to `Styling.draw`.

---

## Draw Cycle Integration

In `lib/ui/core/drawable.lua`, modify the draw path to call `Styling.draw` before `_draw_control`:

```
-- existing: resolve inherited effect chain and skin assets
-- new step: assemble resolved styling props
-- new step: Styling.draw(props, bounds, graphics)  ← outer shadow, background, border, inset shadow
-- existing: _draw_control(graphics)               ← control content
-- existing: descendant composition
```

This enforces the spec paint order:
1. outer shadow — from `Styling.draw`
2. background — from `Styling.draw`
3. border — from `Styling.draw`
4. inset shadow — from `Styling.draw`
5. content and descendants — from the existing draw cycle

No changes to the existing `_draw_control` dispatch are required. Styling is prepended, not embedded.

---

## Backward Compatibility

Controls that currently render their own background via `_draw_control` (e.g., button fills via skin `fillColor` tokens) will still work after this phase — their token-driven colors continue to resolve through the skin/resolver path and are included in the resolved `props` table passed to `Styling.draw`.

The only behavioral change is that styling-driven paint now precedes control content paint, which is the correct order per the spec. Controls that were painting background inside `_draw_control` may need to stop doing so once their skin values are migrated to the new styling properties.

That migration is out of scope for this phase. This phase establishes the integration point; per-control migration happens in a subsequent pass.

---

## Key Normalizations

- `Styling.draw` is called unconditionally for every Drawable node. If no styling properties resolve, it paints nothing.
- The resolved `props` table is ephemeral — it is not cached on the node and is rebuilt each draw pass. Caching strategy is an implementation optimization not required by this phase.
- The phase does not remove any existing rendering behavior from controls. It prepends the new styling layer.

---

## Verification

- A bare `Drawable` with `backgroundColor = {0.1, 0.5, 0.9}` set directly → paints background without touching skin or tokens
- A bare `Drawable` with no direct properties but a skin providing `backgroundColor` → skin value used
- A bare `Drawable` with no direct properties and no skin but a theme token for `backgroundColor` → token value used
- A bare `Drawable` with none of the above → nothing painted, no errors
- A `Button` with its existing skin token pipeline → renders unchanged (backward compatible)
- `Styling.draw` called with empty `props` → no paint, no errors
