# Task 04: Default Token Table And Acceptance

## Goal

Populate the default token table for all spec-backed control surfaces and validate the visual contract end to end.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §8.4 Token Model`
- `docs/spec/ui-foundation-spec.md §8.9 Render Skin Resolution`
- `docs/spec/ui-foundation-spec.md §8.16 Missing Or Invalid Skin Inputs`
- `docs/spec/ui-controls-spec.md §8.2 Control Visual Surfaces`

## Scope

- Create the library default token table
- Cover documented control parts and state variants
- Verify that missing tokens fail or fall back exactly as the spec allows
- Build a Phase 8 demonstration harness
- Keep the acceptance surface rooted in documented bindings even if implementation coverage is broader internally

## Required Behavior

- Default tokens may exist for all documented bindings, but they must remain rooted in the documented part/property surfaces.
- Partial theme overrides must fall through to base tokens and library defaults exactly as the token-resolution order requires.
- Text styling must stay within the documented `Text` content surface and not rely on extra role taxonomies.
- The demo and acceptance checks must not treat internal convenience aliases, broad fallback tables, or helper APIs as public contract.

## Demo Expectations

- Token override screen proves instance override precedence.
- Nine-slice screen proves corner and edge behavior.
- Variant screen proves documented state priority.
- Canvas-isolation screen proves grouped compositing versus incorrect inline rendering.
- Full-theme screen proves token coverage across the documented controls.

## Non-Goals

- No new control APIs.
- No new stable token families.
- No theming behavior that is not backed by the specs.

## Acceptance Checks

- Every documented control part resolves a token or a documented fallback.
- Theme overrides can be applied without editing control behavior.
- The harness makes spec-visible failures obvious and deterministic.
- Passing acceptance does not depend on undocumented helper APIs or extra public token families.
