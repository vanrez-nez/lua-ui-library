# Phase 14 Task Set

Source implementation document for this phase:

- `docs/implementation/phase-14-styling-integration.md`

Authority rules for this phase:

- `docs/spec/ui-styling-spec.md` §4B is authoritative for the four-level resolution cascade: direct instance property → skin value → token fallback → library default.
- `docs/spec/ui-styling-spec.md` §10 is authoritative for how skin and token values interact with the flat styling properties.
- `docs/spec/ui-foundation-spec.md` §8.3 is authoritative for the customization mechanism used by the resolver infrastructure.
- `docs/spec/ui-styling-spec.md` §11A is authoritative for paint order, which must be preserved in the draw cycle integration.

Settled decisions that control this task set:

- `Styling.draw` is called unconditionally for every Drawable node. If no props resolve, it paints nothing. No "has styling" flag or skip guard is added at the draw cycle level.
- The resolved `props` table is ephemeral — it is rebuilt each draw pass. No per-node caching of resolved props is introduced in this phase.
- `STYLING_KEYS` is a single flat list of all 29 property names introduced in Phase 12. It lives as a module-level constant in the file where it is most useful (co-located with the resolution logic).
- Resolution for each key: `node[key] or resolver.resolve({ property = key, ... })`. This is correct because nil in Lua is falsy. A value of `false` as a boolean property (e.g., `shadowInset = false`) is a special case — raw `node[key]` access must use `rawget` or an explicit nil check rather than `or` for boolean properties. See task 02 for the precise pattern.
- `Styling.draw` is inserted before `_draw_control` in the draw cycle. It does not replace or modify `_draw_control`. Existing controls are unaffected.
- No per-control migration of existing skin-driven backgrounds into the new styling system in this phase. That migration is a subsequent pass.
- Phases 12 and 13 must both be complete before this phase can be fully verified.

Implementation conventions for every task in this phase:

- All existing behavior of `drawable.lua` must be preserved. The new code is additive.
- Use `Assert.that` or `error(msg, 2)` for any new argument guards.
- The `bounds` table passed to `Styling.draw` must match the format expected by Phase 13: `{ x, y, width, height }`.

Task order:

1. `00-compliance-review.md`
2. `01-styling-keys-constant.md`
3. `02-props-assembly.md`
4. `03-draw-cycle-wiring.md`
5. `04-acceptance.md`
