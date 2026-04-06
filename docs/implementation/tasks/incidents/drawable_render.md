# Drawable Render Pipeline

This document traces the draw-time path for retained UI elements in the current library.

Scope:
- This is about rendering, not layout or update.
- It assumes `Stage:update()` already ran for the frame.
- It uses pseudocode for explanation and points to the real functions that implement each step.

## 1. Frame Entry

References:
- `lib/ui/scene/stage.lua:501` `resolve_draw_args`
- `lib/ui/scene/stage.lua:2449` `Stage:_prepare_draw`
- `lib/ui/scene/stage.lua:2466` `Stage:draw`

Pseudocode:

```text
function Stage:draw(graphics, draw_callback):
    assert stage is not destroyed
    assert update already ran this frame

    graphics, draw_callback = normalize arguments
    wrapped_callback = create focus-aware draw callback(draw_callback)

    draw subtree starting at baseSceneLayer
    draw subtree starting at overlayLayer

    mark frame as no longer draw-ready
```

What this means:
- Rendering is gated by the two-pass rule. Draw is not allowed until update has completed.
- The stage always renders two roots in order:
  - `baseSceneLayer`
  - `overlayLayer`

Complexity notes:
- `resolve_draw_args`: `O(1)`
- `Stage:_prepare_draw`: `O(1)` plus callback wrapping
- `Stage:draw`: `O(T_base + T_overlay)` where each term is full subtree traversal cost
- Practical interpretation: stage draw itself is cheap; total cost is dominated by the two subtree renders it triggers

## 2. Per-Node Draw Callback

References:
- `lib/ui/scene/stage.lua:531` `draw_node_default`
- `lib/ui/scene/stage.lua:547` `create_focus_aware_draw_callback`

Pseudocode:

```text
function wrapped_draw_callback(node, graphics):
    previous_focus_flag = node._focused
    node._focused = (stage.focus_owner == node) or nil

    try:
        if node.draw exists:
            node:draw(graphics)

        if node._draw_control exists:
            node:_draw_control(graphics)

        run external draw_callback(node, graphics)

        if node is the focused Drawable:
            node:_draw_default_focus_indicator(graphics)
    finally:
        restore previous node._focused value
```

What this means:
- Default node rendering happens before any external/demo callback.
- Focus decoration is not part of `Drawable:draw`; it is layered on after the normal draw callback finishes.
- `_draw_control` is a second internal hook that may add extra visuals beyond `node.draw`.

Complexity notes:
- `draw_node_default`: `O(1)` dispatch plus whatever `node.draw` and `node._draw_control` cost
- `create_focus_aware_draw_callback`: `O(1)` to create, `O(1)` wrapper overhead per visited node
- Practical interpretation: the wrapper itself is cheap; the cost multiplies because it runs once per visible visited node

## 3. Subtree Entry

References:
- `lib/ui/core/container.lua:2095` `Container:_draw_subtree`
- `lib/ui/core/container.lua:2127` `Container:_draw_subtree_resolved`

Pseudocode:

```text
function Container:_draw_subtree_resolved(graphics, draw_callback):
    read current graphics scissor/stencil state

    draw_subtree(
        root = self,
        graphics = graphics,
        draw_callback = draw_callback,
        clip_state = {
            active_clips = [],
            scissor = current graphics scissor,
            stencil_compare = current graphics stencil compare,
            stencil_value = current graphics stencil value
        }
    )
```

What this means:
- Subtree drawing inherits whatever scissor and stencil state is already active on the graphics adapter.
- Clip state is explicit and threaded through recursion.

Complexity notes:
- `Container:_draw_subtree`: `O(1)` argument normalization
- `Container:_draw_subtree_resolved`: `O(1)` setup plus one call into recursive traversal
- Practical interpretation: this layer is not the bottleneck unless it forces synchronization through `ensure_current`

## 4. Recursive Subtree Traversal

References:
- `lib/ui/core/container.lua:1329` `draw_subtree`

Pseudocode:

