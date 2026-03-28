# Skia UI Design Patterns

## Core Model
Skia is not a widget toolkit by default. Its primary model is a drawing engine built around `SkCanvas`, where drawing is expressed as operations applied under a current transform and clip state. At the lowest level, the dominant pattern is a transform-and-clip stack: `SkCanvas` explicitly documents that it contains a stack of `SkMatrix` and clip values, and `save()`, `restore()`, `concat()`, `clipRect()`, `clipPath()`, and `saveLayer()` all operate by pushing and popping scoped state. For UI work, that is the foundational pattern: a subtree or visual region is not usually a standalone widget object, but a bounded drawing context with inherited transforms, clipping, and compositing.

On top of that, Skia also supports recorded drawing. `SkPictureRecorder` exposes a canvas that records commands and can finish as an immutable `SkPicture`, while Graphite uses `Recorder` and `Recording` to capture deferred GPU work. That gives Skia a second strong pattern: command recording or display-list style rendering. In UI terms, Skia is very comfortable separating “describe what to draw” from “submit it now.”

The important nuance is that Skia spans multiple layers of abstraction. The core canvas API is immediate-mode drawing. The recording APIs add retained command streams. And `modules/sksg` adds an actual retained scene graph with invalidation and node composition. So the repository does contain graph-style UI signals, but they sit beside, not inside, the base canvas API.

## Pattern Signals
The clearest low-level signal is the transform stack. `SkCanvas` composes all geometry through the concatenation of matrix values in the stack, and clips drawing by the intersection of clip values in the stack. This is the classic push/pop rendering model used by many UI renderers for nested panels, scrolling regions, masks, and local coordinate spaces.

The second strong signal is compositing through scoped isolation. `saveLayer()` creates an isolated drawing surface for subsequent commands and merges it back on `restore()`. In UI terms, this is the same pattern used for opacity groups, filter groups, masked content, and offscreen composition. You can see the same idea again in `modules/sksg`, where render contexts decide whether paint overrides can be applied directly or require isolation.

The third signal is command buffering. `SkPictureRecorder::beginRecording()` returns a canvas that captures a stream of draw operations and later seals it into an immutable `SkPicture`. Graphite extends this with `Recorder::snap()` producing a `Recording`, plus deferred canvases, task lists, and backend submission ordering. For a UI framework, this is highly relevant: it favors building replayable draw lists or render packets instead of issuing every draw directly to the final target.

Skia also exposes dirty-state style invalidation, but not always under a literal `dirty` flag. `SkDrawable` has a generation ID and requires `notifyDrawingChanged()` whenever internal state changes, which is a cache-invalidation pattern. `Paragraph` exposes `markDirty()` for text layout recomputation. In `modules/sksg`, `Node::invalidate()` tags DAG fragments for revalidation, and `InvalidationController` accumulates dirty rectangles for repaint. So the broad pattern is invalidation-by-version-or-damage rather than a single framework-wide boolean dirty bit.

Finally, there is a real graph pattern in `modules/sksg`. `Node` explicitly describes itself as part of a DAG, supports observer-style invalidation through ingress edge management, and revalidates descendants before rendering. `Group`, `TransformEffect`, `ClipEffect`, `MaskEffect`, `OpacityEffect`, `Draw`, and `Scene` collectively form the closest thing in Skia to a retained UI/render tree.

## Major Components
For UI architecture, the most relevant Skia components are:

- `SkCanvas` as the base drawing surface with matrix, clip, and layer stacks.
- `SkPictureRecorder` and `SkPicture` for immutable recorded command streams.
- `SkDrawable` for cacheable drawables with generation-based invalidation.
- `skgpu::graphite::Recorder` and `Recording` for deferred GPU command capture and submission.
- `ParagraphBuilder` and `Paragraph` from `modules/skparagraph` for text styling, layout, painting, and text dirtiness.
- `modules/sksg` types such as `Node`, `RenderNode`, `Group`, `Transform`, `TransformEffect`, `Draw`, `ClipEffect`, `MaskEffect`, `OpacityEffect`, `Scene`, and `InvalidationController`.

Two details matter especially for UI design. First, `ParagraphBuilder` uses a style stack with `pushStyle()` and `pop()`, then builds a `Paragraph` that separates `layout(width)` from `paint(...)`. That is a clean text-layout pipeline rather than ad hoc text drawing. Second, Graphite includes systems such as `AtlasProvider` and `TextBlobRedrawCoordinator`, which signal cache-heavy rendering for glyphs and repeated content. Those are not widget abstractions, but they are exactly the kinds of subsystems a high-performance UI renderer benefits from.

## UI Takeaways
If you are using Skia as a reference for a UI library, the most reusable ideas are:

- Use a strict transform and clip stack for nested UI regions.
- Treat opacity, filters, and masks as isolated compositing scopes, not ad hoc per-widget hacks.
- Separate command recording from playback so large parts of the interface can be captured and replayed.
- Use invalidation based on damage regions, generation IDs, or revalidation passes instead of blindly redrawing every structural layer.
- Keep text as its own subsystem with style stacking, layout, and paint phases.
- When higher-level structure is needed, use a retained render graph like `sksg` instead of trying to force the raw canvas API to serve as the tree model.

The `sksg` module is especially important here. It shows how Skia’s low-level primitives can be wrapped in a retained DAG with node-level invalidation, group composition, transform effects, clip effects, and hit testing via `nodeAt()`. That is much closer to the architecture of a real UI renderer than raw `SkCanvas` calls alone.

## Caveats
Skia is robust, but it is not opinionated about widget semantics. The base library does not give you buttons, focus routing, event bubbling, layout containers, or a DOM-like event tree. Those layers must be built above it. Even `sksg` is primarily a rendering scene graph, not a full interactive UI framework.

So the right reading is: Skia is an excellent foundation for UI rendering patterns, especially transform stacks, compositing layers, display-list recording, damage tracking, and text layout. But if you want browser-like capture/bubble input routing or a full retained widget hierarchy, you need to supply those policies yourself or pair Skia with a higher-level framework.
