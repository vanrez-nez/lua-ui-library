# Spec Patch: Normalize Graphics Capabilities Across Drawable And Shape

## Part 2: Shared Root Compositing

---

## Summary

This part defines the runtime contract for the shared root-compositing surface
established in Part 1.

The shared root-compositing surface is:

- `opacity`
- `shader`
- `blendMode`

This part closes the following items deferred from Part 1:

- runtime capability declaration and resolution mechanism
- composition target stack model
- default root-compositing state
- isolation derivation rule
- `blendMode` motion writability
- `shader` motion writability and uniform parameterization model
- shader failure modes and their trigger points
- graphics state save/restore obligation

---

## Document Series

- **Part 1: Model And Boundaries** — closed
- **Part 2: Shared Root Compositing** — this document
- **Part 3: Shape-Owned Fill Sources And Texture**

All decisions in Part 1 are authoritative. This part extends them. Where this
part references compositing order, blend reference frame, or isolation
semantics, the canonical definition remains in Part 1.

---

## Amendments To Existing Specs

This patch supersedes the following normative statements. Both specs must be
updated to reflect these changes when this patch is ratified.

**Section 8.13 — Shader Contract, node-level execution order:**

Remove:
> A shader applied at the node level executes over the node's rendered output,
> after the node draws and before its descendants draw, unless the composition
> requires isolation.

Replace with:
> A root shader defined by the shared root-compositing surface executes after
> the node's full subtree is composited, at step 3 of the canonical compositing
> order established in the capability-normalization patch. It operates on the
> fully composited subtree result, not on the node's pre-descendant output.

Part-level shader execution defined in §8.13's second paragraph is not affected
by this change.

**Section 8.6 — Visual Inheritance Within Composition:**


The following statement in §8.6 is superseded for root-compositing properties
only:
> node-level opacity, blend mode, masking, and shader behavior propagate only
> through the inherited effect chain

Replace with:
> node-level `opacity`, `blendMode`, and `shader` defined by the shared
> root-compositing surface do not propagate through the inherited effect chain.
> They are resolved exclusively from each node's own compositing state record.
> The inherited effect chain remains authoritative for transform, clipping, and
> mask behaviors. `mask` is not part of the shared root-compositing surface.

**`ui-motion-spec.md` — Section 4I, Family Adoption Matrix:**

Add the following rows:

| Family or object | Motion-relevant phases | Typical targets |
|---|---|---|
| `Drawable` | consumer-defined visual motion | root compositing surface (`opacity`, `blendMode`, `shader`) |
| `Shape` | consumer-defined visual motion | root compositing surface (`opacity`, `blendMode`, `shader`) |

This mirrors the `Image` row already present in §4I. Motion phase selection for
these primitives is consumer-driven and not tied to a specific component
lifecycle phase.

---

## Capability Declaration Model

A primitive declares root-compositing participation through a static
class-level capability table declared on the primitive class definition. The
renderer resolves capability by reading this table through the node's class
identity, resolved once per class when the class is first loaded. No per-instance
query is performed.

The capability table is a typed declaration, not a runtime query.

It must state:

- whether the node type supports `opacity`
- whether the node type supports `shader`
- whether the node type supports `blendMode`

The renderer reads this table once per class. It does not infer capability
from primitive family membership. It does not re-evaluate per frame.

`Drawable` and `Shape` both declare full support for all three properties.

Any future primitive that does not adopt the shared root-compositing surface
declares no support. Assignment of a root-compositing property to a
non-adopting primitive is an immediate hard error per Part 1.

---

## Compositing State Record

At draw time, the renderer resolves a compositing state record for each node.

The compositing state record contains:

- resolved `opacity`: finite number, 0.0–1.0
- resolved `blendMode`: enum value
- resolved `shader`: shader object reference or nil

This record is derived from the node's current property values. It is not
accumulated from ancestors. Root-compositing properties are direct instance
properties that do not participate in ordinary property inheritance.

The record is resolved once per node per frame traversal. It is the sole
input to isolation derivation and draw-time compositing.

---

## Default Root-Compositing State

The default root-compositing state is:

- `opacity`: `1.0`
- `blendMode`: `"normal"` (source-over)
- `shader`: `nil`

A node whose resolved compositing state record exactly matches the default
state requires no isolation pass and incurs no additional compositing cost.

This is the mandatory fast path. The renderer must not allocate offscreen
targets, acquire canvases, or modify compositing state for nodes in default
state.

---

## Composition Target Stack

Root-compositing execution is managed through a composition target stack
maintained during scene graph traversal.

The composition target stack is an ordered stack of active render targets.

Rules:

- the stack is initialized with the root render target before traversal begins
- the target at the top of the stack is the current active render target
- when a node requires isolation, a new offscreen target is pushed onto the
  stack before the node's subtree is drawn
- the node and its descendants draw into the offscreen target now at the top
- after the subtree is complete, the offscreen target is popped from the stack
- the resolved node result is composited from the popped target into the target
  now at the top, applying the node's resolved `blendMode` and `opacity`

