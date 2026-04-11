# Task 05: Container Base Migration

## Goal

Rewrite `lib/ui/core/container.lua` so every public property routes through `Proxy` + `Reactive` + `Schema(self)` + `DirtyState`, replacing the current `_public_values`/`_effective_values`/`_set_public_value`/`__newindex` machinery. Responsive-override resolution becomes a `Proxy.on_read` hook — there is no second backing store. Every existing Container spec passes unchanged, and the ten mutation families from `audits/dirty_props_refactor.md` remain fully supported through the existing internal methods, now backed by `Proxy.raw_set`/`Proxy.raw_get`. Once Container has migrated, the legacy `Schema.validate`/`validate_all`/`extract_defaults`/`merge` module functions are removed from `lib/ui/utils/schema.lua`.

## Scope

In scope:

- rewrite `Container:constructor` to build `DirtyState`, `Reactive(self)`, and `Schema(self):define(ContainerSchema)`
- replace `_public_values`/`_effective_values`/`_set_public_value`/`_allowed_public_keys` with the proxy pipeline and a responsive-override read hook
- rewrite the per-prop fan-out in `_set_public_value` as a declarative dependency-class table plus `Reactive:watch` handlers
- rewrite the following internal methods to use `Proxy.raw_set`/`Proxy.raw_get` while preserving their current behavior: `_set_layout_offset`, `_set_measurement_context`, `_set_resolved_responsive_overrides`, `_mark_parent_layout_dependency_dirty`, `markDirty`, `apply_resolved_size`, `apply_content_measurement`, `_refresh_if_dirty`
- consolidate the duplicated `apply_resolved_size`/`apply_content_measurement` fan-out into a shared Container helper that subclasses call
- delete the legacy `Schema.validate`, `Schema.validate_all`, `Schema.extract_defaults`, and `Schema.merge` module functions from `lib/ui/utils/schema.lua`; `Schema.validate_size` either moves into a `Rule.custom` at its single call site or stays as a private helper consumed by that rule
- add container specs covering responsive-override round-trip through the read hook, `_set_layout_offset` bypassing `on_change`, and dirty-flag clearing on refresh

Out of scope:

- migrating `Drawable`, `Shape`, or any layout subclass (tasks 06–07); task 05 leaves subclass constructors untouched except where they must stop writing to `_public_values`/`_effective_values`
- introducing a paint/render dirty domain on Container (flagged as future work)
- changing any public API on Container
- any behavior change in the refresh pipeline or the order in which dirty flags are cleared

## Spec anchors

- [audits/dirty_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/dirty_obj.md)
- [audits/proxy_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/proxy_obj.md)
- [audits/reactive_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/reactive_obj.md)
- [audits/schema_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/schema_obj.md)
- [audits/dirty_props_refactor.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/dirty_props_refactor.md) — ten mutation families; task 05 must preserve all of them.
- Task 00 compliance review — responsive override as `Proxy.on_read` is `spec-sensitive` and the only approved approach; the container dirty set is fixed at eight flags.

## Current implementation notes

- `Container.__newindex` routes writes through `Container:_set_public_value(key, value)`. That method validates against `ContainerSchema`, stores into `self._public_values`, optionally stores into `self._effective_values` when no responsive override is active, and fans out to the per-property dirty flags.
- `Container.__index` consults `self._effective_values` first, then falls through to the class metatable for methods. Every existing spec that reads a container prop observes the effective value.
- The current Container dirty flags are `_measurement_dirty`, `_local_transform_dirty`, `_world_transform_dirty`, `_bounds_dirty`, `_responsive_dirty`, `_layout_dirty`, `_child_order_dirty`, `_world_inverse_dirty`. The new `DirtyState` uses `responsive`, `measurement`, `local_transform`, `world_transform`, `bounds`, `child_order`, `layout`, `world_inverse` — same eight flags.
- `_set_layout_offset(x, y)` writes directly into `_public_values` and `_effective_values` for the offset pair, then marks transform and bounds dirty. Under the new model it uses `Proxy.raw_set` so no `pre_write` runs and no `on_change` watcher fires, preserving the family-4 contract that layout-owned writes bypass schema escalation.
- `_set_resolved_responsive_overrides(token, overrides)` currently writes resolved values into `_effective_values`, leaving `_public_values` untouched. Under the new model the override table becomes the source of truth consulted by the `on_read` hook; `_effective_values` is deleted.
- `apply_resolved_size(width, height)` and `apply_content_measurement(width, height)` are copy-pasted across `drawable.lua`, `flow.lua`, `sequential_layout.lua`, `stack.lua`, and `safe_area_container.lua`. `audits/dirty_props_refactor.md` §5 flags this as the single biggest dedup win; task 05 extracts the helper on `Container`.
- `lib/ui/utils/schema.lua` still exports the legacy module functions after task 04. Task 05 is the first task where Container no longer depends on them, so they can be deleted.

