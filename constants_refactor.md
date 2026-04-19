# Plan: Centralize Shared String Enums

## Context

String enum values are scattered across 40+ files. Some are duplicated identically across modules (e.g., `JUSTIFY_VALUES` copy-pasted 3 times). The refactor must handle three categories of enum ownership, not just one.

## Three Categories of Enum Ownership

### 1. Global Shared Constants
Enums used across multiple modules with no single owner. These go in `lib/ui/core/enums.lua`.

| Group | Values | Used in |
|-------|--------|---------|
| **Alignment** | `start`, `center`, `end`, `stretch` | drawable_schema, layout_node_schema, flow, sequential_layout, image, shape_schema, styling |
| **Justify** | `start`, `center`, `end`, `space-between`, `space-around` | layout_node_schema, flow, sequential_layout |
| **SourceAlign** | `start`, `center`, `end` | graphics_validation, shape_schema, drawable_schema |
| **BlendMode** | `normal`, `add`, `subtract`, `multiply`, `screen`, `lighten`, `darken`, `replace` | graphics_validation, drawable_schema, shape_schema, graphics_state |
| **Orientation** | `horizontal`, `vertical` | slider, radio_group, tabs, graphics_validation, fill_placement, fill_renderer, styling, scrollable_container |
| **Direction** | `ltr`, `rtl` | direction, flow, sequential_layout |
| **StrokeStyle** | `smooth`, `rough` | drawable_schema, shape_schema, styling |
| **StrokeJoin** | `miter`, `bevel`, `none` | drawable_schema, shape_schema, draw_helpers |
| **StrokePattern** | `solid`, `dashed` | drawable_schema, shape_schema, draw_helpers, styling, circle_shape |
| **FillKind** | `color`, `gradient`, `texture` | fill_source, fill_placement, fill_renderer, shape |
| **Event** | `ui.activate`, `ui.drag`, etc. | stage + 10+ controls |
| **DragPhase** | `start`, `move`, `end` | stage, button, slider, switch, scrollable_container |
| **NavigationDirection** | `up`, `down`, `left`, `right` | stage, radio_group, select, slider, tabs |
| **NavigationMode** | `sequential`, `directional` | stage, radio_group, select, slider, tabs, text_input |
| **PointerFocusCoupling** | `before`, `after`, `none` | stage + 9 controls |
| **Edge** | `top`, `bottom`, `left`, `right` | notification, tooltip, stage |
| **VisualVariant** | `base`, `disabled`, `focused`, `checked`, `unchecked`, `indeterminate`, `selected`, `pressed`, `hovered`, `dragging`, `readOnly`, `composing`, `active`, `inactive`, `open`, `determinate` | 6+ controls |
| **SizeMode** | `fill`, `content` | container_schema, container, drawable, flow, sequential_layout, content_fill_guard, scrollable_container, stage + more |
| **GraphicsDrawMode** | `fill`, `line` | draw_helpers, styling, circle_shape, container |
| **EventPhase** | `capture`, `target`, `bubble` | event, event_dispatcher, stage |

### 2. Class-Exported Constants
Enums whose domain is a single class, but that class exposes them on its module table so external callers can reference them statically instead of raw strings.

```lua
-- tooltip.lua (owner)
Tooltip.Placement = { top = 'top', bottom = 'bottom', left = 'left', right = 'right' }
Tooltip.Align = { start = 'start', center = 'center', ['end'] = 'end' }
Tooltip.TriggerMode = { hover = 'hover', focus = 'focus', ['hover-focus'] = 'hover-focus', manual = 'manual' }

-- consumer (another module)
require('lib.ui.controls.tooltip')
local placement = Tooltip.Placement.top  -- not 'top' as raw string
```

| Group | Owner | Values |
|-------|-------|--------|
| **Placement / Align / TriggerMode** | `tooltip.lua` | top/bottom/left/right, start/center/end, hover/focus/hover-focus/manual |
| **State** | `checkbox.lua` | checked, unchecked, indeterminate |
| **SelectionMode** | `select.lua` | single, multiple |
| **SnapBehavior** | `switch.lua` | nearest, directional |
| **InputMode** | `text_input.lua` | text, numeric, email, url, search |
| **SubmitBehavior** | `text_input.lua` | blur, submit, none |
| **Fit / Align / Sampling** | `image.lua` | contain/cover/stretch/none, start/center/end, nearest/linear |
| **ScrollState** | `scrollable_container.lua` | idle, dragging, inertial |

Pattern: `ClassName.EnumName.value` — the class owns and defines the enum, but other modules reference it through the class table rather than duplicating the string.

### 3. Local Top-Level Declarations
Strings used only within one file, not exported, not shared. A `local` constant at the top of the file is sufficient.

| Group | File | Why local |
|-------|------|-----------|
| FillPlacementMode | fill_placement.lua | Only consumed internally |
| GradientKind | graphics_validation.lua | Single validator |
| QuadKind | side_quad/corner_quad | Internal |
| StencilCompare | graphics_stencil + root_compositor | Tightly coupled pair |
| ResultClipKind | root_compositor + shape | Specialized |
| ViewportOrientation | stage.lua | Internal |
| PointerType | stage.lua | Internal |
| ScrollAxis | stage.lua | Internal |
| ResponsiveSourceKind | responsive.lua | Internal |
| DirtyGroup | container/shape/layout_node | Internal runtime flags |

