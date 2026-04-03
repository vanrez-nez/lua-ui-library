# Task 04: Shared Validator Helpers

## Goal

Extract repeated validation patterns from the property group implementations (tasks 01–03) into local helper functions in `drawable_schema.lua`. The helpers must be defined before the property group entries use them, must produce consistent error messages, and must be usable from any validator function in the file.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §5.2` — opacity domain `[0, 1]`
- `docs/spec/ui-styling-spec.md §13` — error message format requirements for all hard failures

## Scope

- Modify `lib/ui/core/drawable_schema.lua`
- Add four local helper functions at the top of the file, before the schema table definition
- No new public exports — helpers are file-local only

## Concrete Module Targets

- `lib/ui/core/drawable_schema.lua` — modified only

## Implementation Guidance

**`resolve_color(key, value)`:**

Calls `Color.resolve(value)` and returns the resolved table. Hard failure propagates from `Color.resolve` unchanged — do not wrap or re-format it. The `key` parameter is available for enriching error context if needed but is not required by the spec. Used by all color-typed property validators.

**`check_opacity(key, value)`:**

Asserts that `value` is a number. Asserts that `value >= 0` and `value <= 1`. If either check fails, hard failure with a message identifying `key` and the violated constraint (`"must be a number in [0, 1]"`). Returns `value` on success. Used by `backgroundOpacity`, `borderOpacity`, `shadowOpacity`.

**`check_non_negative(key, value)`:**

Asserts that `value` is a number. Asserts that `value >= 0`. If the number check fails, hard failure. If the non-negative check fails, hard failure with a message identifying `key` as `"must be a number >= 0"`. Returns `value` on success. Used by all width, blur, and corner radius properties.

**`check_enum(key, value, allowed)`:**

Asserts that `value` equals one of the entries in the `allowed` sequential table. Uses a linear scan — the value sets are all small (2–3 entries). If `value` is not found in `allowed`, hard failure with a message identifying `key`, the invalid value received, and the accepted values. Example message form: `"backgroundAlignX: 'middle' is not a valid value — accepted: start, center, end"`. Returns `value` on success. Used by `backgroundAlignX`, `backgroundAlignY`, `borderStyle`, `borderJoin`.

**Placement:**

Place all four helpers as local functions at the top of `drawable_schema.lua`, after any `require` statements and before the schema table literal. This ensures they are defined before the inline validate functions in property entries reference them.

**Error level:**

All helper functions must pass `level + 1` (or use `error(msg, 2)`) so that the error location reported by Lua points to the caller of the helper, not the helper itself. The goal is that the error points to the line in the consumer that set the invalid property value.

## Required Behavior

- `resolve_color("backgroundColor", {1, 0, 0})` → `{1, 0, 0, 1}`
- `resolve_color("backgroundColor", "purple")` → hard failure (propagated from `Color.resolve`)
- `check_opacity("backgroundOpacity", 0.5)` → `0.5`
- `check_opacity("backgroundOpacity", 1.5)` → hard failure with message referencing `backgroundOpacity`
- `check_opacity("backgroundOpacity", -0.1)` → hard failure
- `check_opacity("backgroundOpacity", "high")` → hard failure (not a number)
- `check_non_negative("borderWidthTop", 0)` → `0`
- `check_non_negative("borderWidthTop", 2.5)` → `2.5`
- `check_non_negative("borderWidthTop", -1)` → hard failure with message referencing `borderWidthTop`
- `check_non_negative("shadowBlur", 0)` → `0` (zero is valid)
- `check_enum("borderStyle", "smooth", {"smooth", "rough"})` → `"smooth"`
- `check_enum("borderStyle", "dashed", {"smooth", "rough"})` → hard failure listing accepted values
- `check_enum("backgroundAlignX", "center", {"start", "center", "end"})` → `"center"`

## Non-Goals

- No public export of helpers. These are file-local to `drawable_schema.lua`.
- No validation of compound types (`backgroundGradient` structure, `backgroundImage` source type) — those are handled inline in the property validators because their logic is too specific to generalize.
- No caching or memoization of validation results.

## Acceptance Checks

- Each helper is callable in isolation and produces the documented result or error.
- Error messages from each helper identify the property key and the violated constraint.
- The file loads without error after helpers are added but before property entries are added.
- Tasks 01–03 property validators that use these helpers compile and behave identically to the inline descriptions in those tasks.
