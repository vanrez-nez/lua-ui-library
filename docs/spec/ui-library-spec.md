# UI Library Specification

## 1. Overview

This specification is split into two authoritative documents.

## 2. Authoritative Documents

- [UI Foundation Specification](./ui-foundation-spec.md)
- [UI Controls Specification](./ui-controls-spec.md)
- [UI Evolution Specification](./ui-evolution-spec.md)

## 3. Document Responsibilities

The foundation document defines the shared component model, composition grammar, state model, interaction model, behavioral completeness, contract stability, failure semantics, visual contract, classification taxonomy, identity contract, retained lifecycle and rendering model, runtime model, propagation, focus, responsive layout, render-skin contract, and theming contract.

The controls document applies that component model, composition grammar, state model, interaction model, behavioral completeness, contract stability, failure semantics, and visual contract to the concrete control families and defines each control's responsibility boundary, compound structure, public state ownership, interaction callbacks, edge-case behavior, stability tier assignment, failure behavior, and stable visual surfaces on top of the foundation contracts.

The evolution document defines how the library manages change over time: breaking change definition, versioning semantics, deprecation and experimental protocols, and the full stability scope declaration for both the foundation and controls.

## 4. Stable Entry Point

This file remains the stable entry point for the specification set.
