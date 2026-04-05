# Incident: Descendant Layout Stays Stale After Ancestor Size Change

## Summary

Changing a parent container size through normal property assignment can update
measurement and bounds without forcing descendant layout nodes to rerun their
layout algorithm.

This leaves mixed layout trees in a stale state until a broader invalidation
event happens, such as `Stage:resize()`.

The issue was reproduced in the page layout demo with this shape:

- `Root = Column`
- `Body = Row`
- `Content = Flow`
- `Sidebar = Column`

`Body` distributes:

- `Content.width = 'fill'`
- `Sidebar.width = '40%'`

When `Root.width` changes, `Body` gets a new width, but `Body` does not rerun
its row distribution immediately. `Content` keeps the stale full-row width and
overlaps `Sidebar`.

Resizing the window fixes it because `Stage:resize()` marks the whole layout
subtree dirty and forces descendant layout nodes to rerun `_apply_layout()`.

---

## Reproduction

The problem was reproduced with a headless Lua script using the same scene
shape as
[layout_page.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/demos/02-drawable/screens/layout_page.lua).

Repro steps:

1. Create a `Stage` with `width = 1400`, `height = 900`
2. Build this tree:
   - `layout-page-root = Column(width = 500, height = '70%')`
   - `layout-page-body = Row(width = 'fill', height = 'fill')`
   - `layout-page-content = Flow(width = 'fill', height = 'fill')`
   - `layout-page-sidebar = Column(width = '40%', height = 'fill')`
3. Run `stage:update(0)`
4. Assign `page.width = '50%'`
5. Run `stage:update(0)` again
6. Read resolved widths from `getLocalBounds()`
7. Then call `stage:resize(1000, 900)` and read the same widths again

Observed values:

### After `page.width = '50%'`

- `page = 700`
- `body = 660`
- `content = 660`
- `sidebar = 264`

This is invalid distribution, because `content + sidebar > body`.

### After `stage:resize(1000, 900)`

- `page = 1000`
- `body = 960`
- `content = 556`
- `sidebar = 384`

This is the expected distribution, because the row is rerun and `Content`
takes the remaining width after `Sidebar`.

---

## Root Cause

### What A Width Assignment Does

Assigning a measurement property such as `page.width = '50%'` goes through
[container.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua).

That path:

- marks the target node `_responsive_dirty`
- marks the target node `_measurement_dirty`
- invalidates ancestor layout measurement
- invalidates descendant geometry through
  `invalidate_descendant_geometry()`

Relevant path:

- [container.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua#L1604)
- [container.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/core/container.lua#L91)

That is enough to refresh:

- measurement
- transforms
- bounds

It is **not** enough to guarantee that descendant layout nodes rerun their own
layout algorithm.

### What A Layout Node Needs

Layout nodes only rerun `_apply_layout()` when `_layout_dirty` is true:

- [layout_node.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/layout/layout_node.lua#L143)

So a descendant `Row`, `Column`, or `Flow` can be measurement-dirty while still
skipping its actual layout distribution pass if `_layout_dirty` was not set.

### What `Stage:resize()` Does Differently

`Stage:resize()` calls `_mark_layout_subtree_dirty()`:

- [stage.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua#L1516)
- [stage.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/scene/stage.lua#L2171)

That recursively calls `markDirty()` on the whole subtree.

For layout nodes, `LayoutNode:markDirty()` sets `_layout_dirty = true`:

- [layout_node.lua](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/layout/layout_node.lua#L90)

That is why window resize fixes the page: the descendant layout nodes are
finally forced to rerun `_apply_layout()`.

---

## Why This Shows Up In The Page Demo

The page demo exposes the issue because it has a dependent layout chain:

- ancestor width changes at `Root`
- descendant distribution is owned by `Body = Row`
- `Body` contains:
  - one child with `width = 'fill'`
  - one child with `width = '40%'`

That means `Body` must recompute layout whenever its available width changes.

The current property-write invalidation path updates sizes, but it does not
promote that ancestor width change into `_layout_dirty` on the descendant row.

So `Body` can keep stale child distribution until a stronger invalidation event
arrives.

---

## Why Other Layout Demos Did Not Obviously Fail

This issue is easiest to see when all of these are true:

- a parent size changes
- a descendant layout node owns redistribution
- the descendant mixes `fill` and parent-relative sizing
- the stale result remains visually obvious

The page demo is a particularly sharp repro because `Body = Row` has exactly
that structure.

Other demos may avoid surfacing it because:

- they mutate the layout node being demonstrated directly
- they do not have the same ancestor-to-descendant redistribution chain
- their setup path already triggers a second update after moving/centering
- their child sizing mix does not produce visible overlap when stale

Those cases do not disprove the bug. They only make it less visible.

---

## Expected Contract

If an ancestor size change affects the available content size of a descendant
layout node, that descendant layout node should rerun layout in the next update
pass without requiring a host viewport resize.

More concretely:

- a measurement change that alters a layout parent's available child region
  should mark dependent descendant layout nodes `_layout_dirty`
- property writes and `Stage:resize()` should not diverge in whether descendant
  layout distribution is recomputed

---

## Patch Direction

The fix should be in invalidation behavior, not in the demo.

Promising directions:

1. Promote ancestor measurement changes into descendant layout dirtiness for
   layout nodes, not just measurement dirtiness.
2. Ensure `invalidate_descendant_geometry()` or the relevant measurement-change
   path marks descendant layout nodes `_layout_dirty` when their parent
   available space changed.
3. Keep `Stage:resize()` behavior as the reference for the required invalidation
   strength.

The demo should not need to fake a resize or force unrelated extra updates just
to make descendant layout distribution correct.
