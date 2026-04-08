# 02-shape

## Goal

Verify the published `Shape` primitive directly, including its shape-owned stroke surface.

Primary authority:

- [UI Foundation Specification](../../docs/spec/ui-foundation-spec.md)
- [UI Styling Specification](../../docs/spec/ui-styling-spec.md)

## What This Demo Proves

- `Shape` is a retained primitive parallel to `Drawable`, not a subtype of it
- `CircleShape`, `TriangleShape`, and `DiamondShape` render their canonical silhouettes
- `Shape` owns `strokeWidth`, `strokeStyle`, `strokePattern`, `strokeJoin`, and dash metrics on the real perimeter instead of borrowing `Drawable` border props
- transformed shape targeting follows the visible silhouette instead of the rectangular layout box
- `TriangleShape` can opt into centroid-based pivoting explicitly without changing the default shape pivot contract
- dashed rectangular frames still show the full layout footprint
- mixed `Drawable` and `Shape` siblings preserve ordinary retained z-order targeting

## Run

```bash
love demos/02-shape
```
