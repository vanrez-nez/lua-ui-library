# Container.lua - Function Documentation

## Overview

`Container` is the foundational UI component class in the lua-ui-library system. It provides:
- Spatial transformation (position, scale, rotation, skew)
- Hierarchical scene graph management
- Dirty-propagation invalidation system
- Clipping and rendering pipeline
- Hit testing and event dispatch
- Responsive property overrides
- Motion/animation integration

**Inheritance:** `Container` extends `EventDispatcher` and implements `DirtyProps`

---

## Constants and Configuration

### `QUAD_FAMILIES` [pure: true]
Defines four quad-based property families (`padding`, `margin`, `safeAreaInsets`, `borderWidth`, `cornerRadius`) with their aggregate keys, member keys, and factory functions for resolution.

### `QUAD_KEY_TO_FAMILY` [pure: true]
Maps individual property keys (e.g., `paddingTop`, `cornerRadiusTopLeft`) to their family names for quick lookup during value resolution.

### `QUAD_MEMBER_ACCESSOR` [pure: true]
Maps specific property keys to their accessor names within resolved quad objects (e.g., `paddingTop` → `top`).

### `side_scratch_layer_1`, `side_scratch_layer_2`, `corner_scratch_layer_1`, `corner_scratch_layer_2` [pure: true]
Reusable scratch tables for quad resolution to avoid per-call allocations.

---

## Dirty Propagation Functions

### `invalidate_world(self)` [calls: `RootCompositor.invalidate_node_plan`, `mark_dirty`, pure: false]
Invalidates world-space caches when the container's world transform changes. Marks `world_transform`, `bounds`, and `world_inverse` as dirty and notifies the compositor to recompute the render plan.

### `_check_parent_invalidation(self)` [calls: `mark_dirty`, `mark_layout_node_dirty`, pure: false]
Pull-based parent invalidation check. Compares cached parent references (`_parent_world_ref`, `_parent_resolved_w`, `_parent_resolved_h`) against current parent state. Marks `world_transform`, `bounds`, `world_inverse`, `responsive`, and `measurement` dirty if parent has changed. O(1) per child.

### `notify_stage_subtree_change(self, stage, handler_name, child, parent)` [calls: `get_root`, pure: false]
Notifies the stage of subtree attachment/detachment events. Validates that `stage` is a Stage instance and that no subtree is being destroyed before invoking the stage handler.

### `invalidate_stage_update_token(self)` [pure: false]
Marks the root's `_update_ran` flag as false if the root is a Stage instance, forcing a stage-managed update on the next tick.

### `mark_layout_node_dirty(self)` [calls: `is_layout_node`, `group_dirty`, `mark_dirty`, `invalidate_stage_update_token`, pure: false]
Marks a layout node as needing layout recalculation. Returns early if already dirty or not a layout node. Returns `true` if the node was newly marked dirty.

---

## Hierarchy and Sync Functions

### `walk_hierarchy(cls, key)` [pure: true]
Walks up the class inheritance chain to find a value defined on any superclass. Used for finding overridden methods in the class hierarchy.

### `ensure_current(node)` [calls: `get_root`, `walk_hierarchy`, pure: false]
Ensures the container hierarchy is up-to-date before reading properties. Calls `_synchronize_for_read` on Stage roots or falls back to `update()` for non-stage roots.

### `get_declared_rule(self, key)` [pure: true]
Returns the schema rule for a given property key from the container's `_declared_props` table.

### `resolve_quad_value(self, family_name, requested_key)` [calls: `Styling.requires_resolution`, `CornerQuad.resolve_layers`/`SideQuad.resolve_layers`, `fill_*_quad_layer`, pure: false]
Resolves quad-based properties (padding, margin, border, corner radius) by merging responsive overrides with base values. Returns either the full quad object (if requesting aggregate key) or a specific member value.

### `get_effective_value(self, key)` [calls: `Styling.requires_resolution`, `resolve_quad_value`, pure: false]
Resolves the effective value of a property, accounting for responsive overrides. For quad properties, delegates to `resolve_quad_value`. For other properties, checks `_resolved_responsive_overrides` first, then falls back to raw value.

### `sync_resolved_cache(self)` [calls: `get_effective_value`, pure: false]
Syncs the `_resolved_pdata` cache with current effective values for all declared properties that have table-type rules.