This model defines what "immediate parent composition target" means concretely.
The blend reference frame from Part 1 is the target at the top of the stack
at the moment the node's resolved result is composited back.

Nested isolation is correct by construction: each isolated node pushes its own
target, draws into it, and composites back. Parent compositing state is applied
only after the parent's own subtree is complete and the parent composites into
its own parent target.

---

## Isolation Derivation Rule

Isolation is derived from the resolved compositing state record.

A node requires isolation when any of the following is true:

- `blendMode` is non-default (any value other than `"normal"`)
- `shader` is non-nil
- `opacity` is not `1.0` and the node's subtree contains overlapping or
  interacting layers whose per-draw alpha application would produce a different
  result than post-composite application

When none of those conditions is true, the node draws inline into the current
active render target with no isolation overhead.

An implementation may use a provably equivalent optimization instead of an
explicit offscreen pass in any of these cases, provided the visible result is
identical.

---

## Graphics State Save And Restore

Any node that modifies compositing state during its draw phase must bracket
that modification with explicit save and restore operations.

The obligation is:

- save compositing-relevant graphics state before applying any compositing
  change; compositing-relevant state means at minimum: the active render target,
  the active blend mode, and any global alpha modulation active at that point
  in the draw pass
- restore that state unconditionally after the node's subtree has been
  composited, regardless of error, early exit, or no-op conditions

This applies to every node that pushes an offscreen target, applies a shader,
or sets a non-default blend mode.

Graphics state must not leak across siblings. The compositor must treat save
and restore as a hard contract, not a best-effort discipline.

---

## Semantics By Property

### Opacity

`opacity` is whole-node alpha applied to the fully composited subtree result.

It is not per-paint-call alpha. It is not fill-only or stroke-only alpha.

The canonical application point is step 4 of the compositing order defined in
Part 1:

1. resolve local paint result
2. resolve descendant contribution
3. apply root shader
4. **apply root opacity**
5. composite into parent target using root blend mode

`opacity` is motion-capable. Motion-written opacity uses the same retained
compositing path as directly assigned opacity.

### Blend Mode

`blendMode` defines how the opacity-scaled node result composites into the
immediate parent composition target.

The target is the render target currently at the top of the composition target
stack at the moment the node composites back. This is the blend reference frame
established in Part 1.

`blendMode` accepts a compositing operator from the following stable enum:

| Value | Operation |
|---|---|
| `"normal"` | Source-over (Porter-Duff SRC_OVER). Default. |
| `"add"` | Additive blending |
| `"subtract"` | Subtractive blending |
| `"multiply"` | Multiply blend |
| `"screen"` | Screen blend |

Values outside this set fail deterministically at assignment time. Renderer
implementations may support additional values beyond this set; additional values
are implementation-defined unless a later revision standardizes them explicitly.

`blendMode` is motion-writable as a discrete step only. There is no meaningful
continuous interpolation between compositing operators. For `blendMode` in a
motion property rule, only `to` is meaningful — `from`, `duration`, and `easing`
are ignored. The step is applied immediately when the motion descriptor is
executed. Adapters must not attempt interpolation between blend mode values.
Continuous animation of blend mode is not supported.

### Shader

`shader` defines a post-composite visual modification stage applied to the
node's resolved result before it is composited into the parent target.

The application point is step 3 of the canonical compositing order. Shader
operates on the composited fill-and-stroke result for `Shape` and on the full
drawable result for `Drawable`. It does not intercept individual paint calls.

**Shader parameterization follows standard uniform conventions.** A shader
object carries its own uniform state. Uniforms are set on the shader object
directly, as is standard practice in graphics pipelines such as Love2D's
`love.graphics.newShader`, GLSL-based WebGL programs, and Metal shader
pipelines. The node holds a reference to the shader object. The shader object
owns its uniform values.

**This surface defines the post-composite node-level shader only.** The root
compositing `shader` prop on `Drawable` and `Shape` is exclusively this
post-composite variant. Part-level shader execution on `Drawable`'s skin parts
is a separate rendering stage resolved through the skin system under foundation
spec §8.8 and §8.13's part-level scope. The two stages are independent — this
surface does not affect, replace, or interact with part-level shader behavior.

**Shader motion is whole-object replacement only.** For `shader` in a motion
property rule, only `to` is meaningful — `from`, `duration`, and `easing` are
ignored. The replacement is applied immediately when the motion descriptor is
executed. Adapters must not attempt interpolation between shader object
references. Per-uniform motion targeting requires a named shader parameter
surface that is not standardized in this revision.

If per-uniform animation is needed, the consuming code must drive uniform
values directly on the shader object and trigger a retained update through the
node's normal dirty path. This is the standard retained-mode shader update
pattern.

---

## Shader Failure Semantics

Shader failure has two distinct kinds with different trigger points.

### Configuration Failure

A configuration failure occurs when the shader object is invalid.

Invalid means any of:

- the value is not a shader object type
- the object fails its own internal validation at assignment time

Configuration failure fires at **assignment time**.

