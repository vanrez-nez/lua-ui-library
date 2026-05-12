local Constants = require('lib.ui.core.constants')
local Enum = require('lib.ui.utils.enum')

local enum = Enum.enum

local Enums = {}

Enums.Alignment = enum(
  { START = Constants.ALIGN_START },
  { CENTER = Constants.ALIGN_CENTER },
  { END = Constants.ALIGN_END },
  { STRETCH = Constants.ALIGN_STRETCH }
)

Enums.Justify = enum(
  { START = Constants.ALIGN_START },
  { CENTER = Constants.ALIGN_CENTER },
  { END = Constants.ALIGN_END },
  { SPACE_BETWEEN = Constants.JUSTIFY_SPACE_BETWEEN },
  { SPACE_AROUND = Constants.JUSTIFY_SPACE_AROUND }
)

Enums.SourceAlign = enum(
  { START = Constants.ALIGN_START },
  { CENTER = Constants.ALIGN_CENTER },
  { END = Constants.ALIGN_END }
)

Enums.Padding = enum(
  { LEFT = Constants.PADDING_LEFT },
  { TOP = Constants.PADDING_TOP },
  { RIGHT = Constants.PADDING_RIGHT },
  { BOTTOM = Constants.PADDING_BOTTOM }
)

Enums.Margin = enum(
  { LEFT = Constants.MARGIN_LEFT },
  { TOP = Constants.MARGIN_TOP },
  { RIGHT = Constants.MARGIN_RIGHT },
  { BOTTOM = Constants.MARGIN_BOTTOM }
)

Enums.BlendMode = enum(
  { NORMAL = Constants.BLEND_MODE_NORMAL },
  { ADD = Constants.BLEND_MODE_ADD },
  { SUBTRACT = Constants.BLEND_MODE_SUBTRACT },
  { MULTIPLY = Constants.BLEND_MODE_MULTIPLY },
  { SCREEN = Constants.BLEND_MODE_SCREEN },
  { LIGHTEN = Constants.BLEND_MODE_LIGHTEN },
  { DARKEN = Constants.BLEND_MODE_DARKEN },
  { REPLACE = Constants.BLEND_MODE_REPLACE }
)

Enums.Orientation = enum(
  { HORIZONTAL = Constants.ORIENTATION_HORIZONTAL },
  { VERTICAL = Constants.ORIENTATION_VERTICAL }
)

Enums.Direction = enum(
  { LTR = Constants.DIRECTION_LTR },
  { RTL = Constants.DIRECTION_RTL }
)

Enums.StrokeStyle = enum(
  { SMOOTH = Constants.STROKE_STYLE_SMOOTH },
  { ROUGH = Constants.STROKE_STYLE_ROUGH }
)

Enums.StrokeJoin = enum(
  { MITER = Constants.STROKE_JOIN_MITER },
  { BEVEL = Constants.STROKE_JOIN_BEVEL },
  { NONE = Constants.STROKE_JOIN_NONE }
)

Enums.StrokePattern = enum(
  { SOLID = Constants.STROKE_PATTERN_SOLID },
  { DASHED = Constants.STROKE_PATTERN_DASHED }
)

Enums.FillKind = enum(
  { COLOR = Constants.FILL_KIND_COLOR },
  { GRADIENT = Constants.FILL_KIND_GRADIENT },
  { TEXTURE = Constants.FILL_KIND_TEXTURE }
)

Enums.AlertVariant = enum(
  { DEFAULT = Constants.INTENT_DEFAULT },
  { DESTRUCTIVE = Constants.INTENT_DESTRUCTIVE },
  { SUCCESS = Constants.INTENT_SUCCESS },
  { WARNING = Constants.INTENT_WARNING }
)

Enums.AccessibilityRole = enum(
  { DIALOG = Constants.ROLE_DIALOG },
  { ALERT_DIALOG = Constants.ROLE_ALERT_DIALOG }
)

