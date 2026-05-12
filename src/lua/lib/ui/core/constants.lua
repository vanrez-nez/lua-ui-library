local Constants = {}

-- Align
Constants.ALIGN_START = 'start'
Constants.ALIGN_CENTER = 'center'
Constants.ALIGN_END = 'end'
Constants.ALIGN_STRETCH = 'stretch'

-- Justify
Constants.JUSTIFY_SPACE_BETWEEN = 'space-between'
Constants.JUSTIFY_SPACE_AROUND = 'space-around'

-- BlendMode
Constants.BLEND_MODE_NORMAL = 'normal'
Constants.BLEND_MODE_ADD = 'add'
Constants.BLEND_MODE_SUBTRACT = 'subtract'
Constants.BLEND_MODE_MULTIPLY = 'multiply'
Constants.BLEND_MODE_SCREEN = 'screen'
Constants.BLEND_MODE_LIGHTEN = 'lighten'
Constants.BLEND_MODE_DARKEN = 'darken'
Constants.BLEND_MODE_REPLACE = 'replace'

-- Orientation
Constants.ORIENTATION_HORIZONTAL = 'horizontal'
Constants.ORIENTATION_VERTICAL = 'vertical'

-- Direction
Constants.DIRECTION_LTR = 'ltr'
Constants.DIRECTION_RTL = 'rtl'

-- StrokeStyle
Constants.STROKE_STYLE_SMOOTH = 'smooth'
Constants.STROKE_STYLE_ROUGH = 'rough'

-- StrokeJoin
Constants.STROKE_JOIN_MITER = 'miter'
Constants.STROKE_JOIN_BEVEL = 'bevel'
Constants.STROKE_JOIN_NONE = 'none'

-- StrokePattern
Constants.STROKE_PATTERN_SOLID = 'solid'
Constants.STROKE_PATTERN_DASHED = 'dashed'

-- FillKind
Constants.FILL_KIND_COLOR = 'color'
Constants.FILL_KIND_GRADIENT = 'gradient'
Constants.FILL_KIND_TEXTURE = 'texture'

-- Intent
Constants.INTENT_DEFAULT = 'default'
Constants.INTENT_DESTRUCTIVE = 'destructive'
Constants.INTENT_SUCCESS = 'success'
Constants.INTENT_WARNING = 'warning'

-- Role
Constants.ROLE_DIALOG = 'dialog'
Constants.ROLE_ALERT_DIALOG = 'alertdialog'

-- Margin
Constants.MARGIN_LEFT = 'marginLeft'
Constants.MARGIN_TOP = 'marginTop'
Constants.MARGIN_RIGHT = 'marginRight'
Constants.MARGIN_BOTTOM = 'marginBottom'

-- Padding
Constants.PADDING_LEFT = 'paddingLeft'
Constants.PADDING_TOP = 'paddingTop'
Constants.PADDING_RIGHT = 'paddingRight'
Constants.PADDING_BOTTOM = 'paddingBottom'

-- Event
Constants.EVENT_ACTIVATE = 'ui.activate'
Constants.EVENT_DEACTIVATE = 'ui.deactivate'
Constants.EVENT_DRAG = 'ui.drag'
Constants.EVENT_DRAG_START = 'ui.drag_start'
Constants.EVENT_DRAG_END = 'ui.drag_end'
Constants.EVENT_FOCUS = 'ui.focus'
Constants.EVENT_BLUR = 'ui.blur'
Constants.EVENT_HOVER = 'ui.hover'
Constants.EVENT_HOVER_START = 'ui.hover_start'
Constants.EVENT_HOVER_END = 'ui.hover_end'
Constants.EVENT_PRESS = 'ui.press'
Constants.EVENT_RELEASE = 'ui.release'
Constants.EVENT_CLICK = 'ui.click'
Constants.EVENT_DOUBLE_CLICK = 'ui.double_click'
Constants.EVENT_SCROLL = 'ui.scroll'
Constants.EVENT_ZOOM = 'ui.zoom'
Constants.EVENT_ROTATE = 'ui.rotate'
Constants.EVENT_PAN = 'ui.pan'
Constants.EVENT_PINCH = 'ui.pinch'
Constants.EVENT_KEY_DOWN = 'ui.key_down'
Constants.EVENT_KEY_UP = 'ui.key_up'
Constants.EVENT_KEY_PRESS = 'ui.key_press'
Constants.EVENT_TEXT_INPUT = 'ui.text_input'
Constants.EVENT_TEXT_EDIT = 'ui.text_edit'
Constants.EVENT_TEXT_COMPOSITION_START = 'ui.text_composition_start'
Constants.EVENT_TEXT_COMPOSITION_END = 'ui.text_composition_end'
Constants.EVENT_VALUE_CHANGE = 'ui.value_change'
Constants.EVENT_SELECTION_CHANGE = 'ui.selection_change'
Constants.EVENT_NAVIGATION = 'ui.navigation'
Constants.EVENT_CANCEL = 'ui.cancel'

