# Task 01: Module Structure And Paint Order

## Goal

Create `lib/ui/render/styling.lua` with the `Styling.draw` entry point and implement the paint order dispatcher. At the end of this task the module exists, loads without error, accepts the correct arguments, and calls paint steps in the correct sequence — even if those steps are stubs returning immediately.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §11A` — paint order: outer shadow → background → border → inset shadow

## Scope

- Create `lib/ui/render/styling.lua`
- Implement `Styling.draw(props, bounds, graphics)` as the module's only public function
- Implement the four paint step dispatch calls in the correct sequence
- Paint step functions (`_paint_outer_shadow`, `_paint_background`, `_paint_border`, `_paint_inset_shadow`) may be stubs that return immediately — they are filled in by subsequent tasks

## Concrete Module Targets

- New file: `lib/ui/render/styling.lua`

## Implementation Guidance

**Module shape:**

The module returns a plain table `{ draw = function }`. No class, no metatable, no constructor. A single require gives the caller access to `Styling.draw`.

**`Styling.draw(props, bounds, graphics)` signature:**

- `props`: a table of resolved styling properties. May be empty. Must not be nil — guard with an assertion.
- `bounds`: a table with numeric fields `x`, `y`, `width`, `height`. Must not be nil. Must have all four fields — guard with assertions.
- `graphics`: the graphics adapter. Must not be nil.

Argument guards should use `Assert.that` or `error(msg, 2)` and point to the caller's line.

**Paint order:**

Call the four steps in this exact sequence:

1. `_paint_outer_shadow(props, bounds, graphics, resolved_radii)` — only when `props.shadowInset == false` (or `props.shadowInset == nil` with a shadow color present)
2. `_paint_background(props, bounds, graphics, resolved_radii)`
3. `_paint_border(props, bounds, graphics, resolved_radii)`
4. `_paint_inset_shadow(props, bounds, graphics, resolved_radii)` — only when `props.shadowInset == true`

`resolved_radii` is a table produced by the corner radius resolution step (Task 02). In this task, pass a stub radii table with all four values set to `0` — the real resolution is implemented in Task 02 and wired back here.

**Early return:**

If `props` is an empty table (no keys set), the function may still call all four steps — each step is responsible for its own skip condition when properties are absent. Do not add a top-level "nothing to paint" short-circuit in this task.

**State management:**

At the start of `Styling.draw`, save the current graphics color. At the end, restore it. Specific line state (style, join, miter limit) is saved and restored in the border and shadow steps.

## Required Behavior

- `Styling.draw({}, {x=0, y=0, width=100, height=50}, graphics)` → no error, no paint
- `Styling.draw(nil, {x=0, y=0, width=100, height=50}, graphics)` → hard failure (nil props)
- `Styling.draw({}, nil, graphics)` → hard failure (nil bounds)
- `Styling.draw({}, {x=0, y=0, width=100, height=50}, nil)` → hard failure (nil graphics)
- `Styling.draw({}, {x=0, y=0, width=100}, graphics)` → hard failure (missing `height`)
- Module loads without error: `require("lib/ui/render/styling")` succeeds

## Non-Goals

- No actual paint output in this task — all four paint steps are stubs.
- No corner radius resolution in this task — stubs use zero radii.
- No source selection logic.

## Acceptance Checks

- Module loads without error.
- `Styling.draw` is accessible on the returned table.
- All four guard cases raise errors as documented.
- Calling `Styling.draw` with valid arguments and empty props produces no error and no visible output.
- Paint steps are called in the order: outer shadow → background → border → inset shadow (verifiable by adding temporary trace output to stubs).