Rules:

- reject the assignment immediately
- raise a hard error
- do not retain the previous valid shader
- do not silently ignore the value
- do not warn and continue

### Capability Failure

A capability failure occurs when the renderer cannot execute required
compositing operations at draw time.

This occurs when:

- the renderer is operating on a software path that does not support shader
  execution
- the active render target does not support shader compositing
- the renderer cannot allocate an offscreen target required by the isolation
  rule (GPU memory exhausted, platform canvas limit exceeded, or equivalent
  resource constraint)

Capability failure fires at **draw time**.

Rules:

- raise a hard error
- do not fall back to drawing without the shader or inline drawing without
  isolation; either fallback produces incorrect compositing output
- do not substitute a no-op shader
- halt the draw for that node and propagate the failure

Both failure kinds follow the deterministic failure model established in Part 1.

---

## Motion Contract For The Shared Root-Compositing Surface

| Property | Motion-capable | Interpolation |
|---|---|---|
| `opacity` | Yes | Continuous, numeric |
| `blendMode` | Yes | Discrete step only |
| `shader` | Yes | Discrete step, whole-object replacement only |

No root-compositing property is inheritable through the scene graph. Motion
written values use the same per-node retained path as directly assigned values.

---

## Fast Path Obligation

The shared root-compositing surface must not impose overhead on nodes in
default state.

The renderer must guarantee:

- no offscreen target allocation for nodes with default compositing state
- no save or restore operations for nodes with default compositing state
- no shader execution for nodes with nil shader
- no blend state change for nodes with `"normal"` blend mode

This is an adoption-cost guarantee, not a rendering-correctness rule. An
implementation that incurs compositing overhead for default-state nodes renders
correctly but violates the adoption contract — it makes normalized surface
adoption a performance regression for every primitive that previously drew
inline with no compositing overhead. Compliance is required to make this surface
safe to adopt uniformly.

---

## Acceptance Criteria

This part is complete when:

- `Drawable` and `Shape` both declare full root-compositing capability through
  the static capability record model
- the renderer resolves compositing state from the record, not from primitive
  family membership
- isolation is derived from the compositing state record per the rule above
- the composition target stack drives all isolation and compositing back
  operations
- `opacity` motion continues to work correctly on both primitives
- `blendMode` is motion-writable as a discrete step on both primitives
- `shader` is motion-writable as whole-object replacement on both primitives
- uniform values are set directly on shader objects and not motion-targeted
  individually
- configuration failure fires at assignment time as a hard error
- capability failure fires at draw time as a hard error
- graphics state is saved and restored unconditionally around every compositing
  modification
- no compositing overhead is incurred for nodes in default state
- `mask` remains outside this surface

---

## What Part 3 Owns

Part 3 is not a compositing document. It receives from Part 2:

- a stable, defined composition target stack
- a resolved compositing state record model
- isolation and save/restore contracts

Part 3 uses these to specify how shape-owned fill sources interact with the
compositing surface. It does not redefine any compositing order, isolation
rule, or motion contract established here.

---

## Final Amends Per File

These are the concrete edits to apply to each spec file when this patch is
ratified. Each amendment includes the file, the located target, and the exact
replacement.

---

### `docs/spec/ui-foundation-spec.md`

**Amendment F-1 — Section 8.13, first paragraph**

Locate:

> A shader applied at the node level executes over the node's rendered output,
> after the node draws and before its descendants draw, unless the composition
> requires isolation.

Replace with:

> A root shader defined by the shared root-compositing surface executes after
> the node's full subtree is composited, at step 3 of the canonical compositing
> order established in the capability-normalization patch. It operates on the
> fully composited subtree result, not on the node's pre-descendant output.

The second paragraph of §8.13 (part-level shader execution) is not affected
by this replacement.

---

**Amendment F-2 — Section 8.6, second bullet**

Locate the bullet inside the Visual Inheritance Within Composition visual
propagation rules list:

> node-level opacity, blend mode, masking, and shader behavior propagate only
> through the inherited effect chain and may trigger isolation according to
> Section 8.14

Replace with:

> node-level `opacity`, `blendMode`, and `shader` defined by the shared
> root-compositing surface do not propagate through the inherited effect chain;
> they are resolved exclusively from each node's own compositing state record;
> the inherited effect chain remains authoritative for transform, clipping, and
> mask behaviors; `mask` is not part of the shared root-compositing surface;
> nodes whose compositing state requires isolation do so per the isolation
> derivation rule in Section 8.14

---

### `docs/spec/ui-motion-spec.md`

**Amendment M-1 — Section 4I, Family Adoption Matrix, add two rows**

Locate the `Image` row in the Family Adoption Matrix table:

> | `Image` | consumer-defined visual motion only | retained image surface |

Append immediately after that row:

> | `Drawable` | consumer-defined visual motion | root compositing surface (`opacity`, `blendMode`, `shader`) |
> | `Shape` | consumer-defined visual motion | root compositing surface (`opacity`, `blendMode`, `shader`) |