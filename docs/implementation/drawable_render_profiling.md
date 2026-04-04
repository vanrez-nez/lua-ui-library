# Drawable Render Profiling Report

This report profiles `demos/02-drawable/screens/alignments.lua` only.

It is based on the pipeline described in `docs/implementation/drawable_render_fixed.md`, and it focuses on the render path from `Stage:draw()` downward.

## Scope

Profile target:
- `demos/02-drawable/screens/alignments.lua`

Pipeline reference:
- `docs/implementation/drawable_render_fixed.md`

Measured report:
- `tmp/drawable-timing-20260403-203731.txt`

Capture command:

```bash
UI_TIME_PROFILE=1 UI_PROFILE_SCREEN=1 UI_TIME_PROFILE_SECONDS=2 love demos/02-drawable
```

## Scene Shape

The alignments screen builds:
- 16 outer `Drawable`s
- each outer has 1 inner child `Drawable`

So the frame contains 32 visible `Drawable`s.

Reference:
- `demos/02-drawable/screens/alignments.lua`

That number matters because the measured hot path is being triggered once per drawn `Drawable`.

## Measured Timing

Key rows from `tmp/drawable-timing-20260403-203731.txt`:

| Zone | Total ms | Avg ms/call | Calls |
|---|---:|---:|---:|
| `Stage.draw` | 1640.154 | 27.799 | 59 |
| `Stage.baseSceneLayer` | 1639.682 | 27.791 | 59 |
| `Drawable.draw` | 1629.576 | 0.863 | 1888 |
| `Drawable.resolveWorldBounds` | 1542.880 | 0.817 | 1888 |
| `Container.getWorldBounds` | 1541.297 | 0.816 | 1888 |
| `Container.ensureCurrent` | 1538.302 | 0.815 | 1888 |
| `Stage.synchronizeForRead` | 1535.937 | 0.814 | 1888 |
| `Styling.assembleProps` | 63.237 | 0.033 | 1888 |
| `Styling.draw` | 19.507 | 0.010 | 1888 |
| `Styling.paint.border` | 7.188 | 0.004 | 1888 |
| `Styling.paint.background` | 5.289 | 0.003 | 1888 |

Important derived numbers:

- `1888 / 59 = 32` draw calls per frame through the hot path.
- That exactly matches the 32 visible `Drawable`s in the alignments screen.
- `Stage.synchronizeForRead` accounts for about `1535.937 / 1640.154 = 93.6%` of `Stage.draw` total time.
- `Styling.assembleProps + Styling.draw = 82.744 ms`, which is about `5.0%` of `Stage.draw` total time.

## What The Measurements Mean

The drop is not primarily in paint.

The dominant chain is:

```text
Stage.draw
  -> Drawable.draw
    -> Drawable.resolveWorldBounds
      -> Container.getWorldBounds
        -> Container.ensureCurrent
          -> Stage.synchronizeForRead
```

References:
- `lib/ui/scene/stage.lua` `Stage:draw`
- `lib/ui/core/drawable.lua` `Drawable:draw`
- `lib/ui/core/container.lua` `Container:getWorldBounds`
- `lib/ui/core/container.lua` `ensure_current`
- `lib/ui/scene/stage.lua` `Stage._synchronize_for_read`

This means the expensive part of the frame is happening before styling paint:
- before border/background drawing
- before most of `Styling.draw`
- before any effect-isolation or clipping branch becomes relevant

## Primary Cause

The main cause of the performance drop is repeated full-stage read synchronization triggered from inside `Drawable:draw()`.

The exact trigger is:

1. `Drawable:draw()` calls `self:getWorldBounds()`
2. `Container:getWorldBounds()` calls `ensure_current(self)`
3. `ensure_current()` detects a stage-backed tree and calls `Stage._synchronize_for_read(root)`
4. `Stage._synchronize_for_read()` runs a full read synchronization pass