### `Container._get_public_read_value` [alias: `get_effective_value`]
Public alias for external components to read fully-resolved property values.

---

## Size and Transform Resolution

### `axis_fill_supported_by_parent(self, axis_key)` [calls: `get_root`, pure: true]
Determines if a parent supports `fill` sizing for the given axis. Returns `true` if parent is a Stage, Layout, or has explicitly declared a fill contract.

### `resolve_fill_axis_size(self, axis_key, parent_size)` [calls: `axis_fill_supported_by_parent`, `Assert.fail`, pure: false]
Resolves `fill` sizing to the parent's size. Throws an assertion error if the parent does not support fill sizing for the requested axis.

### `resolve_measurement_axis_size(self, axis_key, configured, parent_size)` [calls: `resolve_fill_axis_size`, `resolve_axis_size`, pure: false]
Resolves a measurement axis based on the configured value. Delegates to `resolve_fill_axis_size` for `fill` mode, otherwise uses standard axis resolution.

### `refresh_measurement(self)` [calls: `_get_effective_content_rect`, `clamp_number`, `resolve_measurement_axis_size`, `clear_dirty`, pure: false]
Computes the resolved width and height based on parent constraints, min/max clamps, and fill/percentage modes. Updates `_resolved_width`, `_resolved_height`, and `_local_bounds_cache`.

### `refresh_local_transform(self)` [calls: `_get_effective_content_rect`, `resolve_axis_size`, `Matrix.set_from_transform`, `clear_dirty`, pure: false]
Builds the local transform matrix from position, pivot, anchor, scale, rotation, and skew properties. Accounts for layout offsets and parent content size.

### `refresh_world_transform(self)` [calls: `Matrix.set`, `mark_dirty`, `clear_dirty`, pure: false]
Concatenates parent world transform with local transform to compute the world transform. For root nodes, copies local transform directly. Marks `world_inverse` as dirty after completion.

### `refresh_bounds(self)` [calls: `walk_hierarchy`, `_get_world_bounds_points`, `Rectangle.bounding_box`, `Matrix.transform_point`, `clear_dirty`, pure: false]
Computes the world-space bounding box by transforming the four local corners through the world matrix. Uses custom bounds method if defined by subclass, otherwise defaults to corner transformation.

### `refresh_child_order_cache(self)` [calls: `get_effective_value`, `table.sort`, `clear_dirty`, pure: false]
Sorts children by `zIndex` (stable sort preserving insertion order for ties). Updates `_ordered_children` cache.

### `mark_parent_order_dirty(self)` [calls: `mark_dirty`, pure: false]
Marks the parent's `child_order` as dirty, triggering a re-sort of siblings on next refresh.

### `resolve_world_inverse(self)` [calls: `Matrix.inverse`, `group_dirty`, `clear_dirty`, pure: false]
Lazily computes the inverse of the world transform matrix. Caches the result and any error message. Returns inverse matrix and error string.

---

## Hit Testing and Clipping

### `contains_world_point(self, x, y)` [calls: `resolve_world_inverse`, `Rectangle.contains_point`, pure: false]
Tests if a world-space point is within the container's local bounds. Transforms the point to local space using the inverse world matrix before testing.

### `point_within_active_clips(active_clips, x, y)` [calls: `contains_world_point`, pure: false]
Tests if a world-space point is within all active clipping regions. Returns `false` if any clip does not contain the point.

### `get_world_clip_points(self, points)` [calls: `Matrix.transform_point`, pure: false]
Computes the four corner points of the container in world space. Reuses the provided `points` table if available, otherwise allocates a new one.

### `is_axis_aligned_edge(first, second)` [pure: true]
Tests if two points form an axis-aligned edge by checking if either X or Y coordinates are equal within epsilon tolerance.

### `is_axis_aligned_clip(self, clip_state)` [calls: `get_world_clip_points`, `is_axis_aligned_edge`, pure: false]
Determines if the container's world-space clip region is axis-aligned. Tests all four edges of the transformed bounding box.

### `get_world_clip_rect(self)` [pure: true]
Returns the world-space bounding rectangle (`_world_bounds_cache`).

### `has_degenerate_clip(self)` [calls: `Rectangle.is_empty`, `Matrix.is_invertible`, pure: false]
Returns `true` if the container has a degenerate (zero-area) clip region due to empty local bounds or non-invertible world transform.

