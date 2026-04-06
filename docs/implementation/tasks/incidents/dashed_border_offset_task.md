# Implementation Task: Dashed Border Offset

## Summary

Implement `borderDashOffset` as a small additive dashed-border property.

The new property must:

- apply only when `borderPattern = "dashed"`
- default to `0`
- shift dash phase along the same resolved border perimeter already used by the
  dashed-border contract
- treat positive values as advancing forward along perimeter traversal
- treat negative values as shifting in the opposite direction

This task should preserve the current dashed-border model and only add public
phase control.

## Public Contract To Implement

Add support for:

- `borderDashOffset`

Behavior:

- finite numeric value in logical units
- ignored when `borderPattern = "solid"`
- `0` preserves existing behavior
- does not change `borderDashLength`
- does not change `borderGapLength`
- does not change uniform-versus-mixed-width path selection

## Implementation Changes

### Validation And Prop Assembly

- Add `borderDashOffset` to the styling schema and contract surface.
- Validate it as a finite number.
- Ensure default resolution is `0` when not explicitly provided.

### Border Renderer

- Thread `borderDashOffset` into the dashed-border renderer.
- Apply it to the continuous uniform-width dashed path by shifting the initial
  cumulative-distance phase.
- Apply the same sign convention to the mixed-width segmented fallback so both
  dashed paths expose one consistent public behavior.
- Keep `borderGapLength = 0` behaving as the existing solid fast path.

### Demo / Verification Surface

- Add or update a simple dashed-border demo case that can show visible phase
  movement when `borderDashOffset` is changed over time.
- Keep this as ordinary property-driven behavior rather than a renderer-only
  debug hook.

## Acceptance Criteria

- `borderDashOffset = 0` matches the current dashed rendering output.
- Positive offset advances the dash phase forward along the resolved perimeter.
- Negative offset shifts the phase in the opposite direction.
- `borderPattern = "solid"` ignores `borderDashOffset`.
- Uniform-width and mixed-width dashed borders both honor the property.
- Non-finite `borderDashOffset` fails deterministically.

## Suggested Verification

- Add a static case comparing `borderDashOffset = 0` and a non-zero value.
- Add a temporary animated demo or scripted property update to visually confirm
  smooth phase motion.
- Check that rounded dashed corners stay in phase when offset changes.

## Assumptions

- No explicit min/max bound is required for `borderDashOffset`; finite numeric
  input is sufficient.
- The public direction contract should use perimeter-traversal language rather
  than a shape-specific term like "clockwise".
