# Task 04: Schema Binding Object And Schema Files Migration

## Goal

Introduce the `Schema(instance):define(...)` binding object from `audits/schema_obj.md` alongside the existing module functions, then rewrite every `*_schema.lua` file to use Rule builders. The binding object is not yet consumed by Container at the end of this task — Container still uses the legacy module functions — but the schemas are already expressed in the new authoring shape so task 05 can land the Container migration against already-ported rule tables.

## Scope

In scope:

- rewrite `lib/ui/utils/schema.lua` so the module exports a callable (`Schema(instance)`) that returns a bound object with a `define(prop_defs)` method
- preserve `Schema.validate`, `Schema.validate_all`, `Schema.extract_defaults`, `Schema.merge`, and `Schema.validate_size` as legacy module functions on the same module table so Container keeps working until task 05
- rewrite every `*_schema.lua` file to use Rule builders from task 03
- consolidate the responsive/breakpoints mutual-exclusion check into a shared `Rule.gate` used by both `container_schema` and `layout_node_schema`
- slim `lib/ui/render/graphics_validation.lua` to constants plus any genuinely complex validators; move simple checks to `Rule.enum`/`Rule.number` at the call site

Out of scope:

- wiring `Schema(instance)` into any class (task 05)
- removing the legacy module functions (task 05 closes this out)
- any behavior change at runtime; every schema spec must pass unchanged

## Spec anchors

- [audits/schema_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/schema_obj.md)
- [audits/schema_refactor_proposal.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/schema_refactor_proposal.md) §2, §6, §7 Phase 2
- Task 00 compliance review — `Schema(instance)` binding and schema files migration are both `spec-sensitive`; error message parity is a stop condition.

## Current implementation notes

- `lib/ui/utils/schema.lua` is a module table with plain functions. After this task it additionally becomes a callable via `setmetatable(Schema, { __call = ... })` that returns a bound object per `audits/schema_obj.md`.
- Every `*_schema.lua` file today returns a plain table `{ [key] = { validate, default, set, required, type } }`. The migration replaces each rule with a Rule builder call, preserving the table shape so existing consumers keep working.
- `container_schema.lua` and `layout_node_schema.lua` both implement the responsive/breakpoints mutual-exclusion check with slightly different inline code. `audits/schema_refactor_proposal.md` §6.4 calls for a shared predicate via `Rule.gate`.
- `graphics_validation.lua` exposes `validate_opacity`, `validate_root_blend_mode`, `validate_source_align`, gradient validators, and motion descriptor validators. `§6.3` proposes slimming this module: simple enum/opacity checks move to `Rule.*` at the call site; gradient and motion validators stay as `Rule.custom` with tier annotations.

## Work items

- **Schema binding object.** Rewrite `lib/ui/utils/schema.lua` so the module table doubles as a constructor. `Schema(instance)` returns `{ _instance = instance }` with metatable `{ __index = Schema }`. `schema:define(prop_defs)` iterates the def table, asserts every value has `_is_rule == true`, calls `Proxy.declare(instance, key)`, and registers `Proxy.on_pre_write(instance, key, validator)` that:
  1. early-returns `value` if `rule.tier` is present and `Rule.tier_passes(rule.tier)` is false
  2. calls `rule.validate(key, value, instance, level)` and uses the returned value if truthy
  3. errors with `('property "%s" is required'):format(key)` at level 3 if `rule.required` and the resolved value is nil
  4. returns the value for the proxy to store
  If the rule has a `set` option, register it as `Proxy.on_write(instance, key, function(v, k, t) rule.set(t, v) end)` so side-effect escalation (family 2 from `dirty_props_refactor.md`) keeps working. If the rule has a `default`, assign it via `instance[key] = rule.default` so the full pipeline runs once.
