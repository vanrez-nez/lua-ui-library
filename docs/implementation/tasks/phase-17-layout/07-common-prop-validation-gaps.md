# Phase 17 Task 07: Common Prop Validation Gaps

## Goal

Close two spec-update validation gaps that have no implementation or test
coverage:

1. Supplying both `responsive` and `breakpoints` on the same layout-family node
   must fail deterministically (§4.2 Ownership note).
2. Prop defaults for layout-family common props must match the explicit defaults
   table added to §4.2.

## Scope

Primary files:

- `lib/ui/layout/layout_node.lua`
- `lib/ui/layout/layout_node_schema.lua`
- `spec/spacing_layout_contract_spec.lua`

## Work

1. `responsive` + `breakpoints` dual-supply detection:
   - When a layout-family node is constructed with both `responsive` and
     `breakpoints` set to non-`nil` values simultaneously, raise a Hard failure.
   - The check must fire at the earliest knowable point: construction or prop
     write, not deferred to the layout pass.
   Implementation detail:
   - locate where `responsive` and `breakpoints` are both settable on a
     layout-family node
   - add a guard that checks both slots are non-`nil` and raises
   - do not change behavior when only one is supplied
2. Prop defaults audit:
   Verify that each prop resolves to the spec default when omitted:

   | Prop           | Required default |
   |----------------|-----------------|
   | `gap`          | `0`             |
   | `wrap`         | `false`         |
   | `justify`      | `"start"`       |
   | `align`        | `"start"`       |
   | `clipChildren` | `false`         |
   | `responsive`   | `nil`           |

   Correct any mismatch. Do not change any other prop default.

## Concrete Changes

- `lib/ui/layout/layout_node_schema.lua` or `lib/ui/layout/layout_node.lua`
  (whichever owns the `responsive` + `breakpoints` assignment paths):
  - add a co-validation check for the dual-supply case
- Schema or constructor defaults:
  - adjust only the specific entries where the audit finds a mismatch against
    the table above

## Constraints

- Do not change behavior when only `responsive` or only `breakpoints` is
  supplied.
- Do not change any prop's accepted type, accepted values, or validation
  behavior beyond the default corrections.
- The dual-supply guard applies to all layout-family components; do not add it
  only to a single component.

## Acceptance Examples

- `Row { responsive = {}, breakpoints = {} }` must fail deterministically with
  a Hard failure.
- `Row { responsive = {} }` must succeed.
- `Row { breakpoints = {} }` must succeed.
- `Row.new({}).gap` must read `0`.
- `Row.new({}).wrap` must read `false`.
- `Row.new({}).justify` must read `"start"`.
- `Row.new({}).align` must read `"start"`.
- `Row.new({}).clipChildren` must read `false`.

## Exit Criteria

- Dual-supply failure test passes: Hard failure is raised when both
  `responsive` and `breakpoints` are non-`nil` on the same node.
- Defaults audit is complete; each entry in the table above is verified with a
  test; any mismatch is corrected.
