# Task 08: Acceptance

## Goal

Verify the complete styling paint pipeline end-to-end. Confirm that all paint steps produce correct visual output, that the paint order is enforced, that no styling paint happens when all properties are absent, and that the module remains stateless across multiple draw calls.

## Spec Anchors

- `docs/spec/ui-styling-spec.md §6`, §7, §8, §9, §11A — all paint contracts

## Scope

- No new implementation — this task verifies the work from tasks 01–07
- Requires a LÖVE runtime to confirm visual output

## Concrete Module Targets

- `lib/ui/render/styling.lua` — read only

## Implementation Guidance

Create a demo screen or temporary acceptance fixture that constructs a series of test nodes using `Styling.draw` directly with prepared `props` and `bounds` tables. Verify each case visually.

**Paint order verification:**

A node with outer shadow, background, border, and inset shadow all set must display them in the correct visual layering: shadow behind background, background behind border, inset shadow inside border.

**Background cases:**

| Props | Expected |
|---|---|
| `backgroundColor = {0.2, 0.4, 0.8}`, `backgroundOpacity = 0.5` | Blue fill at half opacity |
| `backgroundGradient = { kind="linear", direction="horizontal", colors={{1,0,0,1},{0,0,1,1}} }` | Red-to-blue horizontal gradient |
| `backgroundGradient = { kind="linear", direction="vertical", colors={{1,1,1,1},{0,0,0,1}} }` | White-to-black vertical gradient |
| `backgroundImage = someTexture` | Texture drawn at top-left, no scaling |
| `backgroundImage = someTexture`, `backgroundAlignX="center"`, `backgroundAlignY="center"` | Texture centered |
| `backgroundRepeatX = true`, `backgroundRepeatY = true`, `backgroundImage = someTexture` | Tiled texture grid |
| No background properties | No fill visible |

**Corner radius cases:**

| Props | Expected |
|---|---|
| All four radii = `8`, background set | Rounded corners on background |
| All four radii = `200`, bounds = `100×100` | Proportional scale-down, pill shape |
| `cornerRadiusTopLeft = 20`, others `0` | Only top-left corner rounded |

**Border cases:**

| Props | Expected |
|---|---|
| `borderWidthTop = 2`, `borderColor = {0,0,0,1}` | Top border only |
| All four `borderWidth* = 2`, `borderColor = {0,0,0,1}` | Uniform black border |
| `borderStyle = "rough"` | Aliased border edges |
| `borderJoin = "miter"`, `borderMiterLimit = 2` | Miter join, limit enforced |

**Shadow cases:**

| Props | Expected |
|---|---|
| `shadowColor = {0,0,0,0.5}`, `shadowOffsetX = 4`, `shadowOffsetY = 4`, `shadowBlur = 6`, `shadowInset = false` | Soft outer shadow, bottom-right |
| Same but `shadowInset = true` | Soft inset shadow inside node |
| `shadowBlur = 0` | Hard-edged shadow |

**Statelessness verification:**

Call `Styling.draw` twice in succession on the same node with the same props. The second call must produce identical output to the first. No state must leak between calls.

**No-op case:**

Call `Styling.draw` with an empty `props` table. Confirm no visible output and no error.

## Non-Goals

- No automated pixel comparison — visual inspection is sufficient for this phase.
- No performance benchmarking — optimization is out of scope.

## Acceptance Checks

- All table entries above produce the expected visual output.
- Paint order is visually correct: outer shadow behind background, background behind border, inset shadow inside border.
- Two successive calls with the same props produce identical output.
- `Styling.draw({}, bounds, graphics)` produces no output and no error.
- Canvas pool has no leaks after shadow draw calls (pool not exhausted over repeated calls).