- **Legacy module functions.** Keep `Schema.validate`, `Schema.validate_all`, `Schema.extract_defaults`, `Schema.merge`, and `Schema.validate_size` on the module table, unchanged except for the tier gate already added in task 03. They continue to serve Container's current `_set_public_value` path until task 05.
- **Shape schema.** Rewrite `lib/ui/core/shape_schema.lua` so every entry is a Rule builder. `fillColor` becomes `Rule.color(...)`, `fillOpacity` becomes `Rule.opacity(1)`, `strokeWidth` becomes `Rule.number({ min = 0, finite = true, default = 0 })`, `strokeStyle` becomes `Rule.enum({ 'smooth', 'rough' }, 'smooth')`, etc. Match every default and every validator's error message against the current inline version.
- **Spacing schema.** Rewrite `lib/ui/core/spacing_schema.lua` using `Rule.normalize` for `Insets`/`SideQuad`/`CornerQuad` entries and `Rule.number` for scalar fields.
- **Drawable schema.** Rewrite `lib/ui/core/drawable_schema.lua`. Background, border, corner radius, shadow, and styling-capable entries become Rule builders. Preserve every `set` callback as the builder's `set` option.
- **Layout schemas.** Rewrite `lib/ui/layout/layout_node_schema.lua` using `Rule.enum`/`Rule.number`/`Rule.custom` and wiring `set = markDirty` through the builder option. Same for `lib/ui/layout/stack_schema.lua`, `row_schema.lua`, `column_schema.lua`, `flow_schema.lua` (these may currently live inside their layout files — migrate in place).
- **Container schema.** Rewrite `lib/ui/core/container_schema.lua`. Consolidate the responsive/breakpoints mutual-exclusion check into a shared predicate used by both container and layout_node schemas via `Rule.gate`. Place the shared predicate in a location both files can import — either at the top of `container_schema.lua` with a re-export, or in a new small helper module under `lib/ui/core/` if the import shape gets awkward.
- **Scroll, stage, composer schemas.** Rewrite `lib/ui/scroll/scrollable_container_schema.lua`, `lib/ui/scene/stage_schema.lua`, `lib/ui/scene/composer_schema.lua` using Rule builders.
- **Direction and responsive helpers.** Update `lib/ui/layout/direction.lua` and `lib/ui/layout/responsive.lua` so their rule factory patterns produce Rule-builder tables instead of the current factory closures.
- **Graphics validation slimming.** Rewrite `lib/ui/render/graphics_validation.lua` per §6.3. Keep constants (`ROOT_BLEND_MODE_VALUES`, `SOURCE_ALIGN_VALUES`, etc.). Move simple validators into `Rule.enum`/`Rule.opacity` at the call site. Gradient and motion descriptor validators stay as `Rule.custom` with `tier = 'heavy'` for the deep structural checks and a companion `Rule.custom` with `tier = 'always'` where a transformed value (e.g. resolved gradient colors) must always flow through.
- **Schema binding spec.** Create `spec/utils/schema_binding_spec.lua` covering: define + set + get round-trip through the proxy, pre-write validation, required-prop failure, default assignment firing pre-write exactly once, the `set` option registering as `on_write` and firing on every assignment, coexistence with `Reactive(self)` on the same instance (pre-write runs before on_change and on_change sees the validated value), and interaction with `Schema.VALIDATION_TIER`.

## File targets

- `lib/ui/utils/schema.lua`
- `lib/ui/core/shape_schema.lua`
- `lib/ui/core/spacing_schema.lua`
- `lib/ui/core/drawable_schema.lua`
- `lib/ui/core/container_schema.lua`
- `lib/ui/layout/layout_node_schema.lua`
- `lib/ui/layout/stack.lua` (if the stack schema lives inside)
- `lib/ui/layout/row.lua`
- `lib/ui/layout/column.lua`
- `lib/ui/layout/flow.lua`
- `lib/ui/layout/direction.lua`
- `lib/ui/layout/responsive.lua`
- `lib/ui/scroll/scrollable_container_schema.lua`
- `lib/ui/scene/stage_schema.lua`
- `lib/ui/scene/composer_schema.lua`
- `lib/ui/render/graphics_validation.lua`
- `spec/utils/schema_binding_spec.lua` (new)

## Testing

Required runtime verification:

- `love demos/04-graphics` renders identically across the four graphics screens
- a demo exercising layout (rows, columns, stacks, flow) renders identically

Required spec verification:

- `spec/shape_primitive_surface_spec.lua`
- `spec/shape_stroke_acceptance_spec.lua`
- `spec/shape_fill_motion_spec.lua`
- `spec/drawable_content_box_surface_spec.lua`
- `spec/styling_resolution_spec.lua`
- `spec/styling_renderer_spec.lua`
- `spec/spacing_layout_contract_spec.lua`
- `spec/layout_contract_responsive_surface_spec.lua`
- `spec/stack_layout_spec.lua`
- `spec/row_column_layout_spec.lua`
- `spec/flow_layout_spec.lua`
- `spec/safe_area_container_layout_spec.lua`
- `spec/scrollable_container_spec.lua`
- `spec/container_tree_surface_spec.lua`
- `spec/stage_layout_pass_integration_spec.lua`
- new `spec/utils/schema_binding_spec.lua`
- full `spec/` suite green with zero edits to any existing spec

## Acceptance criteria

- `Schema(instance):define(prop_defs)` exists and behaves per `audits/schema_obj.md`; the legacy module functions (`validate`, `validate_all`, `extract_defaults`, `merge`, `validate_size`) remain on the same module table.
- Every `*_schema.lua` file contains only Rule-builder calls; zero inline validator closures remain outside `Rule.custom`.
- The responsive/breakpoints mutual-exclusion check is defined exactly once and shared between `container_schema` and `layout_node_schema`.
- `graphics_validation.lua` is slimmed per §6.3: constants remain, simple validators moved to the call site.
- `spec/utils/schema_binding_spec.lua` covers define+set+get, required failure, default firing, side-effect escalation, coexistence with Reactive, and tier interaction.
- Full `spec/` suite passes with zero edits to any existing spec file, including error-message-asserting specs.
