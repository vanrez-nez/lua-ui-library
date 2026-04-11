# Task 08: Stage, ScrollableContainer, Text Migration

## Goal

Migrate the three classes that exercise the two trickiest mutation families from `audits/dirty_props_refactor.md` most heavily: family 8 (controller-owned internal-node mutation) and family 10 (stage environment change). Stage, ScrollableContainer, and Text each own internal child nodes whose positions/sizes are written by the controller code rather than flowing through the public pipeline. Under the new model those writes go through `Proxy.raw_set` / `Reactive:raw_set` on the target node while preserving every current behavior.

## Scope

In scope:

- migrate `lib/ui/scene/stage.lua` and `lib/ui/scene/composer.lua` onto the migrated Container base, binding `StageSchema` and `ComposerSchema` via `self.schema:define(...)`
- rewrite `Stage:resize` and `refresh_environment_bounds` so viewport and safe-area writes go through `Proxy.raw_set` on stage-owned fields
- migrate `lib/ui/scroll/scrollable_container.lua`; internal writes to content node, viewport node, and scrollbar nodes use `Reactive:raw_set` (or `Proxy.raw_set`) on the target node instead of touching legacy backing tables
- migrate `lib/ui/controls/text.lua`; intrinsic-size writes use `Reactive:raw_set(self, 'width', w)` / `Reactive:raw_set(self, 'height', h)` followed by `self:markDirty()`
- audit `lib/ui/scene/transitions.lua` and `lib/ui/scene/scene.lua` for any direct `_public_values`/`_effective_values` access and fix it
- add specs covering: stage environment change round-trip, scroll controller offset write not firing `on_change` watchers on the content node, Text intrinsic-size update not firing `on_change` watchers on the text instance itself

Out of scope:

- controls migration beyond `Text` — task 09 handles the rest of `lib/ui/controls/`
- GPU/frame-hot caching — task 10
- any public API change on Stage, ScrollableContainer, or Text

## Spec anchors

- [audits/dirty_props_refactor.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/dirty_props_refactor.md) — family 8 (controller-owned internal mutation), family 10 (stage environment change)
- Task 00 compliance review — both mutation families are explicitly preserved; no collapse is permitted.

## Current implementation notes

- `lib/ui/scene/stage.lua` owns the viewport and safe-area environment. `Stage:resize(width, height)` currently writes viewport fields directly and then re-resolves responsive tokens across the tree. `refresh_environment_bounds` updates safe-area insets and marks every descendant responsive/measurement/transform dirty. These are family-10 writes — stage-internal fields that do not need to fire `on_change` watchers.
- `lib/ui/scroll/scrollable_container.lua` owns internal content, viewport, and scrollbar child nodes. The controller code sets offsets, sizes, and thumb geometry on these internal nodes directly. Currently each write edits the target's `_public_values` and `_effective_values` in lockstep; under the new model each write is a `Proxy.raw_set(child_node, key, value)` followed by the child's existing dirty marking.
- `lib/ui/controls/text.lua` measures its intrinsic size after text/font/style changes and writes the result back into its own `width`/`height`. The current code writes both `_public_values.width` and `_effective_values.width` then calls `self:markDirty()`. The new pattern is `Reactive:raw_set(self, 'width', w)` + `Reactive:raw_set(self, 'height', h)` + `self:markDirty()`. The intent is that the measured size does not fire the width/height `on_change` watchers a user might register — the public API for setting width/height still fires them normally.
- `lib/ui/scene/composer.lua` mediates between Stage and the render pipeline. Audit it for any legacy backing-table access; migrate as needed.
- `lib/ui/scene/transitions.lua` manipulates node opacity and transform during transitions. It already uses `MathUtils.clamp` after task 01. Audit for any legacy-field writes and migrate.

## Work items