```text
function draw_subtree(node, graphics, draw_callback, clip_state, render_state):
    if node.visible is false:
        return

    if node is a Drawable and has active render effects:
        render subtree into isolation canvas
        composite canvas back into parent target
        return

    if node.clipChildren is false:
        draw_callback(node)
        for each child in node._ordered_children:
            draw_subtree(child, ...)
        return

    if node.clipChildren is true:
        handle clipping branch
```

Traversal shape:
- Depth-first
- Parent first, then children
- Child order comes from `_ordered_children`

Complexity notes:
- `draw_subtree`: `O(V)` over visited visible nodes for a subtree, before counting expensive branches
- More precisely: `O(V + C + I)` where:
  - `V` = visited nodes
  - `C` = clip work
  - `I` = isolated subtree replay/composite work
- Practical interpretation: base traversal is linear in node count; the expensive part is what each node forces the traversal to do

## 5. Effect Isolation Branch

References:
- `lib/ui/core/container.lua:1123` `resolve_drawable_effects`
- `lib/ui/core/container.lua:1163` `drawable_requires_isolation`
- `lib/ui/core/container.lua:1266` `draw_isolated_subtree`
- `lib/ui/core/container.lua:1193` `composite_isolated_subtree`

Pseudocode:

```text
function resolve_drawable_effects(node):
    if node is not a Drawable:
        return nil

    return {
        shader,
        opacity,
        blendMode,
        mask,
        translationX,
        translationY,
        scaleX,
        scaleY,
        rotation
    }

function drawable_requires_isolation(effects):
    return any of these changes the normal draw path:
        shader != nil
        mask != nil
        blendMode != nil
        opacity != 1
        translationX != 0
        translationY != 0
        scaleX != 1
        scaleY != 1
        rotation != 0
```

If isolation is required:

```text
function draw_isolated_subtree(node, graphics, draw_callback, clip_state, render_state, effects):
    acquire offscreen canvas sized for stage/root bounds
    save current render target and graphics state

    set canvas as current target
    reset transform, clear canvas
    clear scissor and stencil restrictions
    reset draw color and shader state

    draw subtree again into the canvas
    but suppress effect re-entry for this same root

    restore previous render target and graphics state

    composite the canvas back:
        apply parent clip state
        apply opacity
        apply shader
        apply blend mode
        apply translation / scale / rotation around pivot
```

What this means:
- Effects do not get applied inline during normal recursion.
- The library first renders the whole subtree into a canvas, then applies compositing/effects in one step.
- This is a major place to inspect when tracking expensive rendering.

Complexity notes:
- `resolve_drawable_effects`: `O(1)`
- `drawable_requires_isolation`: `O(1)`
- `draw_isolated_subtree`: `O(S)` for replaying the isolated subtree, where `S` is nodes in that subtree, plus canvas clear/acquire/composite cost
- `composite_isolated_subtree`: `O(1)` CPU-side setup, plus one canvas draw whose GPU cost scales with the canvas area
- Practical interpretation: isolation is one of the most expensive branches because it replays a subtree offscreen and then draws it again as a texture

## 6. Clipping Branches

References:
- `lib/ui/core/container.lua:1329` `draw_subtree`

### 6.1 No Clipping

Pseudocode:

```text
if clipChildren is false:
    draw current node
    recurse into children
```

### 6.2 Degenerate Clip

Pseudocode:

```text
if clipChildren is true and clip geometry is degenerate:
    temporarily push this node as active clip
    set scissor to empty rectangle
    immediately restore previous clip state
    stop recursion for this branch
```

What this means:
- Nothing under this node can render.

Complexity notes:
- Degenerate clip handling: `O(1)`
- Practical interpretation: cheap branch, but still incurs graphics state churn

### 6.3 Axis-Aligned Clip

Pseudocode:

```text
if clipChildren is true and clip is axis-aligned:
    combined_scissor = this node clip rect

    if parent scissor already exists:
        combined_scissor = intersect(parent scissor, this clip rect)

    save previous scissor
    set graphics scissor = combined_scissor

    draw current node
    recurse into children

    restore previous scissor
```

What this means:
- Axis-aligned clip uses a normal scissor rectangle, which is the cheaper branch.

