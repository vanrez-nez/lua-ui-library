# Task 04: Integration And Acceptance

## Goal

Wire `Color.resolve` into the library's existing color consumption paths, verify all spec-defined input forms end-to-end, and confirm hard-failure semantics match the spec.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §5.3` — full accepted form catalog
- `docs/spec/ui-styling-spec.md §5.4` — full conversion catalog
- `docs/spec/ui-styling-spec.md §13` — complete hard-failure list for color inputs

## Scope

- Expose `Color.resolve` through `lib/ui/init.lua` or the appropriate graphics/render namespace
- Replace any raw color table pass-through in the theme resolver or default tokens that would benefit from going through `Color.resolve`
- Confirm all acceptance checks from tasks 01–03 pass in the integrated context
- Confirm hard failures bubble correctly from `Color.resolve` to the calling site

## Concrete Module Targets

- `lib/ui/render/color.lua` — finalized
- `lib/ui/init.lua` — export `Color` if it is part of the public surface

## Implementation Guidance

**Export decision:**

`Color.resolve` is a public utility — consumers writing custom skins or tokens may need to normalize color inputs programmatically. Export it through the library's public surface under `Color` or `ui.Color`.

**Theme default token compatibility:**

All existing color values in `lib/ui/themes/default.lua` are already `{ r, g, b, a }` tables in `[0, 1]`. They are valid passthrough inputs to `Color.resolve`. No migration of default tokens is required.

**Resolver integration:**

The theme resolver (`lib/ui/themes/resolver.lua`) returns raw token values. Color token values should be passed through `Color.resolve` at the point of consumption (in the styling renderer, Phase 13) rather than in the resolver itself. The resolver remains a general-purpose value lookup and does not need to know about color normalization.

**Acceptance script:**

Write a standalone Lua script (or add to an existing test harness under `demos/` or a `tests/` directory) that exercises all input forms defined by the spec. The script must:

- Call `Color.resolve` with each accepted form and assert the expected output
- Call `Color.resolve` with each documented hard-failure case wrapped in `pcall` and assert that an error is raised

The script must be runnable standalone without a full LÖVE runtime (pure Lua).

## Full Acceptance Matrix

### Passing cases

| Input | Expected output |
|---|---|
| `{1, 0, 0}` | `{1, 0, 0, 1}` |
| `{1, 0, 0, 0.5}` | `{1, 0, 0, 0.5}` |
| `{255, 0, 0}` | `{1, 0, 0, 1}` |
| `{255, 0, 0, 128}` | `{1, 0, 0, 0.502}` |
| `"#F00"` | `{1, 0, 0, 1}` |
| `"#FF0000"` | `{1, 0, 0, 1}` |
| `"#FF000080"` | `{1, 0, 0, ~0.502}` |
| `"#F00F"` | `{1, 0, 0, 1}` |
| `"red"` | `{1, 0, 0, 1}` |
| `"transparent"` | `{0, 0, 0, 0}` |
| `"black"` | `{0, 0, 0, 1}` |
| `"white"` | `{1, 1, 1, 1}` |
| `"hsl(0, 1, 0.5)"` | `{1, 0, 0, 1}` |
| `"hsl(120, 1, 0.5)"` | `{0, 1, 0, 1}` |
| `"hsl(240, 1, 0.5)"` | `{0, 0, 1, 1}` |
| `"hsla(0, 1, 0.5, 0.5)"` | `{1, 0, 0, 0.5}` |
| `"hsl(360, 1, 0.5)"` | same as `hsl(0, ...)` |
| `"hsl(-90, 1, 0.5)"` | same as `hsl(270, ...)` |

### Hard-failure cases

| Input | Reason |
|---|---|
| `{255, 0.5, 0}` | non-integer in detected `[0, 255]` range |
| `{300, 0, 0}` | component exceeds 255 |
| `"purple"` | unsupported named color |
| `"#FFFFF"` | invalid hex length |
| `"#GG0000"` | invalid hex character |
| `"hsl(0, 1.5, 0.5)"` | saturation out of `[0, 1]` |
| `"hsl(0, 1, 1.5)"` | lightness out of `[0, 1]` |
| `"hsla(0, 1, 0.5, 1.5)"` | alpha out of `[0, 1]` |
| `42` | not a table or string |
| `true` | not a table or string |
| `nil` | not a table or string |

## Non-Goals

- No color interpolation utilities — those belong in Phase 13.
- No integration into the schema validator — that is Phase 12's responsibility.
- No migration of existing skin or token color values — they are already valid passthrough inputs.

## Acceptance Checks

- All passing cases in the matrix return the documented output (within float tolerance for division).
- All hard-failure cases raise an error when called via `pcall`.
- `Color.resolve` is accessible from the library public surface.
- The acceptance script runs cleanly with `lua acceptance.lua` or equivalent without a LÖVE runtime.
