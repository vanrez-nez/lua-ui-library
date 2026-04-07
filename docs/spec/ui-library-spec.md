# UI Library Specification

## 1. Overview

This specification is split into a small set of authoritative documents.

## 2. Authoritative Documents

- [UI Foundation Specification](./ui-foundation-spec.md)
- [UI Layout Specification](./ui-layout-spec.md)
- [UI Controls Specification](./ui-controls-spec.md)
- [UI Graphics Specification](./ui-graphics-spec.md)
- [UI Motion Specification](./ui-motion-spec.md)
- [UI Evolution Specification](./ui-evolution-spec.md)

## 3. Document Responsibilities

The foundation document defines the shared component model, composition grammar, state model, interaction model, behavioral completeness, contract stability, failure semantics, visual contract, classification taxonomy, identity contract, retained lifecycle and rendering model, runtime model, propagation, focus, responsive contract, the foundational primitive contracts for `Container`, `Drawable`, and `Shape`, the render-skin contract, and theming contract.

The layout document defines spacing semantics for `padding` and `margin`,
`Drawable` internal content alignment semantics, layout-family common behavior,
and the authoritative contracts for `Stack`, `Row`, `Column`, `Flow`, and
`SafeAreaContainer`. It does not define `Shape` layout-specific spacing or
content-box behavior.

The controls document applies that component model, composition grammar, state model, interaction model, behavioral completeness, contract stability, failure semantics, and visual contract to the concrete control families and defines each control's responsibility boundary, compound structure, public state ownership, interaction callbacks, edge-case behavior, stability tier assignment, failure behavior, and stable visual surfaces on top of the foundation contracts.

The graphics document defines the first-class graphics-object contracts and retained image presentation surfaces layered on top of the foundation contracts.

The motion document defines the public motion integration contract, including motion phases, motion surfaces, motion properties, motion descriptors, presets, and adapter boundaries layered on top of the foundation and component contracts.

The evolution document defines how the library manages change over time: breaking change definition, versioning semantics, deprecation and experimental protocols, and the full stability scope declaration for the specification set.

## 4. Stable Entry Point

This file remains the stable entry point for the specification set.
