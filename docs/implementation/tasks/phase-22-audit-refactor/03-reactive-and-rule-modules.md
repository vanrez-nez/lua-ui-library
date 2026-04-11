# Task 03: Reactive And Rule Modules

## Goal

Introduce `Reactive` as a verbatim port of `audits/reactive_obj.md` and `Rule` as the full builder set from `audits/schema_refactor_proposal.md` §2.1, including validation tier support. Neither module is wired into any class in this task. `Rule.tier_passes` and the `Schema.VALIDATION_TIER` module flag are added to the current `Schema` module in a backward-compatible way so no existing rule breaks.

## Scope

In scope:

- create `lib/ui/utils/reactive.lua` from `audits/reactive_obj.md`
- create `lib/ui/utils/rule.lua` implementing every builder in `audits/schema_refactor_proposal.md` §2.1
- add `Schema.VALIDATION_TIER` module flag and tier gating inside the existing `Schema.validate` so rules with `tier` higher than the active ceiling return the value unchanged
- add new specs for both modules, including strict error-message parity tests

Out of scope:

- migrating any `*_schema.lua` file to Rule builders (task 04)
- the `Schema(instance)` binding (task 04)
- any class wiring (tasks 05–09)
- changing default validation behavior; `Schema.VALIDATION_TIER` defaults to `'heavy'` so every existing rule runs exactly as today

## Spec anchors

- [audits/reactive_obj.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/reactive_obj.md)
- [audits/schema_refactor_proposal.md](/Users/vanrez/Documents/game-dev/lua-ui-library/audits/schema_refactor_proposal.md) §2.1–§5
- Task 00 compliance review — error message parity is a stop condition for this task

## Current implementation notes

- `audits/schema_refactor_proposal.md` §2.1 lists 13 builders: `enum`, `number`, `boolean`, `color`, `opacity`, `instance`, `table`, `any`, `string`, `normalize`, `custom`, `gate`, `controlled_pair`.
- §3 defines three tiers: `always` (always runs; used when the validator produces a transformed value the system needs, e.g. `Color.resolve`), `dev` (pure checks skippable in production), `heavy` (opt-in deep structural checks).
- §3.4 assigns default tiers: `color`, `normalize`, `custom` that transforms → `always`; `enum`, `number`, `boolean`, `string`, `instance`, `controlled_pair`, `gate` → `dev`; gradient/motion deep checks → `heavy`.
- §5.1 describes the rule table shape: `{ validate, type, default, set, required, tier }`. `Rule` builders return tables with `_is_rule = true` so `Schema.define` (task 04) can assert on them.
- Current inline validators scattered across `*_schema.lua` files produce specific error message formats observed by existing specs. Replacing them with Rule builders must reproduce those messages exactly.

## Work items

- **Reactive module.** Create `lib/ui/utils/reactive.lua` as a verbatim port of `audits/reactive_obj.md`. Depends on `lib/ui/utils/proxy.lua` only. API: `Reactive(instance)`, `r:define(prop_defs)`, `r:watch(key, fn)`, `r:unwatch(key, fn)`, `r:raw_get(key)`, `r:raw_set(key, value)`. `define` accepts `{[key] = { default, get }}`; `get` registers as a `Proxy.on_read` transform; `default` passes through to `Proxy.declare`.
- **Rule module.** Create `lib/ui/utils/rule.lua` with every builder listed above. Each builder returns a rule table with `_is_rule = true` and the fields documented in §5.1. Each builder accepts an optional `opts` table (or trailing arguments where the audit example uses them) to set `default`, `set`, `required`, and `tier`.
  - `Rule.enum(allowed, default, opts)` — pre-computes a lookup table from the `allowed` array at builder time; validator does a single table index. Error message format: `'<key> must be one of: <v1, v2, ...>; got <value>'` or whatever format the current inline validators produce — match exactly.
  - `Rule.number(opts)` — supports `min`, `max`, `min_exclusive`, `max_exclusive`, `finite`, plus `default`, `set`, `required`, `tier`.
  - `Rule.boolean(default)` — accepts a plain default as a shorthand; optional `opts` table for the side fields.
  - `Rule.color(default)` — tier `'always'`; wraps `Color.resolve` at validation time and returns the resolved color.
  - `Rule.opacity(default)` — tier `'dev'` by default; range check `[0, 1]`.
  - `Rule.instance(classes, msg)` — accepts one class or an array; delegates to `Types.is_instance`; tier `'dev'`.
  - `Rule.table()`, `Rule.any()`, `Rule.string(opts)` — type checks using `lib/ui/utils/assert.lua`. `string` accepts `non_empty`.
  - `Rule.normalize(normalizer, opts)` — tier `'always'`; calls the supplied normalizer (e.g. `Insets`, `SideQuad`, `CornerQuad`) and returns the normalized value.
  - `Rule.custom(fn, opts)` — escape hatch; tier defaults to `'dev'` unless `opts.tier` is set.
  - `Rule.gate(predicate, inner_rule)` — runs `predicate(key, value, ctx, opts)` first; if it does not throw, delegates to `inner_rule`.
  - `Rule.controlled_pair(value_key, callback_key)` — asserts either both are present or neither; tier `'dev'`.