Complexity notes:
- Axis-aligned clip branch: `O(1)` per clipped node plus child traversal
- Uses rectangle intersection and scissor state changes only
- Practical interpretation: usually acceptable unless used on many nodes every frame

### 6.4 Non-Axis-Aligned Clip

Pseudocode:

```text
if clipChildren is true and clip is not axis-aligned:
    next_stencil_value = current_stencil_value + 1

    write this node clip polygon into stencil buffer using increment
    set stencil test to "equal next_stencil_value"

    draw current node
    recurse into children

    redraw clip polygon into stencil buffer using decrement
    restore previous stencil and scissor state
```

What this means:
- Rotated or otherwise non-axis-aligned clips go through stencil, not scissor.
- This is another branch worth profiling if transformed clipping is used heavily.

Complexity notes:
- Non-axis-aligned clip branch: `O(1)` CPU per node, but more expensive GPU/state work than scissor
- Requires stencil writes, stencil test changes, polygon generation, and stencil cleanup
- Practical interpretation: this is significantly heavier than axis-aligned clipping when repeated across many nodes

## 7. Drawable Paint Entry

References:
- `lib/ui/core/drawable.lua:589` `Drawable:draw`

Pseudocode:

```text
function Drawable:draw(graphics):
    bounds = self:getWorldBounds()
    props = Styling.assemble_props(self, self._styling_context)
    Styling.draw(props, bounds, graphics)
```

What this means:
- `Drawable:draw` is intentionally small.
- The actual work is delegated to:
  - bounds resolution
  - styling prop assembly
  - styling paint

Complexity notes:
- `Drawable:draw`: `O(1)` CPU-side dispatch plus `Styling.assemble_props` and `Styling.draw`
- `getWorldBounds()` here is cache-backed after `ensure_current`, so the read itself is effectively `O(1)`
- Practical interpretation: `Drawable:draw` is a small wrapper, but it sits on the hottest path because it runs for every drawn `Drawable`

## 8. Styling Prop Assembly

References:
- `lib/ui/render/styling.lua:998` `Styling.assemble_props`

Pseudocode:

```text
function Styling.assemble_props(node, resolver_context):
    resolver_context = normalize resolver context

    if contextual component/part styling is active:
        return resolve contextual props

    props = {}

    for each root styling key:
        skip quad-family aggregate keys here
        value = node[key]
        if value is nil:
            value = skin fallback
        props[key] = normalize styling value

    for each quad family:
        direct layer = node aggregate + per-side overrides
        skin layer = skin aggregate + per-side overrides
        resolved = merge quad family from layers
        copy resolved values into props

    return props
```

Important detail:
- A significant amount of render-time work can happen before any pixels are drawn, because styling values are normalized and merged here.

Complexity notes:
- `Styling.assemble_props`: `O(P + Q)` where:
  - `P` = root styling keys
  - `Q` = quad-family members
- In the current implementation, `P` and `Q` are fixed-size tables, so this is effectively `O(1)` per drawable
- Practical interpretation: constant-time does not mean cheap; this fixed work is paid for every drawn drawable every frame

## 9. Styling Paint Order

References:
- `lib/ui/render/styling.lua:668` `Styling.draw`
- `lib/ui/render/styling.lua:408` `paint_background`
- `lib/ui/render/styling.lua:438` `paint_border`
- `lib/ui/render/styling.lua:581` `paint_outer_shadow`
- `lib/ui/render/styling.lua:614` `paint_inset_shadow`

Pseudocode:

```text
function Styling.draw(props, bounds, graphics):
    validate inputs
    radii = resolve effective corner radii
    save current color

    if shadow is outer:
        paint outer shadow

    paint background
    paint border

    if shadow is inset:
        paint inset shadow

    restore previous color
```

Exact paint order:
1. outer shadow
2. background
3. border
4. inset shadow

Complexity notes:
- `Styling.draw`: `O(1)` control flow, with cost dominated by selected paint branches
- Practical interpretation: the function itself is simple, but it dispatches into the most GPU-expensive work in the pipeline

## 10. Background Branch

