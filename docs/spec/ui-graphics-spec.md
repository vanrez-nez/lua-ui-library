# UI Graphics Specification

> Version `0.1.0` — initial publication. Release history and change management policy: [UI Evolution Specification](./ui-evolution-spec.md).

## 3. Glossary

All terminology defined in [UI Foundation Specification](./ui-foundation-spec.md) is binding in this document.

`Graphics object`: A first-class library artifact that represents image-source data, a region view over image-source data, or a retained presentational image primitive.

`Texture`: A resolved image-source object with intrinsic pixel dimensions.

`Atlas`: A catalog of named regions over one or more textures.

`Sprite`: A resolved drawable view over a texture or atlas region.

## 4. Scope And Domain

This document defines the concrete graphics-object families built on the foundation specification.

This revision owns the following first-class graphics objects:

- `Texture`
- `Atlas`
- `Sprite`
- `Image`

The foundation contracts for render assets, token classes, failure semantics, render effects, theming, and stability remain authoritative and are not redefined here.

## 4A. Graphics Object Classification And Identity

The component-model rules in Section 3A of [UI Foundation Specification](./ui-foundation-spec.md) are binding where they apply to retained primitives. Non-component graphics objects in this document still have stable public contracts and identity boundaries.

| Object | Tier | Sole responsibility | Explicitly does not manage | Boundary type |
|--------|------|---------------------|----------------------------|---------------|
| `Texture` | Asset object | resolved image-source data plus intrinsic dimensions | UI layout, retained interaction, animation playback, atlas lookup policy | fixed |
| `Atlas` | Asset object | named region lookup over one or more textures | UI layout, retained interaction, animation sequencing, display behavior | fixed |
| `Sprite` | Asset object | resolved texture view, including full-texture or region-backed drawable source description | retained UI layout, interaction, animation playback, atlas loading policy | fixed |
| `Image` | Primitive | retained presentation of a `Texture` or `Sprite`, including fit, alignment, and sampling resolution | activation semantics, native loading lifecycle, animation playback, tiling contract in this revision | fixed |

Additional identity rules:

- `Texture`, `Atlas`, and `Sprite` are first-class graphics objects in this revision even though they are not interactive controls.
- `Sprite` is not an animation object. Animation systems may later compose sprites, but frame sequencing is not part of the `Sprite` contract.
- `Image` is the retained UI primitive that displays a `Texture` or `Sprite`. It is not an alias of `Texture` or `Sprite`.

## 4B. Shared Source Contracts

### 4B.1 Texture Contract

`Texture` represents a resolved image source.

`Texture` must:

- expose intrinsic pixel width and height
- be usable as the full-source basis for rendering
- allow implementation-specific backing sources such as decoded image data, runtime-generated pixels, or render-target output so long as the public contract remains consistent

`Texture` must not:

- require a filesystem path as its identity
- imply CPU-readable pixel access in this revision
- imply mutability after creation in this revision

### 4B.2 Atlas Contract

`Atlas` represents named region metadata over one or more textures.

`Atlas` must:

- resolve a stable region descriptor by name or key
- associate each region with exactly one backing texture at resolution time
- expose region bounds in texture pixel space

`Atlas` must not:

- imply animation ordering
- imply a single-texture backing in this revision
- imply retained drawing behavior

### 4B.3 Sprite Contract

`Sprite` represents a resolved drawable view over a texture.

`Sprite` may resolve from:

- a full `Texture`
- an `Atlas` region
- an explicit source rectangle over a `Texture`

`Sprite` must:

- resolve to exactly one backing texture plus one effective source region
- expose intrinsic pixel dimensions derived from its effective source region
- remain valid as a drawable image view without requiring a retained UI node

`Sprite` must not:

- own animation playback
- own layout or interaction semantics

### 4B.4 Region Contract

Where a graphics object or control accepts a source region in this revision, that region is expressed as:

- `x`
- `y`
- `width`
- `height`

All region coordinates are in source-texture pixel space.

When a requested region extends outside the available source bounds, the consumer-visible fallback in this revision is:

- clip the region to valid bounds
- emit a warning diagnostic

The request must still fail deterministically when the requested width or height is non-positive.

## 5. Texture

**Purpose and contract**

`Texture` is a first-class image-source object. It owns intrinsic source dimensions and provides the backing pixel source for `Sprite`, `Image`, atlas regions, and texture-backed skin assets.

**Public contract**

- intrinsic width
- intrinsic height
- resolved source identity

**Behavioral edge cases**

- A `Texture` with invalid or unavailable backing source must fail deterministically.
- A `Texture` may be provider-backed or runtime-generated in this revision so long as it still resolves the documented public contract.