### `clear_array_tail(values, last_index)` [pure: false]
Clears all elements in an array from `last_index + 1` to the end. Used for recycling scratch tables.

### `get_empty_scissor_rect(clip_state)` [pure: false]
Returns or creates a zero-sized scissor rectangle `{x=0, y=0, width=0, height=0}`. Used for degenerate clips that should render nothing.

### `get_scissor_scratch_rect(clip_state, depth)` [pure: false]
Returns or creates a scratch rectangle for the given clip depth. Used for intersecting scissor rects without allocations.

### `copy_rect_into(target, source)` [pure: false]
Copies rectangle properties from source to target. Returns target.

### `intersect_rect_into(target, first, second)` [calls: `max`, `min`, pure: false]
Computes the intersection of two rectangles and stores the result in target. Returns target with clamped dimensions (zero if no overlap).

### `resolve_axis_aligned_scissor(clip_state, clip_rect)` [calls: `get_scissor_scratch_rect`, `intersect_rect_into`, `copy_rect_into`, pure: false]
Intersects the current scissor rect with a new clip rect. Uses per-depth scratch space to allow nested branches to restore parent state.

### `draw_clip_polygon(graphics, self, clip_state)` [calls: `get_world_clip_points`, `clear_array_tail`, `graphics.polygon`, pure: false]
Flattens the four corner points into a coordinate array and draws a filled polygon. Used for stencil-based clipping.

### `draw_subtree_scissor(self, graphics, draw_callback, clip_state, render_state)` [calls: `resolve_axis_aligned_scissor`, `set_scissor_rect`, `draw_callback`, `_draw_children`, pure: false]
Draws the container subtree using scissor clipping. Pushes the container onto the active clips stack, intersects scissor rects, draws the container and children, then restores previous scissor state.

### `draw_subtree_stencil(self, graphics, draw_callback, clip_state, render_state)` [calls: `set_stencil_test`, `graphics.stencil`, `draw_clip_polygon`, `draw_callback`, `_draw_children`, pure: false]
Draws the container subtree using stencil buffer clipping. Increments stencil value within the clip polygon, sets equal comparison, draws container and children, then decrements to restore.

### `draw_subtree_plain(self, graphics, draw_callback, clip_state, render_state)` [calls: `draw_callback`, `_draw_children`, pure: false]
Draws the container subtree without any clipping. Used when `clipChildren` is false.

### `_draw_children(node, graphics, draw_callback, clip_state, render_state)` [calls: `draw_subtree`, pure: false]
Iterates over ordered children and draws each subtree.

### `Container._resolve_root_compositing_extras()` [pure: true]
Stub method for subclasses to provide compositing extras. Returns `nil` by default.

### `Container._resolve_root_compositing_world_paint_bounds()` [pure: true]
Stub method for subclasses to provide world paint bounds. Returns `nil` by default.

### `Container._resolve_root_compositing_result_clip()` [pure: true]
Stub method for subclasses to provide result clip. Returns `nil` by default.

### `ROOT_COMPOSITOR_RUNTIME` [pure: true]
Runtime adapter object providing closure-bound functions for the root compositor to interact with container internals.

### `draw_subtree(self, graphics, draw_callback, clip_state, render_state)` [calls: `RootCompositor.initialize_render_state`, `RootCompositor.resolve_node_plan`, `RootCompositor.plan_requires_isolation`, `RootCompositor.draw_isolated_subtree`, `draw_subtree_scissor`, `draw_subtree_stencil`, `draw_subtree_plain`, pure: false]
Main entry point for drawing a container subtree. Handles visibility checks, root compositing isolation decisions, and dispatches to the appropriate clipping strategy (scissor, stencil, or plain).

### `find_hit_target(self, x, y, layer_eligible, effective_visible, effective_enabled, active_clips)` [calls: `point_within_active_clips`, `contains_world_point`, `_is_effectively_targetable`, pure: false]
Recursive hit test function. Traverses children in reverse z-order (top-most first), testing visibility, enabled state, clip containment, and targetability. Returns the top-most hit target or `nil`.

