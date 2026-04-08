# 02-shape

## Goal

Verify the published `Shape` primitive directly.

Primary authority:

- [UI Foundation Specification](../../docs/spec/ui-foundation-spec.md)
- [Phase 18 Shape Primitive](../../docs/implementation/phase-18-shape-primitive.md)

## What This Demo Proves

- `Shape` is a retained primitive parallel to `Drawable`, not a subtype of it
- `CircleShape`, `TriangleShape`, and `DiamondShape` render their canonical silhouettes
- transformed shape targeting follows the visible silhouette instead of the rectangular layout box
- `TriangleShape` can opt into centroid-based pivoting explicitly without changing the default shape pivot contract
- dashed rectangular frames still show the full layout footprint
- mixed `Drawable` and `Shape` siblings preserve ordinary retained z-order targeting

## Run

```bash
love demos/02-shape
```