- **Stage.** Rewrite `Stage:constructor(opts)` to delegate to `Container:constructor(opts)` (or the current base, whichever the migrated Container hierarchy dictates) and call `self.schema:define(StageSchema)`. `Stage:resize(width, height)` uses `Proxy.raw_set(self, 'viewport_width', width)` / `Proxy.raw_set(self, 'viewport_height', height)` (or whichever fields the current code writes), then triggers the existing responsive-token resolution and tree-wide dirty fan-out. `refresh_environment_bounds` uses `Proxy.raw_set` for safe-area insets and keeps its existing descendant invalidation loop. The `safeAreaInsets` public prop routes through the schema `set` callback so user-level writes still fire `on_change` watchers.
- **Composer.** Rewrite `Composer:constructor(opts)` to delegate to the migrated Container base and bind `ComposerSchema`. Audit every write in composer for direct legacy-field access and route internal writes through `Proxy.raw_set` where they should not fire watchers, or through normal assignment where they should.
- **ScrollableContainer.** Rewrite `ScrollableContainer:constructor(opts)` to delegate to the migrated Container base and bind `ScrollableContainerSchema`. Controller-owned writes to the internal content node, viewport node, and scrollbar thumb/track nodes all become `Reactive:raw_set(target, key, value)` (or `Proxy.raw_set` if the target does not have a `Reactive` instance attached). After the raw write, call the target's existing dirty-marking method so the layout pass picks up the change. Every behavior — `sync_viewport_size`, `apply_content_offset`, `update_scrollbar_geometry`, thumb drag, wheel scroll — is preserved.
- **Text.** Rewrite `Text:constructor(opts)` to delegate to the migrated Container base and bind the Text-specific schema (if one exists). Rewrite `refresh_intrinsic_size()` so the measured width/height are written via `Reactive:raw_set(self, 'width', w)` + `Reactive:raw_set(self, 'height', h)` + `self:markDirty()`. Public `Text:setText` and style mutators continue to flow through normal assignment so user-facing watchers fire.
- **Transitions audit.** Walk `lib/ui/scene/transitions.lua` for any direct `_public_values`/`_effective_values` reference. Transitions typically write node opacity/scale/rotation during tween steps; those should be normal assignments so any user-registered `on_change` watcher fires as expected. If a transition write was previously going through a raw path, keep it as `Proxy.raw_set`; otherwise use normal assignment.
- **Scene audit.** Same treatment for `scene.lua` — audit and migrate any legacy references.
- **Migration specs.** Add `spec/scene_proxy_migration_spec.lua` (or integrate into existing scene/scroll/text spec layout) covering:
  - stage environment round-trip: `Stage:resize(w, h)` updates the raw store and triggers tree-wide dirty fan-out; a user-registered watcher on `viewport_width` does not fire (it is a raw write) but a user-registered watcher on `safeAreaInsets` does fire when the safe-area prop is set through the public API
  - scroll controller offset write: `ScrollableContainer` internal offset update does not fire an `on_change` watcher registered on the content node's `x`/`y`
  - Text intrinsic size: `Text:setText` → `refresh_intrinsic_size` path does not fire an `on_change` watcher registered on the text instance's `width`/`height`
  - public Text width assignment by the user: `text.width = 100` does fire the watcher

## File targets

- `lib/ui/scene/stage.lua`
- `lib/ui/scene/composer.lua`
- `lib/ui/scene/scene.lua` (audit; rewrite if touching legacy fields)
- `lib/ui/scene/transitions.lua` (audit; rewrite if touching legacy fields)
- `lib/ui/scroll/scrollable_container.lua`
- `lib/ui/controls/text.lua`
- `spec/scene_proxy_migration_spec.lua` (new; or integrated into existing spec layout)

## Testing

Required runtime verification:

- at least one demo exercising `ScrollableContainer` (scroll, wheel, thumb drag) renders and behaves identically
- a demo that triggers a window resize (Stage environment change) re-lays out identically
- a demo with dynamic `Text:setText` calls re-measures and re-lays out identically

Required spec verification:

- `spec/scrollable_container_spec.lua`
- `spec/stage_layout_pass_integration_spec.lua`
- every existing `text`-related spec
- every existing `scene`/`composer` spec
- the new scene migration spec
- full `spec/` suite green with zero edits to existing spec files

## Acceptance criteria

- `Stage:constructor`, `Composer:constructor`, `ScrollableContainer:constructor`, `Text:constructor` all delegate to the migrated Container base and call `self.schema:define(...)`.
- `Stage:resize` and `refresh_environment_bounds` use `Proxy.raw_set` for stage-internal fields; public `safeAreaInsets` prop writes still fire `on_change`.
- Every controller-owned internal write in `ScrollableContainer` uses `Reactive:raw_set` or `Proxy.raw_set`; no write to an internal node's `_public_values` or `_effective_values` remains.
- `Text:refresh_intrinsic_size` writes measured width/height via `Reactive:raw_set` so the measurement pass does not fire user watchers; public width/height assignments still flow through the normal pipeline.
- `lib/ui/scene/` and `lib/ui/scroll/` contain zero references to `_public_values`, `_effective_values`, `_set_public_value`, or `_allowed_public_keys`.
- Every scene/scroll/text spec passes with zero edits.
- Family 8 (controller-owned internal mutation) and family 10 (stage environment change) from `dirty_props_refactor.md` are both still supported, with pointers to the new call sites documented for the task 11 acceptance summary.
