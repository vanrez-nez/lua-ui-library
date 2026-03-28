# Phase 03 Compliance Review

Source under review: `docs/implementation/phase-03-layout.md`

Primary findings, ordered by severity:

1. `Flow` gains unsupported public props.
   Source: `phase-03-layout.md:103-112`
   Spec anchors: `ui-foundation-spec.md §6.2.2 Common props`, `ui-foundation-spec.md §6.2.7 Flow`
   Problem: the phase doc introduces `gapX` and `gapY` as `Flow` props, but the spec says `Flow` defines no additional props beyond the common layout props. The common layout prop is `gap`, not axis-specific gap props.
   Required normalization: keep `Flow` on the common layout prop surface unless the spec is amended.

2. Responsive handling in the phase plan conflicts with the now-settled spec contract.
   Source: `phase-03-layout.md:17-23`, `phase-03-layout.md:147-151`
   Spec anchors: `ui-foundation-spec.md §6.2.2 Common props`, `ui-foundation-spec.md §7.3 Responsive Rules`, `ui-foundation-spec.md §6.1.1 Container`
   Problems:
   - the phase doc hardcodes a breakpoint list format with `minWidth` / `minHeight` entries and `props` tables
   - it evaluates breakpoints only against Stage viewport
   - it does not account for orientation, safe area, or parent dimensions, all of which the spec permits responsive rules to depend on
   - it does not reflect the settled rule that `responsive` and `breakpoints` are two public entry points into the same pre-measure responsive step
   - it omits the deterministic-invalid rule for nodes that supply both `responsive` and `breakpoints`
   Required normalization: treat the spec's timing and entry-point relationship as authoritative, keep any serialized rule shape implementation-local, and make dual-source responsive configuration a deterministic failure.

3. Row fill allocation is presented as if it were contract, but the spec does not define that policy.
   Source: `phase-03-layout.md:61-65`
   Spec anchors: `ui-foundation-spec.md §6.2.5 Row`, `ui-foundation-spec.md §7.3 Responsive Rules`
   Problem: the draft states that `width = "fill"` children share remaining space equally. The spec supports fluid percentages and size modes, but it does not define equal-share fill allocation for Row.
   Required normalization: treat fill-allocation strategy as internal implementation policy unless and until the spec declares it.

4. `SafeAreaContainer` is rooted in insets rather than safe-area bounds.
   Source: `phase-03-layout.md:120-130`
   Spec anchors: `ui-foundation-spec.md §6.2.8 SafeAreaContainer`, `ui-foundation-spec.md §6.4.1 Stage`
   Problem: the phase doc says `SafeAreaContainer` reads `stage:getSafeArea()` and applies per-edge insets, but the spec defines the contract in terms of current safe-area bounds and explicitly clarifies that an insets-only environment API is insufficient.
   Required normalization: derive the container's content region from queryable safe-area bounds, not from an insets-only API assumption.

5. The phase document assigns public defaults the spec does not stabilize.
   Source: `phase-03-layout.md:59`, `phase-03-layout.md:68-72`, `phase-03-layout.md:86`, `phase-03-layout.md:103`, `phase-03-layout.md:123-133`
   Spec anchors: `ui-foundation-spec.md §6.2 Layout Family`, `ui-evolution-spec.md §2 Breaking Change Definition`
   Problem: defaults such as `wrap = true` for `Flow`, `wrap = false` for `Row`/`Column`, or all-edge `SafeAreaContainer` defaults may be reasonable implementation choices, but they are not declared as stable defaults by the spec text.
   Required normalization: keep such defaults as implementation detail unless separately documented in the spec as contract.

Secondary scoping notes:

- `Stack` content-size-from-children behavior is a reasonable implementation for `width = "content"`, but it should be treated as implementation-level measurement behavior rather than a newly stated stable promise unless the spec is amended.
- Percentage sizing must resolve against the effective parent content region, including safe-area-derived content boxes, rather than against raw viewport size by default.
- The Stage update split into layout pass then transform pass is consistent with the spec's update traversal so long as it remains an internal execution detail.