References:
- `lib/ui/render/styling.lua:408` `paint_background`
- `lib/ui/render/styling.lua:177` `paint_background_color`
- `lib/ui/render/styling.lua:203` `paint_background_gradient`
- `lib/ui/render/styling.lua:329` `paint_background_image`

Pseudocode:

```text
function paint_background(props, bounds, graphics, radii):
    if backgroundImage exists:
        paint image background
    else if backgroundGradient exists:
        paint gradient background
    else if backgroundColor exists:
        paint solid color background
```

What this means:
- Background layers are mutually exclusive in the current renderer.
- Image wins over gradient, gradient wins over solid color.

Complexity notes:
- `paint_background`: `O(1)` branch selection
- `paint_background_color`: typically one filled shape draw
- `paint_background_gradient`: one gradient path plus clipping/shape work
- `paint_background_image`: one image path plus clipping/tiling work
- Practical interpretation: solid backgrounds are cheapest; image and gradient paths add more graphics work but are still far cheaper than isolation or blurred shadows

## 11. Border Branch

References:
- `lib/ui/render/styling.lua:438` `paint_border`

Pseudocode:

```text
function paint_border(props, bounds, graphics, radii):
    read per-side border widths
    if all widths are zero:
        return

    if no border color exists:
        return

    set border color and line state

    if all four border widths are equal:
        draw one rounded-rectangle outline
    else:
        draw each side independently
        draw each corner arc independently

    restore previous line state and color
```

What this means:
- Uniform borders are the simpler path.
- Mixed per-side borders require more draw operations.

Complexity notes:
- `paint_border`: `O(1)` with a fixed upper bound on line/arc draws
- Uniform border: one rounded outline draw
- Mixed border widths: up to four side lines plus four corner arcs
- Practical interpretation: borders are usually moderate cost, but heterogeneous border widths increase draw-call count noticeably

## 12. Shadow Branches

References:
- `lib/ui/render/styling.lua:581` `paint_outer_shadow`
- `lib/ui/render/styling.lua:614` `paint_inset_shadow`

Pseudocode:

```text
function paint_outer_shadow(...):
    if no shadow color or final alpha <= 0:
        return

    if blur <= 0:
        draw one hard-edged rounded rect shadow
    else:
        render shadow into canvas using multiple expanded steps
        composite shadow canvas back
```

```text
function paint_inset_shadow(...):
    if no shadow color or final alpha <= 0:
        return

    compute inner box from border widths
    if inner box is empty:
        return

    stencil to the inner rounded rect

    if blur <= 0:
        draw one hard-edged inner shadow
    else:
        render blurred shadow into canvas
        composite into the clipped interior

    restore stencil state
```

What this means:
- Blurred shadows are canvas-based and multi-pass.
- Inset shadows additionally pay stencil setup/restoration costs.

Complexity notes:
- Hard-edged shadow: `O(1)` draw
- Blurred shadow: `O(B)` shadow steps where `B ~= ceil(blur * 2)`, plus canvas acquire/clear/composite
- Inset blurred shadow: `O(B)` plus stencil setup and restoration
- Practical interpretation: blurred shadows are among the most expensive styling features in this pipeline

## 13. Full Pipeline Summary

Pseudocode:

```text
function frame_render():
    Stage:draw()
        prepare draw arguments
        wrap draw callback with focus handling

        for root in [baseSceneLayer, overlayLayer]:
            root:_draw_subtree_resolved()
                seed clip state from graphics adapter
                recursively draw nodes

                    for each node:
                        skip invisible nodes

                        if effects require isolation:
                            draw subtree into canvas
                            composite canvas back
                        else:
                            if clipChildren:
                                choose scissor or stencil branch

                            run wrapped draw callback
                                node:draw()
                                    bounds = getWorldBounds()
                                    props = Styling.assemble_props()
                                    Styling.draw()
                                        outer shadow
                                        background
                                        border
                                        inset shadow
                                node:_draw_control() if present
                                external draw callback
                                focus indicator if applicable

                            recurse children in order
```

## 14. Practical Profiling Hooks

If the goal is to explain large FPS drops, start measuring here:

- `Stage:draw`
  - total frame render cost
- `draw_subtree`
  - visited node count
  - skipped invisible node count
