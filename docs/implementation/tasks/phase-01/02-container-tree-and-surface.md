# Task 02: Container Tree And Public Surface

## Goal

Implement `Container` as the retained structural primitive while keeping its public API aligned with the foundation spec.

## Spec Anchors

- `docs/spec/ui-foundation-spec.md §6.1.1 Container`
- `docs/spec/ui-foundation-spec.md §3A.3 Component Responsibility Boundary`
- `docs/spec/ui-foundation-spec.md §3B.2 Composition Validity Rules`
- `docs/spec/ui-foundation-spec.md §3G.2 Invalid Usage Classification`

## Scope

- Implement `lib/ui/core/container.lua`
- Parent-child ownership and reparenting rules
- Ordered child storage
- Destruction and tree detachment behavior
- Stable storage for the documented `Container` prop surface

## Public Surface Requirements

- Keep the documented props exactly within the spec surface:
  `tag`, `visible`, `interactive`, `enabled`, `focusable`, `clipChildren`, `zIndex`,
  `anchorX`, `anchorY`, `pivotX`, `pivotY`, `x`, `y`, `width`, `height`,
  `minWidth`, `minHeight`, `maxWidth`, `maxHeight`, `scaleX`, `scaleY`,
  `rotation`, `skewX`, `skewY`, `breakpoints`.
- Do not expose `focusScope` or `trapFocus` as `Container` props in this phase.
- Do not document Phase-specific default values as spec commitments when the spec does not define them.

## Required Behavior

- `addChild`, `removeChild`, and `getChildren` manage one parent maximum and stable insertion order.
- Reparenting is allowed, but the child must be removed from its prior parent before entering the new one.
- Cyclic parenting attempts hard-fail deterministically.
- `destroy()` detaches the subtree and ends further retained-tree participation for that instance.

## Deferred But Shape-Stable Requirements

- `width` and `height` must preserve the full spec surface now.
- Phase 1 only needs concrete execution paths for explicit numeric sizes and direct-root `fill` cases required by the test harness.
- Unsupported measurement paths must not silently redefine the API; they must remain deferred behind later tasks or follow the spec's documented failure behavior.

## Non-Goals

- No event propagation implementation yet.
- No layout-family child placement yet.
- No focus traversal behavior yet.

## Acceptance Checks

- Child insertion order is stable until explicit mutation.
- Reparenting does not duplicate nodes.
- Cycle creation raises a hard failure.
- Public docs and constructor surface do not narrow `width` or `height` to numbers only.
