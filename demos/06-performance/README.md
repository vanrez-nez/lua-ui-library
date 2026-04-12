# 06-performance

## Goal

Build a focused performance demo set for retained-scene stress cases.

Primary authority:

- [UI Foundation Specification](../../docs/spec/ui-foundation-spec.md)
- [UI Library Specification](../../docs/spec/ui-library-spec.md)

## Scope

This demo currently covers one retained `Image` stress case using shared source
data and increasing node count.

## Screen Set

1. image bounce stress

## Demo Notes

- The image screen starts with 10 bouncing `Image` nodes that all share one
  `Texture` source.
- Each left click adds 10 more bouncing images so node count can increase
  interactively during the run.