### `_is_effectively_targetable(self, x, y, state)` [calls: `point_within_active_clips`, `contains_world_point`, pure: false]
Determines if the container is targetable at a given world-space point. Checks `interactive`, `visible`, `enabled` properties and clip containment.

### `_hit_test(self, x, y, state)` [calls: `ensure_current`, `_hit_test_resolved`, pure: false]
Public hit test entry point. Ensures the container is up-to-date before delegating to `_hit_test_resolved`.

### `_hit_test_resolved(self, x, y, state)` [calls: `find_hit_target`, pure: false]
Low-level hit test that assumes the container is already synchronized. Delegates to `find_hit_target`.

---

## Tree Management Functions

### `detach_child(parent, child)` [calls: `find_child_index`, `get_root`, `deregister_subtree_ids`, `table.remove`, `assign_attachment_root_recursive`, `rebuild_attachment_root_index`, `invalidate_world`, `notify_stage_subtree_change`, pure: false]
Removes a child from its parent. Updates attachment roots, rebuilds ID indices, marks transforms dirty, and notifies the stage of the detachment.

### `destroy_subtree(node)` [calls: `detach_child`, `destroy`, pure: false]
Destroys an entire subtree. Sets `_destroying_subtree` flag, detaches from parent, and recursively destroys all children. Clears array references to allow GC.

### `_init_state_fields(self, config)` [calls: `EventDispatcher.constructor`, `DirtyProps.init`, `reset_dirty_props`, pure: false]
Initializes all state fields for a new container instance, including transform caches, bounds, dirty props configuration, and motion state.

### `_init_schema(self, extra_public_keys)` [calls: `Utils.merge_tables`, `Schema`, `ContainerPropertyViews.install`, pure: false]
Initializes the schema system by merging base schema with extra keys, creating the Schema instance, and installing property views.

### `_init_hooks()` [pure: true]
Placeholder for schema hooks. Currently a no-op as DirtyProps sync handles change detection.

### `_apply_opts(self, opts, declared_props, schema_props)` [calls: `Assert.fail`, `ContainerPropertyViews.write_extra`, pure: false]
Applies constructor options to the container. Validates that all provided keys are declared, then sets schema properties or extra properties accordingly.

### `_initialize(self, opts, extra_public_keys, config)` [calls: `_init_state_fields`, `_init_schema`, `_init_hooks`, `_apply_opts`, `mark_dirty`, `register_node_id_with_root`, `sync_resolved_cache`, pure: false]
Main constructor entry point. Initializes state, schema, applies options, marks all caches as dirty, and syncs the resolved cache.

### `constructor(self, opts, extra_public_keys, config)` [calls: `_initialize`, pure: false]
Instance constructor that delegates to `_initialize`.

### `Container.new(opts)` [calls: `Container`, pure: false]
Static factory method for creating new container instances.

### `Container._allow_fill_from_parent(node, axes)` [calls: `assert_live_container`, `Assert.table`, pure: false]
Declares that a node is allowed to use `fill` sizing from its parent for the specified axes. Sets `_fill_parent_contract`.

### `Container._allow_child_fill(node, axes)` [calls: `assert_live_container`, `Assert.table`, pure: false]
Declares that a node allows its children to use `fill` sizing for the specified axes. Sets `_child_fill_contract`.

### `refresh_responsive(self)` [calls: `clear_dirty`, pure: false]
Clears the responsive dirty flag. Placeholder for future responsive resolution logic.

### `_apply_resolved_size(self, width, height)` [calls: `default`, `clear_dirty`, `mark_dirty`, `invalidate_world`, `_refresh_layout_content_rect`, `mark_layout_node_dirty`, pure: false]
Applies resolved dimensions to the container. Returns `true` if size changed, triggering layout invalidation for layout nodes.

### `_apply_content_measurement(self, width, height)` [calls: `get_effective_value`, `clamp_number`, `_apply_resolved_size`, pure: false]
Applies content-based measurements when width/height are set to `content` mode. Clamps against min/max constraints.

### `_refresh_if_dirty(self)` [calls: `sync_dirty_props`, `_check_parent_invalidation`, `refresh_responsive`, `refresh_measurement`, `refresh_local_transform`, `refresh_world_transform`, `refresh_bounds`, `refresh_child_order_cache`, `reset_dirty_props`, pure: false]
Main refresh pipeline. Checks and refreshes each dirty group in dependency order: responsive → measurement → local_transform → world_transform → bounds → child_order.

