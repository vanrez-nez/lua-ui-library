# Spec Patch: `fill` And Parent-Relative Sizing

## Goal

Clarify two different behaviors that are currently too easy to conflate:

1. `fill` is a layout-aware participation value, not a generic self-resolved size value
2. percentage sizing is self-resolved against the effective parent axis and remains independent from local same-axis position

This patch is documentation-first.

## Intended Outcome

After this patch, the spec should communicate that:

- `width = "100%"` on a plain `Container` means full effective parent width
- `x` on that same node remains an independent local offset
- overflow from combining those two is valid and expected in a free-positioned model
- `fill` is not the same thing as `100%`
- `fill` requires a parent contract that knows how to resolve it
- the spec explicitly names which parent contracts do and do not resolve `fill`
- follow-up implementation work includes validation, diagnostics, and spec-test updates rather than only measurement internals

## Proposed Patch

### 1. Patch `Container` Props

Current text:

```text
- `width`, `height: number | "content" | "fill" | percentage`
```

Proposed text:

```text
- `width`, `height: number | "content" | percentage | "fill"`
```

Add an explanatory note immediately after the props list:

```text
`percentage` sizing is self-resolved against the effective parent content region for the relevant axis.
`fill` is a parent-resolved layout participation value and is only meaningful when the parent contract defines fill resolution for that axis.
These two sizing categories are intentionally distinct and must not be treated as aliases.
```

### 2. Patch `Container` State Model / Measurement Clarification

Add after the existing state model section:

```text
For plain `Container`, percentage measurement resolves before local transform and remains independent of local same-axis position.
For example, `x = 160` and `width = "100%"` means "resolve width from the effective parent width, then offset the node by 160 in parent space."
Any resulting overflow is valid unless clipping or a parent contract states otherwise.
```

### 3. Patch `Container` Behavioral Edge Cases

Replace the current Stage sentence with a parent-contract note, and add:

```text
- A `Container` may use `fill` only when its parent contract explicitly defines fill resolution for that axis.
- In this revision, the supported parent-contract cases are:
  - direct child of `Stage` for viewport-filling runtime layers
  - child of a layout family whose algorithm defines fill resolution for that axis
  - library-owned internal containers whose owning component contract explicitly delegates or synchronizes that axis
- A `Container` with percentage width or height resolves that percentage against the full effective parent content region on the relevant axis, independent of the node's own local position on that axis.
- A `Container` may overflow its parent when parent-relative sizing is combined with local offsets. This is valid free-positioned behavior unless the parent or an explicit clipping rule constrains it.
- A `Container` does not interpret `fill` as sibling-aware remaining-space allocation.
- If a `Container` uses `fill` on an axis whose parent contract does not define fill resolution for that axis, the configuration is invalid for that parent-child pairing and must produce a deterministic diagnostic.
```

### 4. Patch `Row`

After the current `Row` fill edge case, add:

```text
In `Row`, fill-sized width is resolved by the parent layout contract rather than by the child node in isolation.
Cross-axis fill behavior is valid only when the `Row` contract defines resolution for that axis.
```

### 5. Patch `Column`

After the current `Column` fill edge case, add:

```text
In `Column`, fill-sized height is resolved by the parent layout contract rather than by the child node in isolation.
Cross-axis fill behavior is valid only when the `Column` contract defines resolution for that axis.
```

### 6. Patch `Flow` And Other Layout Families

Add a short clarification in the layout-family section:

```text
Any layout family that supports `fill` must define that support explicitly on a per-axis basis.
If a layout family does not define `fill` resolution for an axis, child `fill` on that axis is invalid and must fail deterministically.
No layout family may silently reinterpret `fill` as a generic alias for `100%`.
```

This avoids leaving `Stack`, `Flow`, and future layout families ambiguous after clarifying `Row` and `Column`.

### 7. Patch Common Layout Terminology

Add a short note in the layout-family section:

```text
`fill` is a layout participation value, not a generic synonym for `100%`.
When supported, it is resolved by the parent's layout algorithm.
Percentages remain self-resolved against the effective parent region and do not imply remaining-space allocation.
```

### 8. Patch Runtime / Internal-Delegation Terminology

Add a short note near the runtime or delegated-content discussion:

```text
Some library-owned runtime or delegated internal nodes may use `fill` even when they are not public layout-family children.
In those cases, `fill` remains valid only because the owning parent contract explicitly defines viewport-sized, delegated, or synchronized-axis resolution.
This is a parent-contract exception that must be documented by the owning component and must not be generalized into plain `Container` self-resolution.
```

## Rationale

This patch preserves the correct free-positioned primitive model:

- percentages are self-computed
- position is independent
- overflow is allowed

And it separates that from the layout model:

- `fill` is parent-resolved
- `fill` implies participation in a parent algorithm
- `fill` should not silently masquerade as `100%`

## Follow-Up Implementation Impact

If the spec patch is accepted, implementation should be reviewed for consistency:

1. `lib/ui/utils/math.lua`
   `fill` should no longer be treated as a generic self-resolved axis size in isolation
2. `lib/ui/core/container.lua`
   plain `Container` should not silently self-resolve `fill` as full parent axis size
3. `lib/ui/layout/sequential_layout.lua`
   keep `fill` as parent-resolved layout behavior for `Row` and `Column`
4. `lib/ui/layout/flow.lua` and any other layout-family measurement entry points
   each layout family must either define axis-specific `fill` support explicitly or reject it deterministically
5. runtime / delegated internal containers
   `Stage`, `Scene`, `ScrollableContainer`, and overlay/control internals that currently rely on `fill` need an explicit sanctioned contract path or a refactor away from generic `Container` self-resolution
6. validation surface
   `lib/ui/utils/schema.lua` and any parent-aware validation path must distinguish "accepted prop token" from "valid in this parent-child pairing"
7. spec and regression tests
   tests that currently assert generic `fill` self-resolution need to be rewritten around supported parent contracts, and new tests should cover deterministic invalid-parent diagnostics
8. warning / diagnostic behavior
   invalid `fill` under unsupported parents should emit a deterministic diagnostic
