# Task 01: Numeric RGBA And Range Detection

## Goal

Implement the `Color.resolve` entry point and handle the two numeric RGBA input forms: passthrough `[0, 1]` tables and auto-detected `[0, 255]` tables. Establish the module file and the hard-failure error contract.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §5.3` — numeric RGBA sequential table form
- `docs/spec/ui-styling-spec.md §5.4` — `[0, 255]` range detection and conversion
- `docs/spec/ui-styling-spec.md §13` — hard-failure cases: component exceeding 255, non-integer in detected range

## Scope

- Create `lib/ui/render/color.lua`
- Implement `Color.resolve(input)` dispatcher skeleton
- Implement numeric table detection and routing
- Implement `[0, 1]` passthrough with alpha defaulting to `1`
- Implement `[0, 255]` detection, integer validation, divide-by-255 conversion
- Hard-fail on mixed-scale input and on any component exceeding `255`

## Concrete Module Targets

- New file: `lib/ui/render/color.lua`

## Implementation Guidance

- `Color.resolve(input)` is the only public function. Route on input type: table → numeric handler, string → handled in later tasks.
- For table inputs, iterate components `[1]` through `[3]` (and `[4]` if present) to determine range.
- `[0, 1]` detection: all components are `≤ 1`. Return `{ input[1], input[2], input[3], input[4] or 1 }`.
- `[0, 255]` detection: any component `> 1`. Then:
  - Verify all components (including alpha if present) are integers via `math.floor(v) == v`. If any fails: `error("color: mixed-scale input — non-integer component alongside a component > 1", 2)`.
  - Verify all components are `≤ 255`. If any fails: `error("color: component exceeds 255 in [0,255] range input", 2)`.
  - Return `{ c[1]/255, c[2]/255, c[3]/255, (c[4] or 255)/255 }`.
- **Port from `reference/color.lua`:** The `is_color` field-type validation pattern — checking that positional fields are numbers — can be adapted here to guard against non-numeric components before range analysis. Do not import the reference module; extract the arithmetic pattern only.
- Use `error(msg, 2)` for all hard failures so the error points to the caller's line.
- The module returns a plain table `{ resolve = function }`. No metatables, no class.

## Required Behavior

- `{1, 0, 0}` → `{1, 0, 0, 1}`
- `{0.5, 0.5, 0.5, 0.5}` → `{0.5, 0.5, 0.5, 0.5}`
- `{255, 0, 0}` → `{1, 0, 0, 1}`
- `{255, 0, 0, 128}` → `{1, 0, 0, 0.502}`
- `{255, 0.5, 0}` → hard failure (non-integer `0.5` alongside `255`)
- `{300, 0, 0}` → hard failure (exceeds 255)
- `{0, 0, 0}` → `{0, 0, 0, 1}` (valid: no component exceeds 1)
- Non-numeric component → hard failure
- Missing required components (fewer than 3) → hard failure

## Non-Goals

- No hex, named, or HSL handling in this task.
- No metatable or class wrapper on the output.

## Acceptance Checks

- All eight required behavior cases above produce the correct result or the correct error.
- Module loads without error in isolation.
- `Color.resolve` called with a string input at this stage raises a "not yet handled" or routing error rather than silently returning nil.