### `_prepare_for_layout_pass(self)` [calls: `sync_dirty_props`, `_check_parent_invalidation`, `refresh_responsive`, `refresh_measurement`, `refresh_child_order_cache`, `reset_dirty_props`, pure: false]
Prepares the container for a layout pass by refreshing measurement-related dirty groups. Returns self for chaining.

### `update(self, _)` [calls: `get_root`, `_refresh_if_dirty`, pure: false]
Main update loop. Resolves responsive behavior if not stage-managed, refreshes dirty caches, and recursively updates children using a snapshot to handle mutations during traversal.

---

## Child Management API

### `addChild(self, child)` [calls: `assert_live_container`, `assert_no_cycle`, `validate_subtree_attach_identity`, `detach_child`, `assign_attachment_root_recursive`, `register_subtree_ids`, `mark_dirty`, `invalidate_stage_update_token`, `notify_stage_subtree_change`, pure: false]
Adds a child to the container. Validates the child, handles reparenting, updates attachment roots and ID indices, and marks caches dirty.

### `removeChild(self, child)` [calls: `assert_live_container`, `detach_child`, pure: false]
Removes a child from the container. Delegates to `detach_child`.

### `getChildren(self)` [calls: `Utils.copy_array`, pure: false]
Returns a copy of the children array.

---

## Lookup Functions

### `findById(self, id, depth)` [calls: `ensure_current`, `validate_lookup_key`, `validate_depth_argument`, `is_public_node`, `get_root`, `is_strict_descendant_of`, `find_by_id_bounded`, pure: false]
Finds a descendant by ID. Supports bounded depth search or full tree search (`depth = -1`). Uses root's `_id_index` for O(1) lookup on full tree searches.

### `findByTag(self, tag, depth)` [calls: `ensure_current`, `validate_lookup_key`, `validate_depth_argument`, `find_by_tag_bounded`, pure: false]
Finds all descendants with a matching tag. Returns an array of matches. Supports bounded depth search.

### `_get_ordered_children(self)` [calls: `ensure_current`, `Utils.copy_array`, pure: false]
Returns a copy of the z-order sorted children array.

---

## Transform API

### `getWorldTransform(self)` [calls: `ensure_current`, `Matrix.clone`, pure: false]
Returns a clone of the world transform matrix.

### `getLocalBounds(self)` [calls: `ensure_current`, `Rectangle.clone`, pure: false]
Returns a clone of the local bounds rectangle.

### `getWorldBounds(self)` [calls: `ensure_current`, `Rectangle.clone`, pure: false]
Returns a clone of the world bounds rectangle.

### `getBounds(self)` [calls: `getWorldBounds`, pure: false]
Alias for `getWorldBounds`.

### `localToWorld(self, x, y)` [calls: `ensure_current`, `Matrix.transform_point`, pure: false]
Transforms a point from local space to world space.

### `worldToLocal(self, x, y)` [calls: `ensure_current`, `resolve_world_inverse`, `Assert.fail`, `Matrix.transform_point`, pure: false]
Transforms a point from world space to local space using the inverse world matrix. Throws if the matrix is not invertible.

### `containsPoint(self, x, y)` [calls: `ensure_current`, `contains_world_point`, pure: false]
Tests if a world-space point is within the container's bounds.

---

## Drawing API

### `_draw_subtree(self, graphics, draw_callback)` [calls: `ensure_current`, `_draw_subtree_resolved`, pure: false]
Public drawing entry point. Validates arguments, defaults graphics to `love.graphics` if unavailable, and delegates to `_draw_subtree_resolved`.

### `_draw_subtree_resolved(self, graphics, draw_callback)` [calls: `Assert.fail`, `get_stencil_test`, `RootCompositor.initialize_render_state`, `draw_subtree`, pure: false]
Low-level drawing function that assumes the container is already synchronized. Initializes render state and clip state, then draws the subtree.

### `markDirty(self)` [calls: `invalidate_stage_update_token`, `mark_dirty`, `invalidate_world`, pure: false]
Coarse fallback that marks all major caches as dirty. Prefer targeted dirty calls where context is available.