These already use local constants or don't need extraction — no change needed.

## Module API: `lib/ui/core/enums.lua`

Each global shared group exposes three forms:

| Form | Example | Use case |
|------|---------|----------|
| Named constants | `Enums.Alignment.start` → `'start'` | Runtime comparisons |
| Lookup set | `Enums.alignment_values` → `{ start = true, ... }` | Validation, membership |
| Ordered list | `Enums.alignment_list` → `{ 'start', 'center', 'end', 'stretch' }` | `Rule.enum()` calls |

Class-exported enums follow a two-form pattern (constants + lookup set/list on the class table), since the class IS the namespace.

## Migration Phases

### Phase 1: Create `lib/ui/core/enums.lua`
- Define all 20 global shared groups
- No existing files modified

### Phase 2: Remove highest-duplication targets
- `layout/layout_node_schema.lua` — replace `JUSTIFY_VALUES` + `ALIGN_VALUES` with Enums refs
- `layout/flow.lua` — same
- `layout/sequential_layout.lua` — same
- `core/drawable_schema.lua` — replace `ALIGNMENT_VALUES`

### Phase 3: Refactor `graphics_validation.lua`
- `ROOT_BLEND_MODE_VALUES` → `Enums.blend_mode_list`
- `SOURCE_ALIGN_VALUES` → `Enums.source_align_list`
- Keep validation functions in place

### Phase 4: Migrate remaining global-enum schemas
- `core/shape_schema.lua` — stroke enums
- `layout/direction.lua` — `VALID_VALUES`
- `event/event.lua` — `VALID_PHASES`
- `event/event_dispatcher.lua` — `VALID_EVENT_LISTENER_PHASES`

### Phase 5: Add class-exported constants
For each class in Category 2, add enum sub-tables to the class module:
- `tooltip.lua` — `Tooltip.Placement`, `Tooltip.Align`, `Tooltip.TriggerMode`
- `checkbox.lua` — `Checkbox.State`
- `select.lua` — `Select.SelectionMode`
- `switch.lua` — `Switch.SnapBehavior`
- `text_input.lua` — `TextInput.InputMode`, `TextInput.SubmitBehavior`
- `image.lua` — `Image.Fit`, `Image.Align`, `Image.Sampling`
- `scrollable_container.lua` — `ScrollableContainer.State`

### Phase 6: Migrate raw string comparisons
- `scene/stage.lua` — events, navigation, drag phases, pointer coupling, size mode
- `core/container.lua` — size mode, draw mode, dirty groups
- Layout files — `'fill'`/`'content'`/`'horizontal'`/`'vertical'`
- Controls — event types, orientation, visual variants, edge
- External callers of class methods — use `Tooltip.Placement.top` instead of `'top'`

### Phase 7: Clean up `lib/ui/init.lua`
- Expose `Enums` on public API if desired

## Files

| File | Change |
|------|--------|
| `lib/ui/core/enums.lua` | **New** — global shared enum definitions |
| `lib/ui/core/drawable_schema.lua` | Remove `ALIGNMENT_VALUES` |
| `lib/ui/layout/layout_node_schema.lua` | Remove `JUSTIFY_VALUES` + `ALIGN_VALUES` |
| `lib/ui/layout/flow.lua` | Remove `JUSTIFY_VALUES` + `ALIGN_VALUES` |
| `lib/ui/layout/sequential_layout.lua` | Remove `JUSTIFY_VALUES` + `ALIGN_VALUES` |
| `lib/ui/render/graphics_validation.lua` | Replace constant arrays with Enums refs |
| `lib/ui/core/shape_schema.lua` | Use Enums for stroke enums |
| `lib/ui/layout/direction.lua` | Remove `VALID_VALUES` |
| `lib/ui/event/event.lua` | Remove `VALID_PHASES` |
| `lib/ui/event/event_dispatcher.lua` | Remove `VALID_EVENT_LISTENER_PHASES` |
| `lib/ui/controls/tooltip.lua` | Add `Tooltip.Placement`, `Tooltip.Align`, `Tooltip.TriggerMode` |
| `lib/ui/controls/checkbox.lua` | Add `Checkbox.State` |
| `lib/ui/controls/select.lua` | Add `Select.SelectionMode` |
| `lib/ui/controls/switch.lua` | Add `Switch.SnapBehavior` |
| `lib/ui/controls/text_input.lua` | Add `TextInput.InputMode`, `TextInput.SubmitBehavior` |
| `lib/ui/graphics/image.lua` | Add `Image.Fit`, `Image.Align`, `Image.Sampling` |
| `lib/ui/scroll/scrollable_container.lua` | Add `ScrollableContainer.State` |
| `lib/ui/scene/stage.lua` | Replace event/navigation/drag strings |
| `lib/ui/core/container.lua` | Replace size mode, draw mode, dirty groups |
| `lib/ui/render/draw_helpers.lua` | Use Enums for stroke/draw mode |
| `lib/ui/render/styling.lua` | Use Enums for stroke/orientation |
| 10+ control files | Replace event types, orientation, variants with Enums refs |

## Verification

- Run all specs after each phase
- Run luacheck after each phase: `./lua_modules/bin/luacheck .`
- No behavior changes — string values are identical, only references change