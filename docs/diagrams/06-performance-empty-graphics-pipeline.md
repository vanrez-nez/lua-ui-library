# `demos/06-performance/screens/empty.lua` Graphics Pipeline

This diagram is intentionally narrow. It traces the concrete draw path used by
[`demos/06-performance/screens/empty.lua`](/Users/vanrez/Documents/game-dev/lua-ui-library/demos/06-performance/screens/empty.lua:1),
not the full UI library.

## Frame Draw Flow

```mermaid
flowchart TD
    A["demos/00-common-base/main.lua<br/>love.draw()"] --> B["demos/common/demo_base.lua<br/>DemoBase:draw()"]
    B --> C["demos/common/screen_helper.lua<br/>screen_wrapper(...).draw()"]
    C --> D["lib/ui/scene/stage.lua<br/>Stage:draw(graphics, draw_callback)"]
    D --> E["lib/ui/core/container.lua<br/>Container:_draw_subtree_resolved()"]
    E --> F["lib/ui/core/container.lua<br/>draw_subtree(self, graphics, draw_callback, ...)"]
    F --> G{"lib/ui/render/root_compositor.lua<br/>plan_requires_isolation(effects)?"}
    G -->|No for this screen| H["lib/ui/scene/stage.lua<br/>draw_node_default(node, graphics)"]
    G -->|Yes| I["lib/ui/render/root_compositor.lua<br/>RootCompositor.draw_isolated_subtree()"]
    H --> J["node.draw(node, graphics)"]
    J --> K["lib/ui/graphics/image.lua<br/>Image:draw() = no-op"]
    H --> L["node._draw_control(node, graphics)"]
    L --> M["lib/ui/graphics/image.lua<br/>Image:_draw_control(graphics)"]
    M --> N["love.graphics.draw(...)"]
    H --> O["demos/common/screen_helper.lua<br/>helpers.draw_demo_node / draw_demo_markers"]
    O --> P["No visible extra work for Image nodes in this screen"]
```

## Per-Image Hot Path

```mermaid
flowchart TD
    A["demos/06-performance/screens/empty.lua<br/>build(stage)"] --> B["UI.Image.new({...}) x N"]
    B --> C["root:addChild(image)"]
    C --> D["demos/common/screen_helper.lua<br/>screen draw calls stage:draw(...)"]
    D --> E["lib/ui/scene/stage.lua<br/>Stage:draw()"]
    E --> F["lib/ui/core/container.lua<br/>draw_subtree(image, graphics, draw_callback, ...)"]
    F --> G["lib/ui/scene/stage.lua<br/>draw_node_default(image, graphics)"]
    G --> H["lib/ui/graphics/image.lua<br/>Image:draw()"]
    H --> I["closed primitive: no background/border draw"]
    G --> J["lib/ui/graphics/image.lua<br/>Image:_draw_control(graphics)"]
    J --> K["resolve_source_metrics(source)"]
    K --> L["texture:getDrawable()"]
    L --> M["self:getWorldBounds()"]
    M --> N["resolve_draw_geometry(...)"]
    N --> O["resolve_quad(...) if source is a Sprite region"]
    O --> P["apply_sampling(texture, drawable, self.sampling)"]
    P --> Q{"self.fit == 'cover'?"}
    Q -->|No in empty.lua| R["skip temporary scissor"]
    Q -->|Yes| S["setScissor(content rect)"]
    R --> T["graphics.draw(drawable or drawable+quad, x, y, 0, sx, sy)"]
    S --> T
    T --> U["restore scissor only if cover path used"]
```

## What Is Specific To `empty.lua`

- All spawned nodes are `Image` primitives backed by one shared `Texture`.
- `fit = "contain"` and `sampling = "linear"` for every spawned image.
- The screen mutates only `x` and `y` during update; draw stays on the same image path each frame.
- No per-image root `opacity`, `blendMode`, `shader`, `mask`, or `clipChildren` is set in this screen, so the normal expectation is the non-isolated root-compositing path.
- The actual pixel submission happens in [`lib/ui/graphics/image.lua`](/Users/vanrez/Documents/game-dev/lua-ui-library/lib/ui/graphics/image.lua:284), not in `Image:draw()`.