References:
- `lib/ui/core/drawable.lua` `Drawable:draw`
- `lib/ui/core/container.lua` `Container:getWorldBounds`
- `lib/ui/core/container.lua` `ensure_current`
- `lib/ui/scene/stage.lua` `synchronize_for_read`

The crucial issue is in `synchronize_for_read`:

```text
if not updating and not synchronizing:
    refresh_environment_bounds
    prepare_layout_subtree
    run_layout_subtree
    refresh_geometry_subtree
```

That branch does not check whether the stage is already current for this frame before running the full pass again.

So during `Stage:draw()`, every `Drawable:getWorldBounds()` read can trigger another whole-tree synchronization.

## Why Alignments Drops So Hard

The alignments screen has 32 visible drawables.

Because each `Drawable:draw()` resolves world bounds, and each world-bounds read goes through `ensure_current`, the stage is being re-synchronized about 32 times per frame.

That turns the frame from:

```text
1 stage update
1 stage draw
```

into something much closer to:

```text
1 stage update
1 stage draw
32 extra read-synchronization passes during draw
```

That is why the measured hot zones are:
- `Stage.synchronizeForRead`
- `Stage.prepareLayoutSubtree`
- `Stage.refreshGeometrySubtree`
- `Drawable.refreshIfDirty`
- `Drawable.refreshContent`

and not the styling paint functions.

## Secondary Contributors

These functions are contributing, but they are downstream of the same root problem:

### `Drawable.refreshIfDirty`

Reference:
- `lib/ui/core/drawable.lua` `Drawable:_refresh_if_dirty`

Measured:
- `2028.110 ms` total across `138308` calls

Meaning:
- once read synchronization begins, drawable refresh work is replayed heavily across the subtree

### `Drawable.refreshContent`

Reference:
- `lib/ui/core/drawable.lua` `refresh_drawable_content`

Measured:
- `1427.073 ms` total across `138308` calls

Meaning:
- alignment/content resolution work is being repeated many times inside the repeated read-sync passes

### `Stage.prepareLayoutSubtree`

Reference:
- `lib/ui/scene/stage.lua` `prepare_layout_subtree`

Measured:
- `557.518 ms` total across `68180` calls

Meaning:
- responsive/layout preparation is repeatedly traversing the subtree during draw-time reads

These are real costs, but they are not independent root causes. They are expensive because `Stage.synchronizeForRead` is being invoked repeatedly during draw.

## What Is Not The Cause

The measurements do not support these as primary causes for the alignments drop:

- `Styling.draw`
- `Styling.paint.border`
- `Styling.paint.background`
- overlay rendering
- clipping
- isolation/compositing

Reasons:
- styling paint totals are small relative to `Stage.draw`
- no clip or isolation zones appeared as dominant rows in the timing report
- `Stage.overlayLayer` time is negligible

## Probable Root Fix

The likely fix is to stop full read synchronization from replaying during `Stage:draw()` for already-updated trees.

The highest-probability fix point is:
- `lib/ui/scene/stage.lua` `synchronize_for_read`

The intended invariant appears to be:
- `Stage:update()` prepares layout and refreshes geometry for the frame
- `Stage:draw()` should then read cached world/local data without triggering another full-tree synchronization

Right now, the measured behavior is:
- `Stage:draw()` enters `Drawable:draw()`
- `Drawable:draw()` asks for bounds
- bounds read re-enters full synchronization

So the root issue is not "drawing is slow".
The root issue is "drawing causes the stage to synchronize again".

## Conclusion

For `alignments.lua`, the performance drop is caused primarily by this function chain:

```text
Drawable:draw
  -> Container:getWorldBounds
    -> ensure_current
      -> Stage._synchronize_for_read
        -> prepare_layout_subtree
        -> run_layout_subtree
        -> refresh_geometry_subtree
```

Measured conclusion:
- about `93.6%` of `Stage.draw` time is spent in the read-synchronization path triggered by bounds resolution
- styling paint is only a small fraction of the frame

So the probable cause of the FPS drop is repeated whole-tree synchronization during draw-time bounds reads, not the retained paint pipeline itself.
