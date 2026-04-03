# Phase 14 Compliance Review

Source under review: `lib/ui/core/drawable.lua` and `lib/ui/themes/resolver.lua`

Task-set authority:

- `docs/spec/ui-styling-spec.md` §4B and §10 are authoritative for the resolution cascade and skin/token interaction.

Primary findings:

1. The draw cycle in `drawable.lua` has no slot for styling paint.
   Spec anchor: `ui-styling-spec.md §11A`
   Problem: the current `drawable.lua` draw path calls `_draw_control` to render control content. No step precedes it for painting background, border, or shadow based on the flat styling properties introduced in Phase 12. Without a wiring point, `Styling.draw` has nowhere to be called.
   Required addition: insert a `Styling.draw` call before `_draw_control`, with a resolved props table and the node's current bounds.

2. No `STYLING_KEYS` list exists anywhere.
   Spec anchor: `ui-styling-spec.md §4B`
   Problem: no file currently enumerates the 29 styling property names for use in iteration. The resolution cascade requires iterating over all styling keys to build the `props` table. Without a canonical list, any implementation would have to hard-code key names in ad-hoc ways.
   Required addition: define `STYLING_KEYS` as a module-level constant listing all 29 property names from Phase 12.

3. The resolver infrastructure exists but has no callers for styling properties.
   Spec anchor: `ui-styling-spec.md §10`, `ui-foundation-spec.md §8.3`
   Problem: `lib/ui/themes/resolver.lua` implements skin, token, and default resolution, but it is currently called only for control-specific property names. Styling property names (`backgroundColor`, `borderWidthTop`, etc.) are not passed through the resolver by any code. The resolver is capable of resolving any property — it just has no callers for the new names.
   Required addition: call the resolver for each styling key in the props assembly step, as the fallback when the instance-level property is not set.

4. Boolean properties in the resolution cascade require explicit nil checking.
   Spec anchor: `ui-styling-spec.md §4B`
   Problem: the simple pattern `node[key] or resolver.resolve(...)` fails for boolean properties where the value is `false` — `false or resolver.resolve(...)` would incorrectly fall through to the resolver even though the instance property is explicitly set to `false`. `shadowInset = false` is a documented valid value that must not trigger a resolver lookup.
   Required normalization: for boolean-typed properties (`backgroundRepeatX`, `backgroundRepeatY`, `shadowInset`), use an explicit nil check rather than the `or` idiom.

5. The bounds format passed to `Styling.draw` must be confirmed.
   Spec anchor: `docs/implementation/phase-13-styling-renderer.md` — `bounds` shape
   Problem: `Styling.draw` expects `{ x, y, width, height }`. The drawable's current draw path works with position and size values but they may be stored in a different format. The correct values and their sources within `drawable.lua` must be identified before wiring.
   Required normalization: construct the bounds table from the node's layout-resolved position and size fields when calling `Styling.draw`.

Secondary notes:

- The resolver may not be called for styling properties that have library default values defined — the library defaults table may need to be extended for any styling property that has a documented default (currently, most styling properties have no library default — nil means "not set"). Review the defaults table as part of task 02.
- Controls that currently draw their own backgrounds via `_draw_control` (e.g., buttons via `fillColor` skin token) continue to work unchanged. The new styling layer prepends, not replaces.
- No new skin or token values are introduced by this phase — that is a migration task for a later pass.
