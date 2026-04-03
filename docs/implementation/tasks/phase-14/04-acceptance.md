# Task 04: Acceptance

## Goal

Verify the full integration: flat instance properties, skin values, and token fallbacks all resolve correctly through the cascade and produce correct visual output via `Styling.draw`. Confirm backward compatibility for existing controls.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §4B` — resolution cascade
- `docs/spec/ui-styling-spec.md §10` — skin and token interaction
- `docs/spec/ui-styling-spec.md §11A` — paint order in the draw cycle

## Scope

- No new implementation — this task verifies the work from tasks 01–03
- Requires a LÖVE runtime for visual verification
- Requires existing controls (Button, Label) for backward-compat verification

## Concrete Module Targets

- `lib/ui/core/drawable.lua` — read only
- `lib/ui/render/styling.lua` — read only

## Implementation Guidance

**Resolution cascade cases:**

Verify each tier of the cascade independently:

1. Direct instance property: set `backgroundColor = {0.1, 0.5, 0.9}` on a bare Drawable. Confirm the background is painted without any skin or token involvement.

2. Skin value: configure a skin that provides `backgroundColor` for a specific part. Set no direct instance property. Confirm the skin value is used.

3. Token fallback: configure an active theme token that maps to `backgroundColor`. Set no instance property and no skin for that part. Confirm the token value is used.

4. No value: bare Drawable with no instance property, no skin, no token for `backgroundColor`. Confirm no background is painted and no error is raised.

**Boolean property cascade:**

Set `shadowInset = false` directly on a node. Confirm this value is respected even if the resolver would otherwise return `true` (configure a test skin or token to confirm the priority). The direct `false` must not fall through to the resolver.

**Paint order in the draw cycle:**

A Drawable with `backgroundColor` set plus control content (text, icon) must show the background behind the content. A Drawable with an inset shadow must show the shadow inside the border, behind the control content.

**Backward compatibility:**

- Render a Button using the existing skin token pipeline. It must look identical to before Phase 14.
- Render a Label. It must look identical to before Phase 14.
- Any existing demo screen must render without errors or visual regressions.

**No-op case:**

A bare Drawable with no styling properties drawn through the full draw cycle must produce no visible styling output and no error.

**Statelessness across nodes:**

Draw two Drawables in sequence — one with `backgroundColor` set, one without. The second must not show any background inherited from the first. The ephemeral props table must not leak between nodes.

## Verification Matrix

| Scenario | Expected result |
|---|---|
| Bare Drawable, `backgroundColor = {0.1, 0.5, 0.9}` | Blue background painted |
| Bare Drawable, skin provides `backgroundColor` | Skin color painted |
| Bare Drawable, token provides `backgroundColor` | Token color painted |
| Bare Drawable, no background source | No background, no error |
| `shadowInset = false` on node, skin provides `shadowInset = true` | `false` wins, outer shadow |
| Drawable with background + border + shadow + control content | Correct visual layer order |
| Button, no styling properties | Renders identically to pre-Phase-14 |
| Label, no styling properties | Renders identically to pre-Phase-14 |
| Two nodes: first has background, second has none | Second shows no background |

## Non-Goals

- No migration of existing control backgrounds from `_draw_control` to the styling layer.
- No new skin or token definitions — only existing resolver infrastructure is verified.
- No performance benchmarking.

## Acceptance Checks

- All verification matrix entries produce the expected result.
- No regressions in existing control rendering.
- Boolean `false` instance property is not overridden by resolver in the cascade.
- Ephemeral props table does not leak state between consecutive node draws.
- Phase 14 is considered complete when all Phase 12, 13, and 14 verification items pass together.
