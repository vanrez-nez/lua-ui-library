# Spec Patch: Dashed Border Pattern Support

## Summary

The current styling spec defines `borderStyle`, but that field only controls
stroke quality:

- `smooth`
- `rough`

It does not define border patterning, and the spec explicitly excludes dashed
or stippled borders.

That leaves a gap in the public styling contract. Authors can request border
quality, but they cannot request a standard dashed border without dropping into
custom drawing.

This patch keeps the existing `borderStyle` semantics intact and adds a
separate, explicit border-pattern contract for `Drawable`.

---

## Problem

The current model creates two problems.

1. The name `borderStyle` reads like it should own visible border style
   categories, but in practice it only selects antialiasing quality.

2. There is no standard way to ask for a dashed border.
   Authors who need a common design affordance must either fake it in demo code
   or bypass the retained styling system entirely.

This is a spec gap, not just a demo issue.

The retained styling contract should be able to express:

- solid border
- dashed border
- stroke quality

Those are separate concerns and should not be conflated.

---

## Proposed Contract

### Keep Existing `borderStyle`

This patch does not redefine `borderStyle`.

`borderStyle` remains:

- `smooth`
- `rough`

Meaning:

- `smooth`: antialiased stroke rendering
- `rough`: aliased stroke rendering

### Add New Border Pattern Props

Add to the `Drawable` styling surface:

```text
- `borderPattern: "solid" | "dashed"`
- `borderDashLength: number`
- `borderGapLength: number`
```

Defaults:

```text
borderPattern = "solid"
borderDashLength = 8
borderGapLength = 6
```

Validation:

- `borderPattern` must be one of the accepted enum values
- `borderDashLength` must be finite, greater than zero, and at most 255
- `borderGapLength` must be finite, greater than or equal to zero, and at most 255
- `borderDashLength + borderGapLength` must not exceed 255

When `borderPattern = "solid"`, dash and gap values are ignored.

---

## Behavioral Rules

### Pattern Ownership

`borderPattern` controls segmentation of the rendered border.

`borderStyle` continues to control stroke quality.

These props are orthogonal:

- `borderPattern = "solid"` + `borderStyle = "smooth"`
- `borderPattern = "solid"` + `borderStyle = "rough"`
- `borderPattern = "dashed"` + `borderStyle = "smooth"`
- `borderPattern = "dashed"` + `borderStyle = "rough"`

### Dashed Border Semantics

When `borderPattern = "dashed"`:

- the resolved border stroke is rendered as repeated dash-gap segments
- dash length is controlled by `borderDashLength`
- gap length is controlled by `borderGapLength`
- partial trailing dashes are permitted at the end of a side

Length values are expressed in **logical units** — the same coordinate space
used for layout and sizing. Implementations are responsible for mapping these
values to the nearest achievable representation in the underlying rendering
system. Exact pixel-accurate fidelity is not guaranteed; rendered output is the
closest achievable approximation.

### Side Model

Dashed borders are defined per resolved side, not as a single continuous
perimeter-phase contract.

That means:

- top, right, bottom, and left sides are patterned independently
- each side starts with a dash at its own local start
- each side may end with a truncated final dash if needed

This keeps the contract deterministic and implementation-friendly for
rectangular and mixed-width borders.

### Interaction With Per-Side Border Width

The pattern applies only where the resolved side border width is greater than
zero.

Therefore:

- a side with resolved width `0` paints nothing for that side
- a side with non-zero width paints its own dashed pattern regardless of
  neighboring side widths

### Interaction With Corner Radius

Corner radius still shapes the resolved border geometry.

For `borderPattern = "dashed"`:

- each side's dashed segments follow the resolved rounded outer edge for that
  side
- rounded corners remain part of the border geometry
- the spec does not require dash continuity across corner transitions

This means rounded corners remain visually clipped and shaped correctly, but
dash phase does not have to flow continuously around the whole perimeter.

### Interaction With `borderJoin`

`borderJoin` continues to govern how border geometry is joined where a visible
border segment meets an adjacent visible segment at a corner.

`borderJoin` does not introduce extra geometry across a dash gap.

So:

- joins apply at actual corner continuity
- joins do not bridge dash interruptions

---

## Field Contract Implications

### `borderPattern`

Patch the styling section to define:

- `borderPattern` as the border segmentation family
- `solid` as the default behavior
- `dashed` as repeated dash-gap segmentation

### `borderDashLength`

Patch the styling section to define:

- numeric, expressed in logical units
- finite
- strictly greater than zero
- at most 255

### `borderGapLength`

Patch the styling section to define:

- numeric, expressed in logical units
- finite
- greater than or equal to zero
- at most 255

### Cycle Length Ceiling

The combined cycle (`borderDashLength + borderGapLength`) must not exceed 255
logical units. This bound aligns with the practical bit-budget ceiling of
pattern-based rendering primitives and ensures consistent behavior across
implementations.

---

## Paint Model Patch

Patch the border paint section to say:

```text
The resolved border paint model includes two independent dimensions:

- stroke quality, controlled by `borderStyle`
- stroke pattern, controlled by `borderPattern`
```

Patch the accepted values section to add:

```text
- `borderPattern: "solid" | "dashed"`
- `borderDashLength: number`  (logical units, >0, ≤255)
- `borderGapLength: number`   (logical units, ≥0, ≤255)
```

Patch the invalid configuration section to add:

- `borderPattern` outside the accepted enum set fails deterministically
- non-finite dash or gap values fail deterministically
- `borderDashLength <= 0` fails deterministically
- `borderDashLength > 255` fails deterministically
- `borderGapLength < 0` fails deterministically
- `borderGapLength > 255` fails deterministically
- `borderDashLength + borderGapLength > 255` fails deterministically

---

## Behavioral Edge Cases

- when all resolved border widths are zero, no border paints regardless of
  pattern settings
- when a side is shorter than `borderDashLength`, a single truncated dash may
  paint for that side
- `borderGapLength = 0` is valid and produces back-to-back dash segments with
  no visible gap; this is visually equivalent to `borderPattern = "solid"` and
  implementations may optimize this case accordingly
- dashed border rendering is the closest achievable approximation of the
  requested lengths; minor deviation from exact values is permitted
- dashed borders do not alter layout, sizing, hit-testing, or clipping
- dashed borders do not affect shadow geometry beyond the same resolved border
  outline already defined by the existing styling contract

---

## Why This Is Better

This model fixes the semantic mismatch cleanly.

It preserves the current meaning of `borderStyle`, which is already implemented
and documented as a quality selector, while adding the missing public concept:

- border pattern

That gives authors a standard retained-mode way to ask for dashed borders
without forcing custom drawing and without overloading one field with two
unrelated responsibilities.

The logical-unit model keeps the contract renderer-agnostic. Pattern rendering
primitives operate on fixed-size bit budgets; the 255-unit cycle ceiling aligns
the spec with that constraint without exposing implementation details.

---

## Recommended Follow-Up

If adopted, the spec should also patch:

- the `Drawable` schema section to include the three new props
- the styling examples to include one dashed-border example
- the demo suite to show `solid` vs `dashed` under both `smooth` and `rough`
