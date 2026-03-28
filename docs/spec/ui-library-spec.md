# UI Library Specification

This specification is split into two authoritative documents:

- [UI Foundation Specification](./ui-foundation-spec.md)
- [UI Controls Specification](./ui-controls-spec.md)

The foundation document defines the shared component model, composition grammar, state model, interaction model, behavioral completeness, contract stability, failure semantics, visual contract, classification taxonomy, identity contract, retained lifecycle and rendering model, runtime model, propagation, focus, responsive layout, render-skin contract, and theming contract.

The controls document applies that component model, composition grammar, state model, interaction model, behavioral completeness, contract stability, failure semantics, and visual contract to the concrete control families and defines each control's responsibility boundary, compound structure, public state ownership, interaction callbacks, edge-case behavior, stability tier assignment, failure behavior, and stable visual surfaces on top of the foundation contracts.

This file remains the stable entry point for the specification set.
