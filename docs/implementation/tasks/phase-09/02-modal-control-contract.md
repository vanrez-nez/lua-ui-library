# Task 02: Modal Control Contract

## Goal

Implement `Modal` strictly on the spec-backed public surface and tie it to overlay-layer behavior.

## Spec Anchors

- `docs/spec/ui-controls-spec.md §6.7 Modal`
- `docs/spec/ui-controls-spec.md §4B.1 Control Validity Rules`
- `docs/spec/ui-controls-spec.md §4B.3 Control Slot Declarations`
- `docs/spec/ui-controls-spec.md §4C.2 Public State Ownership Matrix`

## Scope

- `lib/ui/controls/modal.lua`
- Controlled open state and `onOpenChange`
- `dismissOnBackdrop` / `dismissOnEscape`
- `trapFocus` / `restoreFocus`
- `safeAreaAware`
- `backdropDismissBehavior`
- Required `root`, `backdrop`, `surface`, and `content` structure

## Required Behavior

- Modal is mounted in the overlay layer owned by Stage.
- The backdrop blocks interaction with underlying content while open.
- When `trapFocus = true`, the modal owns a nested focus scope and restores focus when configured.
- Dismissal via backdrop or escape only occurs when the corresponding spec-backed props allow it.
- The control must remain valid with no focusable content in the surface.

## Settled Boundaries

- Keep any `open()` / `close()` convenience methods internal unless a separate stable API is documented.
- Do not encode a public `focusScope` prop on `Drawable` or `Modal`; the spec models focus scope as overlay behavior, not as a drawable setting.
- Surface placement may be centered or otherwise positioned according to the control contract, but the implementation must not narrow that to a single public layout rule beyond the spec.

## Non-Goals

- No Alert-specific title/actions behavior.
- No public overlay registry API.
- No public scene lifecycle expansion.

## Acceptance Checks

- Controlled open state behaves as a negotiated UI state.
- `dismissOnBackdrop = false` blocks dismissal without losing the backdrop barrier.
- `restoreFocus = true` returns focus to the prior valid node when possible.
