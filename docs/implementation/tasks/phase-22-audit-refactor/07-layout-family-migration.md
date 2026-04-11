# Task 07: Layout Family Migration

## Goal

Migrate the entire layout family — `LayoutNode`, `Stack`, `Row`, `Column`, `Flow`, `SequentialLayout`, `SafeAreaContainer`, plus the rule factory helpers in `direction.lua` and `responsive.lua` — onto the new object model. Drop the copy-pasted `apply_resolved_size` / `apply_content_measurement` implementations across layout files in favor of the base Container helper extracted in task 05 — the single biggest dedup win flagged by `audits/dirty_props_refactor.md` §5. Every layout spec passes unchanged.

## Scope

In scope:

- rewrite `LayoutNode:constructor` to delegate to the migrated Container base and bind `LayoutNodeSchema` via `self.schema:define(...)`
- rewrite `Stack`, `Row`, `Column`, `Flow`, `SafeAreaContainer` constructors to delegate to their migrated bases and merge their own schema rules on top
- delete every per-file copy of `apply_resolved_size` / `apply_content_measurement` and call the base Container helper from task 05
- wire the layout-specific `set` option callbacks (gap, padding, wrap, justify, align, responsive, safe-area apply flags) through Rule builders so `Schema(self)` registers them as `on_write` hooks
- migrate `direction.lua` and `responsive.lua` so their rule-factory exports produce Rule-builder tables instead of the current factory closures
- add layout migration specs for representative layouts confirming identical output pre- and post-migration

Out of scope:

- any change to the layout algorithm itself (gap/padding/wrap/justify/align semantics are unchanged)
- Stage, ScrollableContainer, Text migration — task 08
- Controls migration — task 09
- paint/render dirty domain on LayoutNode (not applicable; LayoutNode is not a Shape)

## Spec anchors

- [audits/dirty_props_refactor.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/dirty_props_refactor.md) §5 — layout-owned resolved-size duplication
- [audits/schema_refactor_proposal.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/schema_refactor_proposal.md) §2, §6 — Rule builders + shared responsive/breakpoints gate
- Task 00 compliance review — layout family migration is `spec-sensitive`; the declarative fan-out decision from task 05 extends down the subclass chain.

## Current implementation notes

- `lib/ui/layout/layout_node.lua` inherits from `Container` and adds gap/padding/wrap/justify/align props. Its current `_set_public_value`-equivalent path fans out to `self:markDirty()` via schema `set` callbacks that are already migrated to Rule builders in task 04.
- `lib/ui/layout/sequential_layout.lua` holds the shared row/column measurement algorithm. It currently has its own copy of `apply_resolved_size` / `apply_content_measurement` invalidation code.
- `lib/ui/layout/stack.lua`, `row.lua`, `column.lua`, `flow.lua`, `safe_area_container.lua` each carry their own `apply_resolved_size` implementation. The bodies are nearly identical: raw-write the resolved width/height, then call the container-level dirty fan-out.
- `lib/ui/layout/safe_area_container.lua` exposes `apply_top`/`apply_bottom`/`apply_left`/`apply_right` props with a helper `set_apply_flag(side, value)`. Under the migrated model, the apply-flag props route through `SafeAreaContainerSchema`'s `set` callback, which calls `markDirty`.
- `lib/ui/layout/direction.lua` and `lib/ui/layout/responsive.lua` currently export factory closures that build validator/normalizer pairs. Task 04 migrated the consuming schemas to Rule builders, so these factories now need to return Rule tables directly instead of closures.
- `content_fill_guard.lua` is a small helper consumed by sequential layout; verify it does not touch `_public_values`/`_effective_values` directly, and if it does, route through `Proxy.raw_get` on the target container.

## Work items

