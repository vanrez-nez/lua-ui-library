# PixiJS UI Design Patterns

## Core Model
PixiJS is fundamentally a retained-mode UI and scene system organized around a `Container` tree rooted at `Application.stage`. The dominant pattern is a scene graph: parent nodes own logical children, and transforms, alpha, visibility, tint, and blend state propagate downward into cumulative `worldTransform` and `worldAlpha` style values. Traversal is tree-based and render order follows child order unless sorting or layering intervenes.

The main architectural split is between logical nodes and renderable views. `Container` acts as the structural node, while `ViewContainer` is the render-facing branch used by concrete elements such as `Sprite`, `Graphics`, `Text`, `BitmapText`, `HTMLText`, `TilingSprite`, `NineSliceSprite`, `Mesh*`, and `ParticleContainer`. That gives PixiJS a component/entity flavor: composition happens by parenting generic containers, while specialized view types plug specific rendering behavior into the same structural tree.

PixiJS is also modular at the renderer level. The renderer is built from extension-driven systems and pipes, so the scene graph is stable while the draw backend is swappable. From a UI architecture standpoint, that means the scene structure, invalidation, event routing, and rendering phases are deliberately separated.

## Pattern Signals
The strongest recurring pattern is a transform stack implemented through parent-to-child propagation rather than isolated widgets computing absolute coordinates. `updateRenderGroupTransforms` walks the tree and composes each node’s local transform into `relativeGroupTransform`, while color, alpha, blend mode, and visibility are folded downward in the same pass. This is classic hierarchical transform propagation.

Traversal is depth-first and pre-order for rendering collection, but reverse child order is used during hit testing so the visually top-most child wins. `collectRenderablesSimple` visits children in order for draw collection, while `EventBoundary.hitTestRecursive` and `hitTestMoveRecursive` walk children from the end of the array backward. That is a clear retained-UI convention: draw order and picking order are both derived from the same tree, but one traverses front-to-back for composition and the other back-to-front for interaction.

PixiJS uses dirty-flag style invalidation aggressively. Signals include `_updateFlags`, `didChange`, `didViewUpdate`, `_didViewChangeTick`, `_didContainerChangeTick`, `structureDidChange`, `textureNeedsUpdate`, and per-render-group update lists such as `childrenToUpdate` and `childrenRenderablesToUpdate`. The system does not blindly rebuild the full render description each frame. Instead, `RenderGroupSystem` chooses between rebuilding instruction sets when structure changed and incrementally updating renderables when only local state changed. That is a strong dirty-flag plus partial-rebuild architecture.

There is also a command-buffer or display-list pattern in the rendering stage. `RenderGroup` owns an `InstructionSet`, `collectRenderablesWithEffects` pushes instructions through render pipes, and `executeInstructions` later replays them. Render groups therefore act like cached display-list fragments for stable subtrees.

The effects path shows a stack pattern as well. `collectRenderablesWithEffects` pushes effect pipes before child traversal and pops them in reverse order afterward. Masks, blend modes, and color-mask operations are therefore modeled as scoped state frames around subtree collection, which is exactly the kind of push/pop stack a UI renderer needs.

## Event and Ordering Patterns
PixiJS uses a DOM-like observer and propagation model through `EventBoundary`, `FederatedEvent`, and `EventSystem`. Input is normalized into federated events, a target is found by hit testing the retained tree, and then propagation runs in three phases: capture, at-target, and bubble. Capture listeners are explicit, bubbling is default, and `composedPath()` defines the propagation chain. This is not a lightweight callback map; it is a full event-routing system modeled after browser semantics.

The event model is tightly coupled to the tree, not to screen-space overlays alone. `eventMode` (`none`, `passive`, `auto`, `static`, `dynamic`) controls whether a subtree participates in hit testing or only its children do. `interactiveChildren` lets a container prune descendant participation. `hitArea` allows shape override. This reveals two patterns at once: observer/event bubbling, and subtree pruning for performance.

Ordering is more nuanced than a simple child list. Baseline render order is scene-graph order, optionally refined with `sortableChildren` and `zIndex`. On top of that, `RenderLayer` decouples visual order from logical parenting: an object keeps transform inheritance from its real parent, but is drawn at the layer’s position in the render sequence. That is effectively a graph overlay pattern on top of the base tree. The logical structure remains a tree, but rendering order can be rerouted through layer attachment points.

`RenderGroup` adds another level of graph segmentation. A render group is a subtree treated as a self-contained rendering unit, with its own instruction cache, transform/color state, and optional cache-as-texture behavior. This is closer to compositing layers in UI frameworks than to ordinary containers.

## Major Components
The key structural pieces are `Application`, `Container`, `ViewContainer`, `RenderGroup`, `RenderGroupSystem`, `RenderLayer`, `EventBoundary`, and `InstructionSet`.

Important UI-facing node families are `Sprite`, `Graphics`, `Text`, `BitmapText`, `HTMLText`, `SplitText`, `NineSliceSprite`, `TilingSprite`, `Mesh*`, and `ParticleContainer`. They all read as renderable components plugged into the same retained tree.

Important supporting systems are:
- `EventSystem` and `EventBoundary` for capture/bubble propagation and hit testing.
- `RenderGroupSystem` for invalidation handling, transform updates, instruction rebuilds, and subtree caching.
- Render pipes such as batch, blend-mode, mask, and color-mask pipes for scoped render-state composition.
- `Culler` for viewport pruning and subtree skipping.
- `Ticker` for per-frame updates and support for `dynamic` event targets.

## UI Takeaways and Caveats
PixiJS is strongest as a retained visual tree with explicit layering and performant subtree caching. For a UI library, the most reusable ideas are:
- Keep a strict logical tree for transforms and event ancestry.
- Separate logical nodes (`Container`) from renderable leaves (`ViewContainer` subclasses).
- Use dirty flags and partial rebuilds instead of rebuilding the whole display list every frame.
- Treat stable subtrees as compositing units (`RenderGroup`) that can cache instructions or textures.
- Allow visual order to diverge from logical order (`RenderLayer`) without breaking transform inheritance.
- Keep event routing tree-based with capture and bubbling, but prune aggressively through interaction modes and subtree flags.

The main caveat is that PixiJS is still a rendering engine first, not a full widget toolkit. Layout is comparatively light, and some advanced ordering features create tradeoffs. `RenderLayer` explicitly warns that visual order can diverge from hit-testing expectations, because interaction still follows logical structure. Ancestor filters also do not automatically apply across layer redirection. So the architecture is robust for interactive 2D UI, but it expects the higher-level toolkit to define stronger layout, widget semantics, and sometimes a stricter policy around visual-order versus input-order consistency.