## Work items

- **Constructor rewrite.** In `Container:constructor(opts)`:
  1. Install `self.dirty = DirtyState({'responsive', 'measurement', 'local_transform', 'world_transform', 'bounds', 'child_order', 'layout', 'world_inverse'})`.
  2. Install `self.props = Reactive(self)` so watchers and read hooks share a single proxy surface.
  3. Install `self.schema = Schema(self)` and call `self.schema:define(ContainerSchema)` to declare every public prop, register pre-write validators, and apply defaults.
  4. Register per-key `on_read` hooks for responsive-override resolution: each key that can be overridden by responsive rules gets a hook that checks `self._resolved_responsive_overrides[key]` and returns the override when present, otherwise returns the raw value.
  5. Register per-key watchers from the declarative dependency-class table (see next bullet).
  6. Apply any `opts`-provided values by normal assignment (`self[key] = opts[key]`) so the full pipeline runs once per opt.
  7. Continue to initialize structural fields (`_children`, `_parent`, attachment index) via plain `rawset`; these are not proxy-declared.
- **Declarative fan-out table.** Lift the if/elseif in current `_set_public_value` into a table keyed by prop family — for example `{ measurement = {'width','height','minWidth','maxWidth','minHeight','maxHeight','padding', ...}, transform = {'x','y','scale','rotation','anchor', ...}, zIndex = {'zIndex'}, visible = {'visible'}, other = { ... } }`. For each entry, register a `Reactive:watch(key, handler)` that marks the correct subset of dirty flags and triggers the same ancestor/descendant invalidation the current code does. `measurement` watchers mark `measurement`/`local_transform`/`bounds`, invalidate the stage responsive token, mark ancestor layout dirty, and mark descendant geometry dirty. `transform` watchers mark `local_transform`/`world_transform`/`bounds` and invalidate descendant world. `zIndex` marks parent `child_order`. `visible` marks stage responsive token and ancestor layout. `other` marks `responsive` only. The behavior is identical to the current function; only the source shape changes.
- **Responsive override as read hook.** Add `self._resolved_responsive_overrides = {}` to the constructor. `Proxy.on_read(self, key, function(value) ... end)` for every responsive-eligible key returns `self._resolved_responsive_overrides[key]` when set and `value` (the raw store) otherwise. Store the set of responsive-eligible keys as a constant near `ContainerSchema` so `_set_resolved_responsive_overrides` and the read hook registration agree on the key list. The raw store in `_pdata` always holds the user-authored value; there is no second backing store.
- **Internal methods using `Proxy.raw_set`.** Rewrite the following so internal writes bypass `pre_write`, `on_write`, and `on_change` (family 4, 5, 7, 8, 10 from the inventory):
  - `_set_layout_offset(x, y)` — `Proxy.raw_set(self, 'x', x)`, `Proxy.raw_set(self, 'y', y)`, then `self.dirty:mark('local_transform', 'world_transform', 'bounds')` and the existing descendant-world invalidation.
  - `_set_measurement_context(width, height)` — `Proxy.raw_set(self, '_measurement_context_width', width)` (or whichever field the current code uses), then `self.dirty:mark('measurement', 'local_transform', 'bounds')` plus stage token invalidation. If the measurement context is stored in non-declared fields today, keep them non-declared and use `rawset` directly.
  - `_set_resolved_responsive_overrides(token, overrides)` — update `self._resolved_responsive_overrides = overrides` and `self._responsive_token = token`; `self.dirty:mark('responsive', 'measurement', 'local_transform')` plus stage token invalidation. Read hooks pick up the new overrides on the next read.
  - `_mark_parent_layout_dependency_dirty()` — unchanged in behavior; marks `layout`/`measurement`/`local_transform` via `self.dirty:mark` rather than touching `_*_dirty` booleans.
  - `markDirty()` — coarse fallback, marks the full local dirty set plus stage token plus ancestor layouts (unchanged behavior).
  - `addChild`, `detach_child`, `destroy_subtree` — structural mutations; these operate on non-declared fields (`_children`, `_parent`, attachment index). They continue to use `rawget`/`rawset` and fan out as today.
  - `_refresh_if_dirty` — reads `self.dirty:is_dirty(name)` instead of the current `_*_dirty` booleans; clears each flag via `self.dirty:clear(name)` after its phase. Refresh order is unchanged (`responsive` → `measurement` → `local_transform` → `world_transform` → `bounds` → `child_order` → `layout` → `world_inverse`).