- **LayoutNode constructor.** Rewrite `LayoutNode:constructor(opts)` to delegate to `Container:constructor(opts)`, then call `self.schema:define(LayoutNodeSchema)`. The layout-specific dirty fan-out already runs through the schema `set` options migrated in task 04; no separate watcher registration is needed for most props. If any layout prop needs a watcher that goes beyond a simple `markDirty` escalation, register it via `self.props:watch(key, handler)`.
- **Stack / Row / Column / Flow.** Each subclass constructor delegates to `LayoutNode:constructor(opts)` and calls `self.schema:define(SubclassSchema)` to merge its extra rules. Subclasses drop any direct `_public_values`/`_effective_values` manipulation.
- **Drop duplicated `apply_resolved_size` / `apply_content_measurement`.** Delete the per-file implementations in `stack.lua`, `row.lua`, `column.lua`, `flow.lua`, `sequential_layout.lua`, `safe_area_container.lua`. Each file calls `Container:_apply_resolved_size` / `Container:_apply_content_measurement` from the base helper extracted in task 05. If a subclass needs any additional post-apply step (e.g. sequential layout's per-child placement), keep that step but call the base helper first. This is the largest dedup win in phase-22; audit the call sites afterward to confirm no subclass silently skipped an invalidation step that now needs to move into the base helper.
- **SafeAreaContainer.** Rewrite `SafeAreaContainer:constructor(opts)` to delegate to `LayoutNode:constructor(opts)` (or `Container`, whichever is the current base), call `self.schema:define(SafeAreaContainerSchema)`, and keep `set_apply_flag(side, value)` as a public method. The `applyTop`/`applyBottom`/`applyLeft`/`applyRight` props route through the schema `set` callback — the flag change fires `markDirty` automatically via the `on_write` slot.
- **`direction.lua` / `responsive.lua`.** Update the rule-factory exports so each factory returns a Rule-builder table directly (e.g. `Rule.custom(...)` or `Rule.gate(...)` wrapping the factory's internal predicate). The consuming schema files in task 04 already call these factories; task 07 rewrites the factory bodies so the returned value is a valid Rule table with `_is_rule = true`. Error messages must match the original closures byte-for-byte.
- **`content_fill_guard.lua`.** Audit the file for direct `_public_values`/`_effective_values` access. If it reads through those, switch to plain `container[key]` reads (which go through the proxy pipeline); if it writes, switch to `Proxy.raw_set` if the write is layout-owned, or to normal assignment if the write should flow through the public pipeline.
- **Layout migration specs.** Add `spec/layout_proxy_migration_spec.lua` (or integrate into existing layout spec layout) covering:
  - stack/row/column/flow produce identical measurement and placement output for a fixed set of input fixtures
  - `safe_area_container` `set_apply_flag` fires `markDirty` via the schema `set` callback and the next layout pass produces the expected geometry
  - `direction.lua` and `responsive.lua` Rule factories produce Rule tables accepted by `Schema(self):define(...)`

## File targets

- `lib/ui/layout/layout_node.lua`
- `lib/ui/layout/stack.lua`
- `lib/ui/layout/row.lua`
- `lib/ui/layout/column.lua`
- `lib/ui/layout/flow.lua`
- `lib/ui/layout/sequential_layout.lua`
- `lib/ui/layout/safe_area_container.lua`
- `lib/ui/layout/direction.lua`
- `lib/ui/layout/responsive.lua`
- `lib/ui/layout/content_fill_guard.lua` (audit only; rewrite if touching legacy fields)
- `spec/layout_proxy_migration_spec.lua` (new; or integrated into existing layout spec layout)

## Testing

Required runtime verification:

- at least one demo exercising each of Stack, Row, Column, Flow renders identically
- a demo exercising SafeAreaContainer across a safe-area inset change renders identically

Required spec verification:

- `spec/layout_contract_responsive_surface_spec.lua`
- `spec/stack_layout_spec.lua`
- `spec/row_column_layout_spec.lua`
- `spec/flow_layout_spec.lua`
- `spec/safe_area_container_layout_spec.lua`
- `spec/spacing_layout_contract_spec.lua`
- the new layout migration spec
- full `spec/` suite green with zero edits to existing spec files

## Acceptance criteria

- Every layout-family file constructs through the migrated Container base and calls `self.schema:define(...)` to bind its Rule-backed schema.
- Zero per-file copies of `apply_resolved_size` or `apply_content_measurement` remain in `stack.lua`, `row.lua`, `column.lua`, `flow.lua`, `sequential_layout.lua`, `safe_area_container.lua`; every caller delegates to `Container:_apply_resolved_size` / `Container:_apply_content_measurement`.
- `direction.lua` and `responsive.lua` export Rule-builder tables (or factories returning Rule tables), not plain factory closures.
- SafeAreaContainer's apply-flag props fire `markDirty` through the schema `set` callback; `set_apply_flag` remains a public method.
- Every layout spec passes with zero edits.
- No file in `lib/ui/layout/` references `_public_values`, `_effective_values`, `_set_public_value`, or `_allowed_public_keys`.
