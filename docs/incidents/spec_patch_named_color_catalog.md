# Spec Patch: Remove Fixed Named-Color Enumeration

## Summary

The current styling spec hardcodes a complete named-color catalog:

- `transparent`
- `black`
- `white`
- `red`
- `green`
- `blue`
- `yellow`
- `cyan`
- `magenta`

That creates unnecessary spec rigidity.

Named colors are only one accepted color-input form. The spec already resolves
all accepted color inputs into RGBA, and no other spec document depends on the
current nine-name list as a behavioral contract.

This patch removes the fixed enumeration from the styling spec and replaces it
with a smaller portability guarantee:

- `transparent`
- `black`
- `white`

All other named colors become implementation-defined unless a later revision
standardizes a broader portable catalog.

---

## Dependency Check

The current explicit named-color list is not required by other spec documents.

Within `docs/spec`, the only direct dependencies found are in
[ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md):

- the accepted input-form section in §5.3
- the explicit named-color catalog list in §5.3
- the generic invalid-input case `unsupported named color`

No other spec document relies on specific named colors such as `red`, `green`,
`blue`, `yellow`, `cyan`, or `magenta`.

So removing the explicit enumeration does not create a cross-spec dependency
break.

---

## Problem

The fixed named-color catalog creates three problems.

1. It freezes a tiny palette as normative public API without clear benefit.

2. It makes implementation evolution harder. Any broader palette requires a
   spec revision even when the semantic contract is unchanged: string color
   names resolving to RGBA.

3. It creates false portability expectations for names that are not required by
   any other behavioral contract in the library.

The real stable contract is:

- named-color strings may be accepted
- accepted names resolve to RGBA
- unsupported names fail deterministically

The exact long-form catalog does not need to be fixed in this revision.

---

## Proposed Contract

### Keep Named Colors As An Accepted Input Form

Do not remove named colors as a public color-input form.

Keep this contract:

- numeric RGBA
- hex color strings
- named colors
- `hsl(...)`
- `hsla(...)`

### Remove The Fixed Full Catalog

Delete the explicit full named-color list from §5.3.

Replace it with a minimum guaranteed baseline:

- `transparent`
- `black`
- `white`

These names remain portable and required.

### Make All Other Named Colors Implementation-Defined

Beyond the required baseline, a runtime may support additional named colors.

Those additional names:

- are allowed
- resolve to RGBA the same way as any other accepted color input
- are not portable unless a later revision standardizes them explicitly

Unsupported names still fail deterministically.

---

## Behavioral Rules

### Required Baseline

Every conforming implementation must support:

- `transparent`
- `black`
- `white`

These names are stable public API.

### Optional Additional Names

An implementation may support additional named colors.

Examples:

- larger built-in palettes
- project-specific portable palettes documented outside the core spec

But the core styling spec does not standardize those additional names in this
revision.

### Resolution Semantics

When a named color is supported:

- it resolves to RGBA before final styling resolution
- it behaves identically to any other color input after resolution

### Failure Semantics

If a named color string is not supported by the active implementation:

- it fails deterministically as `unsupported named color`

This preserves the current failure model.

---

## Patch Direction

Patch [ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md) §5.3 like this:

### Replace

```text
Named colors are intentionally narrow in this revision.

The full named-color catalog in this revision is:

- transparent
- black
- white
- red
- green
- blue
- yellow
- cyan
- magenta

The library must not imply any named-color catalog beyond this set unless a later revision documents it explicitly.
```

### With

```text
Named colors are a supported public color-input form in this revision.

The following names are required and portable:

- transparent
- black
- white

Implementations may support additional named colors.
Additional names are implementation-defined unless a later revision standardizes
them explicitly.
```

---

## Rationale

This patch lowers spec rigidity without weakening the important guarantees.

The stable guarantees remain:

- named colors are allowed
- a known baseline exists
- named colors resolve to RGBA
- unsupported names fail deterministically

What changes is only the over-specified long-form catalog.

That is a better fit for the actual abstraction level of the styling contract.

---

## Follow-Up

If this patch is accepted:

1. Update [ui-styling-spec.md](/Users/vanrez/Documents/game-dev/lua-ui-library/docs/spec/ui-styling-spec.md).
2. Decide whether the implementation should:
   - keep the current narrow catalog,
   - expose a larger built-in palette,
   - or move broader named colors into a separate palette module.
3. Ensure implementation docs clearly distinguish:
   - required portable names
   - implementation-defined additional names

