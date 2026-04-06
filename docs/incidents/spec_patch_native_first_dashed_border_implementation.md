# Spec Patch: Consolidate Native-First Continuous-Path Guidance For Dashed Borders

## Summary

The dashed border spec should explicitly align two implementation-facing ideas:

1. native or pattern-based rendering primitives are preferred when they satisfy
   the public contract
2. the standard dashed-border model is a continuous perimeter-phase stroke for
   the common uniform-width case

Evidence of that intent already exists in the public contract:

- dash and gap lengths are bounded to `<= 255`
- the total cycle is bounded to `<= 255`
- rendered output is defined as the closest achievable approximation rather
  than as exact geometric fidelity

The current implementation and the current public text are not aligned with
that intent. The implementation has drifted toward segmented dashed rendering,
while the spec text still describes per-side dash starts. That combination
works against the stronger algorithmic guidance already demonstrated by
[`border-fallback.lua`](/Users/vanrez/Documents/game-dev/lua-ui-library/border-fallback.lua):
continuous perimeter-distance dash placement with corners kept in phase.

That drift creates two problems:

1. It adds renderer complexity in an area the spec was trying to keep
   implementation-friendly.
2. It prevents the spec from clearly guiding implementations toward a
   continuous-path dashed strategy that keeps rounded corners visually in sync.

This patch does not narrow the public behavior contract. It adds an explicit
implementation note: when more than one implementation strategy can satisfy the
contract, native-first is the preferred direction, specifically because this
contract is loose enough to give implementations space to consider trade-offs
between compliance to a specific visual requirement and performance, rather than
inviting clever constructed geometry on top of a contract that was designed to
permit approximation.

---

## Problem

The current public spec leaves room for multiple compliant implementations, but
it does not state the intended phase model clearly enough.

That ambiguity allowed a drift from:

- native or pattern-based rendering where feasible
- continuous perimeter-distance dash placement for the standard dashed-border
  path

to:

- a more custom composable dashed-border renderer

For dashed rounded borders, that drift is especially costly:

- corners can fall out of sync with perimeter distance
- implementations lose a strong guide for keeping radii visually coherent
- renderer complexity increases without delivering better output

This is both a public behavior clarification and an implementation-guidance
clarification about performance-driven trade-offs.

---

## Existing Signals In The Current Spec

The current styling spec already points toward native-first implementation and
approximation-friendly dashed rendering:

- [ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md#L528)
  caps the dash cycle at `255`, which clearly aligns with pattern/stipple-style
  primitive limits.
- [ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md#L538)
  defines dashed rendering as the closest achievable approximation rather than
  exact pixel-perfect geometry.

What is missing is:

- an explicit statement that implementations should prefer native facilities
  when that path is good enough
- an explicit statement that the standard dashed path is continuous around the
  rendered perimeter rather than restarting at side boundaries
- an explicit statement that mixed-width support is valid but should not force
  extra procedural splitting onto the uniform-width fast path

---

## Proposed Contract Clarification

### Consolidate Public Behavior

This patch keeps the public property surface unchanged:

- `borderPattern`
- `borderDashLength`
- `borderGapLength`
- rounded corner shaping
- closest achievable approximation

But it does clarify the dashed phase model:

- uniform-width dashed borders use one continuous perimeter-phase model
- rounded corners participate in that same cumulative-distance model
- mixed-width borders remain valid and may require a segmented fallback path

### Add Native-First Implementation Guidance

Add a short implementation note to the dashed border section:

```text
When the host rendering system provides native or pattern-based primitives that
can satisfy the public dashed-border contract, implementations should prefer
those native facilities first.

This preference exists because the contract is intentionally loose enough to let
implementations balance compliance to a specific visual requirement against
performance, not because native output is always visually superior.

For the common case where all resolved border widths are equal, implementations
should preserve a continuous-path fast path instead of procedurally splitting
the border only to support rarer mixed-width cases.

Custom rendering remains valid when native primitives cannot satisfy the
contract, but it should be a fallback rather than the default strategy.

Mixed-width dashed borders remain part of the contract, but the extra
procedural cost of supporting them should be paid only on that exceptional
path, not imposed on the uniform-width case.
```

This keeps the spec behaviorally open while making the intended implementation
direction explicit.

---

## Rationale

This consolidation makes the spec more honest about its own design constraints.

The dashed-border contract was not written as if the renderer were a full
vector engine. It was written to remain:

- deterministic
- implementation-friendly
- compatible with native pattern-based rendering limits

Adding native-first continuous-path guidance does four useful things:

1. It aligns the implementation strategy with the existing `255` cycle ceiling.
2. It discourages unnecessary renderer complexity where native output is
   already contract-compliant.
3. It makes performance the explicit reason the contract remains
   approximation-friendly while still preserving a fast path for the dominant
   uniform-width case.
4. It gives implementations a clear algorithmic guide for keeping straight
   segments and rounded corners in phase through cumulative perimeter distance.

---

## Patch Direction

Patch the dashed border subsection of
[ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md)
so it reads, in effect:

```text
The dashed border is resolved from cumulative distance along the rendered border
perimeter rather than restarting the dash phase at each side boundary.

Rounded corners participate in the same cumulative-distance model as straight
border segments.

Rendered dash and gap lengths are the closest achievable approximation of the
requested values; exact pixel-accurate fidelity is not guaranteed.

When native or pattern-based host primitives can satisfy this contract,
implementations should prefer those native facilities first.

When all resolved border widths are equal, implementations should preserve a
continuous-path fast path rather than procedurally splitting geometry only to
support rarer mixed-width cases.

Differing resolved border widths remain valid and may require a segmented
fallback path when the continuous-path fast path cannot satisfy the full border
contract.
```

This keeps the contract implementation-flexible without pretending all
implementation strategies are equally preferred.

---

## Non-Goals

This patch does not:

- require one specific LÖVE API call or one specific host primitive
- forbid custom rendering absolutely
- change the public property surface
- introduce a new border fidelity guarantee
- require mixed-width dashed borders to have the same cost profile as the
  uniform-width path

It clarifies the intended dashed phase model and the implementation preference
order.

It also makes explicit that this preference order is motivated by performance
and by preserving the proof-of-concept algorithmic fast path where possible.

---

## Patch Note

Add this note to the dashed-border clause in
[ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md):

```text
Dashed borders are resolved from cumulative distance along the rendered border
perimeter rather than restarting the dash phase at each side boundary.
Rounded corners participate in that same cumulative-distance model.

When native or pattern-based host primitives can satisfy the dashed-border
contract, implementations should prefer those native facilities first.

When all resolved border widths are equal, implementations should preserve a
continuous-path fast path rather than procedurally splitting geometry only to
support rarer mixed-width cases. Custom dashed-border construction remains
valid as a fallback when native primitives cannot satisfy the contract or when
mixed-width borders require a segmented path.
```