- `drawable_requires_isolation`
  - number of isolated subtrees per frame
- `draw_isolated_subtree`
  - canvas allocations and subtree replay cost
- `Drawable:draw`
  - count of actual styled drawables
- `Styling.assemble_props`
  - time spent resolving styles before paint
- `Styling.draw`
  - cost split between background, border, and shadow branches
- clipping path
  - how often scissor is used
  - how often stencil is used

The main performance question is not just "how many drawables exist", but:
- how many nodes are visited
- how many nodes trigger canvas isolation
- how many nodes trigger stencil work
- how many nodes trigger shadow work

## 15. Potential Bottlenecks

Ordered by likely impact in this pipeline:

1. Subtree isolation for effects
- Triggered by shader, mask, blend mode, opacity not equal to `1`, or active motion transforms.
- Why it hurts: the subtree is rendered once into an offscreen canvas and then composited back, so the subtree work is replayed and the canvas area also matters.
- References:
  - `lib/ui/core/container.lua:1163` `drawable_requires_isolation`
  - `lib/ui/core/container.lua:1266` `draw_isolated_subtree`
  - `lib/ui/core/container.lua:1193` `composite_isolated_subtree`

2. Blurred shadows
- Triggered by `shadowBlur > 0`.
- Why it hurts: blurred shadows are multi-pass and canvas-based. Cost grows with blur radius and shaded area.
- References:
  - `lib/ui/render/styling.lua:581` `paint_outer_shadow`
  - `lib/ui/render/styling.lua:614` `paint_inset_shadow`

3. Non-axis-aligned clipping
- Triggered when `clipChildren` is enabled on a transformed clip region.
- Why it hurts: stencil setup, stencil writes, polygon emission, and stencil teardown are all more expensive than scissor clipping.
- References:
  - `lib/ui/core/container.lua:1329` `draw_subtree`

4. Large visible node counts
- Triggered by screens with many visible nodes, especially when each node also has borders, shadows, controls, or extra overlays.
- Why it hurts: the traversal is linear, so all per-node constant work compounds quickly.
- References:
  - `lib/ui/core/container.lua:1329` `draw_subtree`
  - `lib/ui/scene/stage.lua:547` `create_focus_aware_draw_callback`
  - `lib/ui/core/drawable.lua:589` `Drawable:draw`

5. Per-drawable style assembly
- Triggered for every drawn `Drawable`.
- Why it hurts: even though `Styling.assemble_props` is effectively constant time, it still performs normalization and merge work on every frame for every drawable.
- References:
  - `lib/ui/render/styling.lua:998` `Styling.assemble_props`

6. Mixed-width borders and rounded geometry
- Triggered by per-side borders and non-zero corner radii.
- Why it hurts: they increase shape generation and draw-call count compared to simple filled rectangles.
- References:
  - `lib/ui/render/styling.lua:438` `paint_border`

7. Extra draw hooks outside the core styling path
- Triggered by `_draw_control`, focus indicators, and any external draw callback supplied by demos or tooling.
- Why it hurts: these execute once per visited node after normal draw.
- References:
  - `lib/ui/scene/stage.lua:531` `draw_node_default`
  - `lib/ui/scene/stage.lua:547` `create_focus_aware_draw_callback`

8. Forced synchronization during draw-time reads
- Triggered when caches are stale and `ensure_current()` has to synchronize before returning bounds/transforms.
- Why it hurts: draw-time cache misses blur the boundary between update and render, which makes rendering spikes harder to reason about.
- References:
  - `lib/ui/core/container.lua:483` `ensure_current`
  - `lib/ui/core/container.lua:2006` `Container:getWorldBounds`

## 16. First Profiling Priorities

If you want to trace the actual FPS drop next, instrument these in order:

1. Count visited nodes in `draw_subtree`
2. Count isolated subtrees in `drawable_requires_isolation`
3. Count blurred shadow draws in `paint_outer_shadow` and `paint_inset_shadow`
4. Count stencil-clip uses versus scissor-clip uses
5. Time `Styling.assemble_props` and `Styling.draw` separately
6. Measure canvas sizes acquired by `draw_isolated_subtree`