Enums.Event = enum(
  { ACTIVATE = Constants.EVENT_ACTIVATE },
  { DEACTIVATE = Constants.EVENT_DEACTIVATE },
  { DRAG = Constants.EVENT_DRAG },
  { DRAG_START = Constants.EVENT_DRAG_START },
  { DRAG_END = Constants.EVENT_DRAG_END },
  { FOCUS = Constants.EVENT_FOCUS },
  { BLUR = Constants.EVENT_BLUR },
  { HOVER = Constants.EVENT_HOVER },
  { HOVER_START = Constants.EVENT_HOVER_START },
  { HOVER_END = Constants.EVENT_HOVER_END },
  { PRESS = Constants.EVENT_PRESS },
  { RELEASE = Constants.EVENT_RELEASE },
  { CLICK = Constants.EVENT_CLICK },
  { DOUBLE_CLICK = Constants.EVENT_DOUBLE_CLICK },
  { SCROLL = Constants.EVENT_SCROLL },
  { ZOOM = Constants.EVENT_ZOOM },
  { ROTATE = Constants.EVENT_ROTATE },
  { PAN = Constants.EVENT_PAN },
  { PINCH = Constants.EVENT_PINCH },
  { KEY_DOWN = Constants.EVENT_KEY_DOWN },
  { KEY_UP = Constants.EVENT_KEY_UP },
  { KEY_PRESS = Constants.EVENT_KEY_PRESS },
  { TEXT_INPUT = Constants.EVENT_TEXT_INPUT },
  { TEXT_EDIT = Constants.EVENT_TEXT_EDIT },
  { TEXT_COMPOSITION_START = Constants.EVENT_TEXT_COMPOSITION_START },
  { TEXT_COMPOSITION_END = Constants.EVENT_TEXT_COMPOSITION_END },
  { VALUE_CHANGE = Constants.EVENT_VALUE_CHANGE },
  { SELECTION_CHANGE = Constants.EVENT_SELECTION_CHANGE },
  { NAVIGATION = Constants.EVENT_NAVIGATION },
  { CANCEL = Constants.EVENT_CANCEL }
)

Enums.DragPhase = enum(
  { START = Constants.DRAG_PHASE_START },
  { MOVE = Constants.DRAG_PHASE_MOVE },
  { END = Constants.DRAG_PHASE_END }
)

Enums.NavigationDirection = enum(
  { UP = Constants.NAVIGATION_DIRECTION_UP },
  { DOWN = Constants.NAVIGATION_DIRECTION_DOWN },
  { LEFT = Constants.NAVIGATION_DIRECTION_LEFT },
  { RIGHT = Constants.NAVIGATION_DIRECTION_RIGHT }
)

Enums.NavigationMode = enum(
  { SEQUENTIAL = Constants.NAVIGATION_MODE_SEQUENTIAL },
  { DIRECTIONAL = Constants.NAVIGATION_MODE_DIRECTIONAL }
)

Enums.PointerFocusCoupling = enum(
  { BEFORE = Constants.POINTER_FOCUS_COUPLING_BEFORE },
  { AFTER = Constants.POINTER_FOCUS_COUPLING_AFTER },
  { NONE = Constants.POINTER_FOCUS_COUPLING_NONE }
)

Enums.Edge = enum(
  { TOP = Constants.EDGE_TOP },
  { BOTTOM = Constants.EDGE_BOTTOM },
  { LEFT = Constants.EDGE_LEFT },
  { RIGHT = Constants.EDGE_RIGHT }
)

Enums.VisualVariant = enum(
  { BASE = Constants.VISUAL_VARIANT_BASE },
  { DISABLED = Constants.VISUAL_VARIANT_DISABLED },
  { FOCUSED = Constants.VISUAL_VARIANT_FOCUSED },
  { CHECKED = Constants.VISUAL_VARIANT_CHECKED },
  { UNCHECKED = Constants.VISUAL_VARIANT_UNCHECKED },
  { INDETERMINATE = Constants.VISUAL_VARIANT_INDETERMINATE },
  { SELECTED = Constants.VISUAL_VARIANT_SELECTED },
  { PRESSED = Constants.VISUAL_VARIANT_PRESSED },
  { HOVERED = Constants.VISUAL_VARIANT_HOVERED },
  { DRAGGING = Constants.VISUAL_VARIANT_DRAGGING },
  { READ_ONLY = Constants.VISUAL_VARIANT_READ_ONLY },
  { COMPOSING = Constants.VISUAL_VARIANT_COMPOSING },
  { ACTIVE = Constants.VISUAL_VARIANT_ACTIVE },
  { INACTIVE = Constants.VISUAL_VARIANT_INACTIVE },
  { OPEN = Constants.VISUAL_VARIANT_OPEN },
  { DETERMINATE = Constants.VISUAL_VARIANT_DETERMINATE }
)

Enums.SizeMode = enum(
  { FILL = Constants.SIZE_MODE_FILL },
  { CONTENT = Constants.SIZE_MODE_CONTENT }
)

Enums.GraphicsDrawMode = enum(
  { FILL = Constants.GRAPHICS_DRAW_MODE_FILL },
  { LINE = Constants.GRAPHICS_DRAW_MODE_LINE }
)

Enums.EventPhase = enum(
  { CAPTURE = Constants.EVENT_PHASE_CAPTURE },
  { TARGET = Constants.EVENT_PHASE_TARGET },
  { BUBBLE = Constants.EVENT_PHASE_BUBBLE }
)

Enums.ScrollState = enum(
  { IDLE = Constants.SCROLL_STATE_IDLE },
  { DRAGGING = Constants.SCROLL_STATE_DRAGGING },
  { INERTIAL = Constants.SCROLL_STATE_INERTIAL }
)

return Enums