## 6. Atlas

**Purpose and contract**

`Atlas` is a first-class region-catalog object. It owns named lookup of source regions across one or more textures.

**Public contract**

- named region lookup
- backing texture association per resolved region
- region bounds

**Behavioral edge cases**

- Missing required atlas region metadata must fail deterministically.
- An atlas region whose resolved bounds exceed the backing texture bounds must clip with warning when used through a region-consuming contract that permits clipping; otherwise it must fail according to the consuming contract.

## 7. Sprite

**Purpose and contract**

`Sprite` is a first-class drawable source-view object. It owns a resolved texture plus an effective source region, with intrinsic size derived from that region.

**Public contract**

- backing texture reference
- effective source region
- intrinsic width and height derived from the effective region

**Behavioral edge cases**

- A `Sprite` created from a full texture uses the full texture bounds as its effective source region.
- A `Sprite` created from an atlas region uses that resolved region as its effective source region.
- A `Sprite` whose requested region exceeds valid source bounds clips with warning in this revision.

## 8. Image

**Purpose and contract**

`Image` is a retained presentational primitive that renders a `Texture` or `Sprite`. It owns fit behavior, alignment inside the assigned box, decorative-versus-named accessibility, and sampling policy.

`Image` must:

- render a resolved `Texture` or `Sprite`
- derive intrinsic size from the effective source view
- support fit behavior within the assigned layout box
- support horizontal and vertical content alignment
- remain non-interactive in this revision

`Image` must not:

- expose built-in animation playback
- expose native file-loading lifecycle as part of the retained primitive contract
- expose public tiling or wrap behavior in this revision

**Anatomy**

- `root`: the image subtree root. Required.
- `content`: the resolved image presentation region. Required.

**Props and API surface**

- `source: Texture | Sprite`
- `fit: "contain" | "cover" | "stretch" | "none"`
- `alignX: "start" | "center" | "end"`
- `alignY: "start" | "center" | "end"`
- `sampling: "nearest" | "linear"`
- `decorative: boolean`
- `accessibleName: string | nil`

Default values:

- `fit = "contain"`
- `alignX = "center"`
- `alignY = "center"`
- `sampling = "linear"`
- `decorative = false`

**State model**

STATE ready

  ENTRY:
    1. A valid `Texture` or `Sprite` source is available.
    2. The effective source view is resolved from that source.
    3. The resolved image geometry is placed according to `fit`, `alignX`, and `alignY`.

  TRANSITIONS:
    ON source, fit, alignment, or bounds change:
      1. Re-resolve the effective source view.
      2. Recompute intrinsic size and fit geometry.
      → ready

ERRORS:
  - missing or invalid `source` → invalid configuration and deterministic failure.
  - `fit`, `alignX`, `alignY`, or `sampling` outside the documented enum sets → invalid configuration and deterministic failure.

**Accessibility contract**

`Image` must support decorative and named-image usage. When `decorative = true`, the image contributes no semantic accessible name. When `decorative = false`, the consumer is responsible for supplying a meaningful `accessibleName`. `Image` does not participate in focus traversal in this revision.

**Composition rules**

`Image` is a closed presentational primitive with no consumer-fillable descendant slots in this revision. It may be placed inside any component that permits presentational descendants.

**Behavioral edge cases**

- An `Image` with `fit = "none"` renders at intrinsic size derived from the effective source view.
- An `Image` with `fit = "cover"` may crop rendered pixels to satisfy cover behavior.
- An `Image` at zero or tiny size must remain valid, though visible pixels may be minimal or absent.

## 9. Visual Contract And Theming Boundary

Stable presentational parts:

- `Image.content`

Shared overridable appearance surface:

- fit treatment
- alignment treatment
- sampling treatment
- decorative-versus-named presentation treatment

Consumer-owned surface:

- `Texture`, `Atlas`, and `Sprite` source data supplied to graphics objects and `Image`

## 10. Failure Semantics

- Invalid `Texture` sources fail deterministically.
- Invalid `Atlas` metadata fails deterministically unless a consuming contract explicitly defines clipping-with-warning behavior.
- Invalid `Sprite` region width or height fails deterministically.
- Region overflow beyond valid source bounds clips with warning where this document or a consuming contract explicitly permits it.

## 11. Stability

| Object | Tier | Current tier since | Deprecated? | Removal version | Replacement |
|--------|------|--------------------|-------------|-----------------|-------------|
| `Texture` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Atlas` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Sprite` | `Stable` | `0.1.0` | no | n/a | n/a |
| `Image` | `Stable` | `0.1.0` | no | n/a | n/a |