### `_set_layout_offset(self, x, y)` [calls: `Assert.number`, `mark_dirty`, `invalidate_world`, pure: false]
Sets the layout offset for the container. Used by layout systems to position children.

### `_mark_parent_layout_dependency_dirty(self)` [calls: `mark_layout_node_dirty`, `mark_dirty`, `invalidate_world`, pure: false]
Marks layout and measurement caches as dirty for parent dependency updates.

### `_get_effective_content_rect(self)` [calls: `Rectangle`, pure: false]
Returns the effective content rectangle, accounting for the resolved size. Caches the result for reuse.

### `_set_measurement_context(self, width, height)` [calls: `Assert.number`, `invalidate_stage_update_token`, `mark_dirty`, `invalidate_world`, pure: false]
Sets the measurement context for root containers. Used when the container is not parented but needs constrained sizing.

### `_set_resolved_responsive_overrides(self, token, overrides)` [calls: `Assert.table`, `get_declared_rule`, `Rule.validate`, `responsive_overrides_affect_root_compositing_plan`, `RootCompositor.invalidate_node_plan`, `invalidate_stage_update_token`, `sync_resolved_cache`, `mark_dirty`, `invalidate_world`, `get_effective_value`, `mark_parent_order_dirty`, pure: false]
Applies responsive overrides to the container. Validates overrides against schema rules, syncs the resolved cache, and invalidates affected caches.

---

## Lifecycle Functions

### `on_destroy(self)` [calls: `destroy_subtree`, pure: false]
Lifecycle hook called when the container is destroyed. Destroys the entire subtree.

---

## Motion Functions

### `_get_motion_surface(self, target_name)` [calls: `Types.is_table`, pure: false]
Returns the motion surface for a given target name. Returns `self` for `nil` or `'root'`, otherwise looks up the property value.

### `_apply_motion_value(self, target_name, property_name, value)` [calls: `_get_motion_surface`, `Assert.fail`, `RootCompositor.motion_property_affects_node_plan`, `RootCompositor.invalidate_node_plan`, pure: false]
Applies a motion value to a property on the target surface. Invalidates the compositor plan if the property affects rendering.

### `_get_motion_value(self, target_name, property_name)` [pure: false]
Returns the current motion state value for a property on the target surface.

### `_raise_motion(self, phase, payload)` [calls: `Motion.request`, pure: false]
Raises a motion event with the given phase and payload. Delegates to the Motion system.

---

## Low-Level Helper Functions

### `is_layout_node(node)` [calls: `Object.is`, pure: true]
Returns `true` if the node is a layout node (either a Layout instance or LayoutNode class).

### `fill_side_quad_layer(target, source, family)` [pure: false]
Fills a side quad layer from a source table. Handles `nil` source by clearing all fields.

### `fill_corner_quad_layer(target, source, family)` [pure: false]
Fills a corner quad layer from a source table. Handles `nil` source by clearing all fields.

### `find_child_index(parent, child)` [pure: false]
Finds the index of a child in the parent's children array. Returns `nil` if not found.

### `assert_live_container(node, name, level)` [calls: `Object.is`, `Assert.fail`, pure: false]
Asserts that a node is a valid Container instance.

### `assert_no_cycle(parent, child, level)` [calls: `Assert.fail`, pure: false]
Asserts that adding `child` to `parent` would not create a cyclic reference.

### `get_root(node)` [pure: false]
Returns the attachment root of a node. Falls back to walking up the parent chain if `_attachment_root` is not set.

### `responsive_overrides_affect_root_compositing_plan(self, previous_overrides, next_overrides)` [calls: `RootCompositor.property_affects_node_plan`, pure: false]
Determines if responsive overrides affect the root compositing plan by checking if any changed properties are compositing-relevant.

### `is_internal_node(node)` [pure: true]
Returns `true` if the node is marked as internal.

### `is_public_node(node)` [calls: `is_internal_node`, pure: true]
Returns `true` if the node is not internal.

### `is_strict_descendant_of(node, ancestor)` [pure: false]
Returns `true` if `node` is a strict descendant of `ancestor`.

### `assign_attachment_root_recursive(node, attachment_root)` [calls: `assign_attachment_root_recursive`, pure: false]
Recursively assigns the attachment root reference to a subtree. Initializes `_id_index` only on the root itself.