-- DragPhase
Constants.DRAG_PHASE_START = 'start'
Constants.DRAG_PHASE_MOVE = 'move'
Constants.DRAG_PHASE_END = 'end'

-- NavigationDirection
Constants.NAVIGATION_DIRECTION_UP = 'up'
Constants.NAVIGATION_DIRECTION_DOWN = 'down'
Constants.NAVIGATION_DIRECTION_LEFT = 'left'
Constants.NAVIGATION_DIRECTION_RIGHT = 'right'

-- NavigationMode
Constants.NAVIGATION_MODE_SEQUENTIAL = 'sequential'
Constants.NAVIGATION_MODE_DIRECTIONAL = 'directional'

-- PointerFocusCoupling
Constants.POINTER_FOCUS_COUPLING_BEFORE = 'before'
Constants.POINTER_FOCUS_COUPLING_AFTER = 'after'
Constants.POINTER_FOCUS_COUPLING_NONE = 'none'

-- Corner
Constants.TOP_LEFT = 'topLeft'
Constants.TOP_RIGHT = 'topRight'
Constants.BOTTOM_LEFT = 'bottomLeft'
Constants.BOTTOM_RIGHT = 'bottomRight'

-- Edge
Constants.EDGE_TOP = 'top'
Constants.EDGE_BOTTOM = 'bottom'
Constants.EDGE_LEFT = 'left'
Constants.EDGE_RIGHT = 'right'

-- VisualVariant
Constants.VISUAL_VARIANT_BASE = 'base'
Constants.VISUAL_VARIANT_DISABLED = 'disabled'
Constants.VISUAL_VARIANT_FOCUSED = 'focused'
Constants.VISUAL_VARIANT_CHECKED = 'checked'
Constants.VISUAL_VARIANT_UNCHECKED = 'unchecked'
Constants.VISUAL_VARIANT_INDETERMINATE = 'indeterminate'
Constants.VISUAL_VARIANT_SELECTED = 'selected'
Constants.VISUAL_VARIANT_PRESSED = 'pressed'
Constants.VISUAL_VARIANT_HOVERED = 'hovered'
Constants.VISUAL_VARIANT_DRAGGING = 'dragging'
Constants.VISUAL_VARIANT_READ_ONLY = 'readOnly'
Constants.VISUAL_VARIANT_COMPOSING = 'composing'
Constants.VISUAL_VARIANT_ACTIVE = 'active'
Constants.VISUAL_VARIANT_INACTIVE = 'inactive'
Constants.VISUAL_VARIANT_OPEN = 'open'
Constants.VISUAL_VARIANT_DETERMINATE = 'determinate'

-- SizeMode
Constants.SIZE_MODE_FILL = 'fill'
Constants.SIZE_MODE_CONTENT = 'content'

-- GraphicsDrawMode
Constants.GRAPHICS_DRAW_MODE_FILL = 'fill'
Constants.GRAPHICS_DRAW_MODE_LINE = 'line'

-- EventPhase
Constants.EVENT_PHASE_CAPTURE = 'capture'
Constants.EVENT_PHASE_TARGET = 'target'
Constants.EVENT_PHASE_BUBBLE = 'bubble'

-- ScrollState
Constants.SCROLL_STATE_IDLE = 'idle'
Constants.SCROLL_STATE_DRAGGING = 'dragging'
Constants.SCROLL_STATE_INERTIAL = 'inertial'

return Constants
