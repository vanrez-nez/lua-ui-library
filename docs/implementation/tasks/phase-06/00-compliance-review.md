# Phase 06 Compliance Review

Source under review: `docs/implementation/phase-06-scroll.md`

Primary findings, ordered by severity:

1. Public child-management APIs are introduced without spec support.
   Source: `phase-06-scroll.md:118-121`
   Spec anchors: `ui-foundation-spec.md §6.3.1 ScrollableContainer`, `ui-foundation-spec.md §3B.4 Slot Model`
   Problem: the phase doc stabilizes `addContent(node)` and `getContentContainer()` as public APIs. The spec defines the anatomy and required `content` subtree, but it does not stabilize public method names for attaching consumer content.
   Required normalization: keep attachment mechanics internal or constructor-based unless the spec later defines public API names for them.

2. Keyboard-scroll behavior is narrowed through `ui.navigate`, which is not the public scroll contract.
   Source: `phase-06-scroll.md:52-55`
   Spec anchors: `ui-foundation-spec.md §3D.1 Input Abstraction Model`, `ui-foundation-spec.md §3D.3 Input-To-State-Proposal Mapping`, `ui-foundation-spec.md §6.3.1 ScrollableContainer`
   Problem: the spec defines `Scroll` as the logical input for scrollable targets and says focused scroll containers respond to keyboard scroll commands. It does not stabilize `ui.navigate` as the public scroll entry point or tie scroll behavior to a specific direction-key translation table.
   Required normalization: implement keyboard scrolling through the scroll contract, but keep the key mapping and event plumbing internal unless a later spec standardizes it.

3. Overscroll and momentum math are over-specified relative to the spec.
   Source: `phase-06-scroll.md:60-75`, `phase-06-scroll.md:108-114`
   Spec anchors: `ui-foundation-spec.md §6.3.1 ScrollableContainer`, `ui-foundation-spec.md §3E.2 Overflow And Constraint Behavior`
   Problem: the phase doc freezes damping factors, velocity-window sizes, spring constants, stop thresholds, and a `momentumDecay` validity range. The spec requires momentum and overscroll support, but it does not commit to these exact algorithms or parameter ranges.
   Required normalization: treat the exact inertial and overscroll math as implementation detail while keeping the observable state machine and contract behavior intact.

4. Scrollbar layout and interaction choices are being committed too early.
   Source: `phase-06-scroll.md:96-102`
   Spec anchors: `ui-foundation-spec.md §6.3.1 ScrollableContainer`, `ui-foundation-spec.md §3B.3 Foundation Compound Component Contract`
   Problem: the phase doc fixes scrollbar geometry, thumb formulas, and non-interactive behavior as if they were stable public requirements. The spec only requires optional visual indicators and drag handles; it does not standardize the exact geometry or interaction profile in this revision.
   Required normalization: keep scrollbar rendering and interaction policy internal unless the component spec later stabilizes specific visuals or handles.

Secondary scoping notes:

- The three-state `idle` / `dragging` / `inertial` model is spec-backed and should remain.
- Nested scroll consumption is required by the spec, but the exact event-propagation wiring is an implementation detail.