### `register_node_id_with_root(node, attachment_root)` [calls: `is_public_node`, pure: false]
Registers a public node's ID in the root's ID index.

### `register_subtree_ids(node, attachment_root)` [calls: `register_node_id_with_root`, `register_subtree_ids`, pure: false]
Recursively registers all public node IDs in a subtree with the root's ID index.

### `deregister_node_id_from_root_value(node, attachment_root, id)` [calls: `is_public_node`, pure: false]
Deregisters a specific ID from the root's ID index.

### `deregister_node_id_from_root(node, attachment_root)` [calls: `deregister_node_id_from_root_value`, pure: false]
Deregisters a node's current ID from the root's ID index.

### `deregister_subtree_ids(node, attachment_root)` [calls: `deregister_node_id_from_root`, `deregister_subtree_ids`, pure: false]
Recursively deregisters all IDs in a subtree from the root's ID index.

### `rebuild_attachment_root_index(root)` [calls: `assign_attachment_root_recursive`, `register_subtree_ids`, pure: false]
Rebuilds the root's ID index from scratch. Used after structural changes.

### `find_sibling_name_collision(node, name, parent)` [calls: `is_public_node`, pure: false]
Finds a sibling with a conflicting name. Returns the colliding sibling or `nil`.

### `validate_name_uniqueness(node, name, parent, level)` [calls: `find_sibling_name_collision`, `Assert.fail`, pure: false]
Asserts that a name is unique among siblings.

### `validate_id_uniqueness_against_root(node, id, attachment_root, ignored_nodes, level)` [calls: `is_public_node`, `Assert.fail`, pure: false]
Asserts that an ID is unique within the attachment root, excluding ignored nodes.

### `validate_subtree_attach_identity(parent, child, level)` [calls: `is_public_node`, `validate_id_uniqueness_against_root`, `validate_name_uniqueness`, pure: false]
Validates that a subtree can be attached without ID or name collisions.

### `validate_depth_argument(method_name, depth, default_depth)` [calls: `Assert.number`, `Assert.fail`, pure: false]
Validates a depth argument for lookup functions. Accepts integers >= -1 or `math.huge`.

### `validate_lookup_key(method_name, key_name, value)` [calls: `Assert.fail`, `Assert.string`, pure: false]
Validates that a lookup key (ID or tag) is a non-empty string.

### `find_by_id_bounded(node, id, depth)` [calls: `is_public_node`, pure: false]
Finds a descendant by ID with bounded depth. Returns the first match or `nil`.

### `find_by_tag_bounded(node, tag, depth, results)` [calls: `is_public_node`, pure: false]
Finds all descendants with a matching tag within bounded depth. Appends matches to the results array.

---

## Call Graph Summary

### Core Refresh Pipeline
```
update()
  └─> _refresh_if_dirty()
        ├─> sync_dirty_props()
        ├─> _check_parent_invalidation()
        ├─> refresh_responsive()
        ├─> refresh_measurement()
        ├─> refresh_local_transform()
        ├─> refresh_world_transform()
        ├─> refresh_bounds()
        ├─> refresh_child_order_cache()
        └─> reset_dirty_props()
```

### Drawing Pipeline
```
_draw_subtree_resolved()
  └─> draw_subtree()
        ├─> RootCompositor.resolve_node_plan()
        ├─> RootCompositor.draw_isolated_subtree()  [if isolated]
        ├─> draw_subtree_scissor()  [axis-aligned]
        ├─> draw_subtree_stencil()  [general]
        └─> draw_subtree_plain()  [no clip]
```

### Hit Testing Pipeline
```
_hit_test_resolved()
  └─> find_hit_target()
        ├─> point_within_active_clips()
        ├─> contains_world_point()
        └─> _is_effectively_targetable()
```

---

## Key Design Patterns

1. **Dirty Propagation** - Bitwise tracking of property changes for O(1) dirty checks
2. **Lazy Evaluation** - Caches computed only when needed (inverse matrix, bounds)
3. **Pull-Based Invalidation** - Children check parent state via stored references
4. **Dual-Path Clipping** - Fast scissor for axis-aligned, stencil for general case
5. **Canvas Pooling** - Reusable off-screen canvases for compositing isolation
6. **Schema-Driven Validation** - All properties validated through Rule system
7. **Motion Surfaces** - Decoupled animation state from visual properties
