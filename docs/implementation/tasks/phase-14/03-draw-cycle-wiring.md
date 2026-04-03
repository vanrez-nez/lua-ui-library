# Task 03: Draw Cycle Wiring

## Goal

Modify `lib/ui/core/drawable.lua` to call `Styling.draw` before `_draw_control`. Assemble the resolved props table using `assemble_styling_props`, construct the `bounds` table from the node's layout values, and pass both to `Styling.draw`. Preserve all existing draw cycle behavior.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §11A` — paint order: styling layer precedes control content
- `docs/spec/ui-foundation-spec.md §8.3` — customization mechanism compatibility

## Scope

- Modify `lib/ui/core/drawable.lua`
- Add `require` for `lib/ui/render/styling.lua`
- Add `assemble_styling_props` call and `Styling.draw` call in the draw path before `_draw_control`

## Concrete Module Targets

- `lib/ui/core/drawable.lua` — modified only

## Implementation Guidance

**Require:**

At the top of `drawable.lua`, require `lib/ui/render/styling.lua` as `Styling`.

**Draw path location:**

Find the existing draw method in `drawable.lua`. The insertion point is immediately before the `_draw_control(graphics)` call (or its equivalent). The new code must not be placed inside any conditional that would prevent it from running — it must execute for every Drawable node draw.

**Bounds construction:**

The `bounds` table passed to `Styling.draw` must be `{ x, y, width, height }` in screen coordinates. Construct it from the node's resolved position and layout size. Use the same coordinate values that `_draw_control` uses as its drawing origin and dimensions.

**Props assembly:**

Call `assemble_styling_props(self, resolver_context)` where `resolver_context` is the same context that the existing resolver calls in `drawable.lua` use (part name, skin key, etc.). Inspect the existing resolver call site to determine the correct context shape.

**Full insertion sequence:**

```
-- existing: resolve inherited effect chain and skin assets
-- new: local props = assemble_styling_props(self, resolver_context)
-- new: Styling.draw(props, bounds, self._graphics)
-- existing: _draw_control(self._graphics)
-- existing: descendant composition
```

**Backward compatibility:**

Do not remove or modify any existing code in the draw path. The new lines are strictly additive. Existing controls that draw their own backgrounds via `_draw_control` continue to do so — the styling layer paints before them, and if a control already paints a background, both will be visible (the styling background will be behind it). That visual redundancy is acceptable in this phase; per-control migration is out of scope.

**No skip guard:**

Do not add a check like "if node has any styling props, then call Styling.draw." Call it unconditionally. `Styling.draw` handles the empty case without painting anything.

## Required Behavior

- A bare `Drawable` with `backgroundColor = {0.1, 0.5, 0.9}` set directly → background is painted before control content
- A bare `Drawable` with no styling properties → `Styling.draw` is called with an empty props table, nothing is painted, no error
- A `Button` with its existing skin token pipeline → renders unchanged (the styling layer paints nothing because no styling properties are set on the button, and its own `_draw_control` still runs)
- Draw cycle order: styling paint (outer shadow, background, border, inset shadow) → control content → descendants

## Non-Goals

- No per-control migration of existing background painting from `_draw_control` to the styling layer.
- No change to the descendant composition or the existing effect chain setup.
- No performance optimization of the props assembly call.

## Acceptance Checks

- `Styling.draw` is called on every Drawable node during the draw pass.
- Styling paint visually precedes control content (background is behind text, icons, etc.).
- Existing controls (Button, Label, etc.) render identically to before this change.
- A bare Drawable with `backgroundColor` set shows a filled background.
- No error when a Drawable with no styling properties is drawn.