- **Tier plumbing.** Add `Schema.VALIDATION_TIER = 'heavy'` to `lib/ui/utils/schema.lua`. Add `Rule.tier_passes(rule_tier)` to `lib/ui/utils/rule.lua` returning `true` when `rule_tier == nil` (default `always`) or when the tier priority is `<=` the active ceiling (`always = 0`, `dev = 1`, `heavy = 2`). In the existing `Schema.validate`, add an early-return gate: if `rule.tier` is present and `Rule.tier_passes(rule.tier)` returns `false`, return `value` unchanged before running any validation. Rules without `tier` default to `always` and always run, preserving current behavior.
- **Reactive spec.** Create `spec/utils/reactive_spec.lua` covering: `define` with default only, `define` with `get` transform, `define` with both, `watch` firing only on `new ~= old`, `watch` passing `(new, old, key, instance)`, `unwatch` removing by function identity, `raw_get` bypassing `get`, `raw_set` bypassing `pre_write` and `on_change`.
- **Rule spec.** Create `spec/utils/rule_spec.lua` covering every builder's happy path and failure path, including:
  - `Rule.enum` accepting a value in the set and rejecting one outside
  - `Rule.number` happy path and failure for each of `min`, `max`, `min_exclusive`, `max_exclusive`, `finite`
  - `Rule.color` calling `Color.resolve` and returning the resolved color
  - `Rule.opacity` accepting `0`, `1`, and values in between; rejecting `-0.1` and `1.1`
  - `Rule.instance` with a single class and an array of classes
  - `Rule.table`, `Rule.any`, `Rule.string` (with `non_empty`)
  - `Rule.normalize` calling the supplied normalizer
  - `Rule.custom` running the supplied function
  - `Rule.gate` running the predicate before the inner rule
  - `Rule.controlled_pair` failing when only one side is present
  - tier gating: with `Schema.VALIDATION_TIER = 'always'`, a `'dev'` rule does not run and returns the value unchanged; with `'dev'`, both `'always'` and `'dev'` run; with `'heavy'`, all three run.
  - error message parity: for each builder whose current inline predecessor is observable through an existing spec, a spec that constructs the equivalent Rule builder and asserts the error message matches byte-for-byte.

## File targets

- `lib/ui/utils/reactive.lua` (new)
- `lib/ui/utils/rule.lua` (new)
- `lib/ui/utils/schema.lua` (add `VALIDATION_TIER` flag and tier gate in `Schema.validate`; legacy module functions otherwise unchanged)
- `spec/utils/reactive_spec.lua` (new)
- `spec/utils/rule_spec.lua` (new)

## Testing

Required runtime verification:

- none; neither module is wired into runtime code.

Required spec verification:

- new `spec/utils/reactive_spec.lua` passes
- new `spec/utils/rule_spec.lua` passes
- full existing `spec/` suite remains green with no edits; the tier gate default of `'heavy'` preserves current behavior
- any existing spec that observes a validator error message must continue to pass without edits; if it does not, the Rule builder is wrong and must be fixed

## Acceptance criteria

- `Reactive` source matches `audits/reactive_obj.md` verbatim.
- `Rule` exports every builder in `audits/schema_refactor_proposal.md` §2.1 and every builder returns a table with `_is_rule = true` and the documented field set.
- `Schema.VALIDATION_TIER` defaults to `'heavy'`; `Rule.tier_passes` is callable from `Schema.validate` and the tier gate is the first conditional in the function.
- Rule spec covers every builder, every failure path, tier gating, and error-message parity for every observable message.
- Full `spec/` suite passes with zero edits to existing spec files.