- **`apply_resolved_size` / `apply_content_measurement` helpers.** Extract `Container:_apply_resolved_size(width, height)` and `Container:_apply_content_measurement(width, height)` on the base class. Each helper does the raw writes (`Proxy.raw_set(self, 'width', w)`, `Proxy.raw_set(self, 'height', h)` or the corresponding fields) and the full dirty fan-out that the current copy-pasted code does. `drawable.lua`, `flow.lua`, `sequential_layout.lua`, `stack.lua`, and `safe_area_container.lua` will call these helpers from their own implementations in tasks 06–07; task 05 just lands the base helpers.
- **Schema-level `set` callbacks.** `ContainerSchema` rules that use the `set` option (layout config escalation, safe-area flags, responsive prop normalization — family 2) are already migrated to Rule builders in task 04. The `Schema(self):define(...)` call in the constructor wires each `set` option as an `on_write` hook, so every assignment (including defaults) triggers the side effect. This preserves family-2 behavior byte-for-byte.
- **Remove legacy schema module functions.** Delete `Schema.validate`, `Schema.validate_all`, `Schema.extract_defaults`, and `Schema.merge` from `lib/ui/utils/schema.lua`. `Schema.validate_size` either (a) moves into a `Rule.custom` at its single call site with a private helper inside `rule.lua`, or (b) stays as a small module helper consumed by that `Rule.custom`. Grep the tree before deletion to confirm zero consumers outside `lib/ui/utils/schema.lua` itself.
- **Delete legacy Container fields.** `_public_values`, `_effective_values`, `_set_public_value`, and `_allowed_public_keys` are removed. `Container.__newindex` and `Container.__index` are removed — the proxy metatable installed by `Proxy.declare` replaces them.
- **Container migration specs.** Add `spec/utils/container_proxy_migration_spec.lua` (or an equivalent file inside the existing container spec layout) covering:
  - responsive-override round-trip: set a raw value, call `_set_resolved_responsive_overrides` with an override, confirm the public read returns the override and the raw store still holds the user value
  - `_set_layout_offset` does not fire an `on_change` watcher registered on `x`/`y`
  - `_set_measurement_context` does not fire an `on_change` watcher on measurement-context fields
  - dirty flags cleared on refresh: mark a flag, run the corresponding refresh phase, confirm `self.dirty:is_dirty(flag)` returns `false`
  - schema `set` option escalation: a rule with a `set` callback fires on every public assignment including the initial default

## File targets

- `lib/ui/core/container.lua`
- `lib/ui/utils/schema.lua` (remove legacy module functions)
- `spec/utils/container_proxy_migration_spec.lua` (new; or integrated into the existing container spec layout if there is an established convention)

## Testing

Required runtime verification:

- `love demos/04-graphics` renders identically across the four graphics screens
- at least one demo exercising layout (rows, columns, stacks, flow) renders identically
- at least one demo exercising responsive breakpoints renders identically across a window resize

Required spec verification:

- every spec currently asserting on container property reads, dirty propagation, and refresh ordering
- `spec/container_tree_surface_spec.lua`
- `spec/layout_contract_responsive_surface_spec.lua`
- `spec/safe_area_container_layout_spec.lua`
- `spec/stage_layout_pass_integration_spec.lua`
- the new container migration spec
- full `spec/` suite green with zero edits to existing spec files

## Acceptance criteria

- `Container:constructor` builds `DirtyState`, `Reactive(self)`, and `Schema(self):define(ContainerSchema)`; no reference to `_public_values`, `_effective_values`, `_set_public_value`, or `_allowed_public_keys` remains in `container.lua`.
- The per-prop fan-out is a declarative table plus `Reactive:watch` handlers; no if/elseif chain on key name survives in `Container:_set_public_value` or equivalent.
- Responsive-override resolution is implemented as a `Proxy.on_read` hook reading from `self._resolved_responsive_overrides`; no second backing store exists.
- `_set_layout_offset`, `_set_measurement_context`, `_set_resolved_responsive_overrides`, `_mark_parent_layout_dependency_dirty`, `markDirty`, `_refresh_if_dirty` are all rewritten against the new dirty set and use `Proxy.raw_set`/`Proxy.raw_get` where they previously touched `_public_values`/`_effective_values`.
- `Container:_apply_resolved_size` and `Container:_apply_content_measurement` exist on the base class and encapsulate the raw writes plus dirty fan-out; subclass migration in tasks 06–07 will call them.
- `Schema.validate`, `Schema.validate_all`, `Schema.extract_defaults`, and `Schema.merge` are gone from `lib/ui/utils/schema.lua`; grep across `lib/ui/` and `spec/` returns zero hits for the removed names.
- Every existing container-related spec passes with zero edits.
- The ten mutation families from `dirty_props_refactor.md` are all preserved: family 1 (public writes) through the proxy pipeline; family 2 (schema `set` escalation) through `on_write`; family 3 (structural) through direct table edits on non-declared fields; families 4, 5, 7, 8, 10 through the internal methods using `Proxy.raw_set`; family 6 (parent-region dependency) through `_mark_parent_layout_dependency_dirty`; family 9 (coarse fallback) through `markDirty()`.
