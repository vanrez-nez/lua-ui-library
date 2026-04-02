local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Schema = require('lib.ui.utils.schema')
local Rectangle = require('lib.ui.core.rectangle')
local Object = require('lib.cls')

local max = math.max
local min = math.min
local abs = math.abs

-- ────────────────────────────────────────────────────────────────────────────
-- ScrollableContainer
--
-- A structural primitive that clips descendant content and exposes scroll
-- state.  Not a layout family peer of Row or Column.
--
-- Anatomy:
--   root       = self
--   viewport   = internal Container with clipChildren = true
--   content    = internal Container inside viewport (consumer adds children here)
--   scrollbars = optional visual Drawable nodes
-- ────────────────────────────────────────────────────────────────────────────

local ScrollableContainer = Container:extends('ScrollableContainer')
ScrollableContainer._schema = require('lib.ui.scroll.scrollable_container_schema')

-- ── Constants ───────────────────────────────────────────────────────────────

local VELOCITY_STOP_THRESHOLD = 0.5
local OVERSCROLL_RESISTANCE   = 0.4
local OVERSCROLL_SNAP_SPEED   = 0.15
local SCROLLBAR_SIZE          = 6
local SCROLLBAR_MIN_THUMB     = 20
local SCROLLBAR_MARGIN        = 2
local SCROLLBAR_MIN_OVERSHOOT_THUMB = 2
local DELTA_EPSILON           = 1e-6

local STATE_IDLE     = 'idle'
local STATE_DRAGGING = 'dragging'
local STATE_INERTIAL = 'inertial'

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function get_effective(self, key)
    local ev = rawget(self, '_effective_values')
    return ev and ev[key]
end

local function get_public(self, key)
    local pv = rawget(self, '_public_values')
    return pv and pv[key]
end

local function clamp(value, lo, hi)
    if lo > hi then return lo end
    if value < lo then return lo end
    if value > hi then return hi end
    return value
end

-- ── Content extent measurement ──────────────────────────────────────────────

local function measure_content_extent(content_node)
    local children = rawget(content_node, '_children') or {}
    local max_right  = 0
    local max_bottom = 0

    for i = 1, #children do
        local child = children[i]
        local ev = rawget(child, '_effective_values')
        if ev == nil or ev.visible ~= false then
            local w = child._resolved_width  or 0
            local h = child._resolved_height or 0
            local cx = child._layout_offset_x or 0
            local cy = child._layout_offset_y or 0
            -- Also consider raw x/y for non-layout children
            local px = (ev and ev.x) or 0
            local py = (ev and ev.y) or 0
            max_right  = max(max_right,  cx + px + w)
            max_bottom = max(max_bottom, cy + py + h)
        end
    end

    return max_right, max_bottom
end

-- ── Scroll range ────────────────────────────────────────────────────────────

local function compute_scroll_range(self)
    local viewport_node = rawget(self, '_viewport')
    local content_node  = rawget(self, '_content')
    if not viewport_node or not content_node then
        return 0, 0, 0, 0
    end

    local vw = viewport_node._resolved_width  or 0
    local vh = viewport_node._resolved_height or 0
    local cw, ch = measure_content_extent(content_node)
    rawset(self, '_content_width', cw)
    rawset(self, '_content_height', ch)

    local max_x = max(0, cw - vw)
    local max_y = max(0, ch - vh)

    -- Suppress axis when disabled
    if not get_public(self, 'scrollXEnabled') then max_x = 0 end
    if not get_public(self, 'scrollYEnabled') then max_y = 0 end

    return max_x, max_y, vw, vh
end

-- ── Offset clamping ─────────────────────────────────────────────────────────

local function clamp_offsets(self, allow_overscroll)
    local max_x, max_y = compute_scroll_range(self)
    rawset(self, '_max_scroll_x', max_x)
    rawset(self, '_max_scroll_y', max_y)

    local sx = rawget(self, '_scroll_x') or 0
    local sy = rawget(self, '_scroll_y') or 0

    if not allow_overscroll or not get_public(self, 'overscroll') then
        sx = clamp(sx, 0, max_x)
        sy = clamp(sy, 0, max_y)
    end

    rawset(self, '_scroll_x', sx)
    rawset(self, '_scroll_y', sy)
end

-- ── Apply scroll offset to content position ─────────────────────────────────

local function apply_content_offset(self)
    local content_node = rawget(self, '_content')
    if not content_node then return end

    local sx = rawget(self, '_scroll_x') or 0
    local sy = rawget(self, '_scroll_y') or 0

    -- Move content in the opposite direction of scroll offset
    local pv = rawget(content_node, '_public_values')
    if pv then
        pv.x = -sx
        pv.y = -sy
    end
    local ev = rawget(content_node, '_effective_values')
    if ev then
        ev.x = -sx
        ev.y = -sy
    end
    rawset(content_node, '_local_transform_dirty', true)
    content_node:invalidate_world()
    content_node:invalidate_descendant_world()
end

-- ── Scrollbar geometry ──────────────────────────────────────────────────────

local function update_scrollbar_geometry(self)
    local function mark_node_geometry_dirty(node)
        if not node then return end
        rawset(node, '_measurement_dirty', true)
        rawset(node, '_local_transform_dirty', true)
        rawset(node, '_bounds_dirty', true)
        node:invalidate_world()
        node:invalidate_descendant_world()
    end

    local function set_node_frame(node, x, y, width, height, visible)
        if not node then return end

        local changed = false
        local pv = rawget(node, '_public_values')
        local ev = rawget(node, '_effective_values')

        if x ~= nil then
            if pv and pv.x ~= x then pv.x = x; changed = true end
            if ev and ev.x ~= x then ev.x = x; changed = true end
        end

        if y ~= nil then
            if pv and pv.y ~= y then pv.y = y; changed = true end
            if ev and ev.y ~= y then ev.y = y; changed = true end
        end

        if width ~= nil then
            if pv and pv.width ~= width then pv.width = width; changed = true end
            if ev and ev.width ~= width then ev.width = width; changed = true end
        end

        if height ~= nil then
            if pv and pv.height ~= height then pv.height = height; changed = true end
            if ev and ev.height ~= height then ev.height = height; changed = true end
        end

        if visible ~= nil then
            if pv and pv.visible ~= visible then pv.visible = visible; changed = true end
            if ev and ev.visible ~= visible then ev.visible = visible; changed = true end
        end

        if changed then
            mark_node_geometry_dirty(node)
        end
    end

    local function compute_thumb_geometry(track_len, viewport_len, content_len, scroll, max_scroll)
        track_len = max(0, track_len or 0)
        viewport_len = max(0, viewport_len or 0)
        content_len = max(0, content_len or 0)
        max_scroll = max(0, max_scroll or 0)

        if track_len <= 0 then
            return 0, 0
        end

        local min_thumb = min(SCROLLBAR_MIN_THUMB, track_len)
        local base_thumb = max(min_thumb, (viewport_len / max(content_len, 1)) * track_len)
        base_thumb = clamp(base_thumb, min_thumb, track_len)

        -- Keep thumb inside track while reflecting overscroll by compressing
        -- thumb size at the active edge. Use a continuous proportion instead
        -- of a hard linear clamp to avoid early visual plateau during snapback.
        local function overshoot_thumb_length(overshoot)
            local mapped_overshoot = overshoot * (track_len / max(viewport_len, 1))
            local compressed = base_thumb / (1 + (mapped_overshoot / max(base_thumb, 1)))
            local min_overshoot_thumb = min(SCROLLBAR_MIN_OVERSHOOT_THUMB, track_len)
            return clamp(compressed, min_overshoot_thumb, track_len)
        end

        if scroll < 0 then
            local overshoot = -scroll
            local thumb_len = overshoot_thumb_length(overshoot)
            return 0, thumb_len
        end

        if scroll > max_scroll then
            local overshoot = scroll - max_scroll
            local thumb_len = overshoot_thumb_length(overshoot)
            return max(0, track_len - thumb_len), thumb_len
        end

        local thumb_pos = max_scroll > 0 and (scroll / max_scroll) * (track_len - base_thumb) or 0
        thumb_pos = clamp(thumb_pos, 0, max(0, track_len - base_thumb))
        return thumb_pos, base_thumb
    end

    if not get_public(self, 'showScrollbars') then
        local h_track = rawget(self, '_scrollbar_h_track')
        local h_thumb = rawget(self, '_scrollbar_h_thumb')
        local v_track = rawget(self, '_scrollbar_v_track')
        local v_thumb = rawget(self, '_scrollbar_v_thumb')
        set_node_frame(h_track, nil, nil, nil, nil, false)
        set_node_frame(h_thumb, nil, nil, nil, nil, false)
        set_node_frame(v_track, nil, nil, nil, nil, false)
        set_node_frame(v_thumb, nil, nil, nil, nil, false)
        return
    end

    local vw = (rawget(self, '_viewport') or {})._resolved_width  or 0
    local vh = (rawget(self, '_viewport') or {})._resolved_height or 0
    local cw = rawget(self, '_content_width')  or 0
    local ch = rawget(self, '_content_height') or 0
    local sx = rawget(self, '_scroll_x') or 0
    local sy = rawget(self, '_scroll_y') or 0
    local max_sx = rawget(self, '_max_scroll_x') or 0
    local max_sy = rawget(self, '_max_scroll_y') or 0

    local show_v = get_public(self, 'scrollYEnabled') and ch > vh
    local show_h = get_public(self, 'scrollXEnabled') and cw > vw

    local v_track_x = max(0, vw - SCROLLBAR_MARGIN - SCROLLBAR_SIZE)
    local v_track_y = SCROLLBAR_MARGIN
    local h_track_x = SCROLLBAR_MARGIN
    local h_track_y = max(0, vh - SCROLLBAR_MARGIN - SCROLLBAR_SIZE)
    local v_track_h = max(0, vh - SCROLLBAR_MARGIN * 2 - (show_h and (SCROLLBAR_SIZE + SCROLLBAR_MARGIN) or 0))
    local h_track_w = max(0, vw - SCROLLBAR_MARGIN * 2 - (show_v and (SCROLLBAR_SIZE + SCROLLBAR_MARGIN) or 0))

    -- Vertical scrollbar
    local v_track = rawget(self, '_scrollbar_v_track')
    local v_thumb = rawget(self, '_scrollbar_v_thumb')
    if v_track and v_thumb then
        set_node_frame(v_track, v_track_x, v_track_y, SCROLLBAR_SIZE, v_track_h, show_v)
        set_node_frame(v_thumb, 0, nil, SCROLLBAR_SIZE, nil, show_v)
        if show_v then
            local thumb_y, thumb_h = compute_thumb_geometry(v_track_h, vh, ch, sy, max_sy)
            set_node_frame(v_thumb, nil, thumb_y, nil, thumb_h, nil)
        end
    end

    -- Horizontal scrollbar
    local h_track = rawget(self, '_scrollbar_h_track')
    local h_thumb = rawget(self, '_scrollbar_h_thumb')
    if h_track and h_thumb then
        set_node_frame(h_track, h_track_x, h_track_y, h_track_w, SCROLLBAR_SIZE, show_h)
        set_node_frame(h_thumb, nil, 0, nil, SCROLLBAR_SIZE, show_h)
        if show_h then
            local thumb_x, thumb_w = compute_thumb_geometry(h_track_w, vw, cw, sx, max_sx)
            set_node_frame(h_thumb, thumb_x, nil, thumb_w, nil, nil)
        end
    end
end

-- ── Scroll application ─────────────────────────────────────────────────────

local function apply_scroll(self, dx, dy, allow_overscroll)
    -- Disabled axes must never move, even with overscroll
    if not get_public(self, 'scrollXEnabled') then dx = 0 end
    if not get_public(self, 'scrollYEnabled') then dy = 0 end

    local sx = rawget(self, '_scroll_x') or 0
    local sy = rawget(self, '_scroll_y') or 0
    local max_x = rawget(self, '_max_scroll_x') or 0
    local max_y = rawget(self, '_max_scroll_y') or 0

    -- Apply overscroll resistance when beyond bounds
    if allow_overscroll and get_public(self, 'overscroll') then
        if (sx < 0 and dx < 0) or (sx > max_x and dx > 0) then
            dx = dx * OVERSCROLL_RESISTANCE
        end
        if (sy < 0 and dy < 0) or (sy > max_y and dy > 0) then
            dy = dy * OVERSCROLL_RESISTANCE
        end
    end

    local new_sx = sx + dx
    local new_sy = sy + dy

    if not allow_overscroll or not get_public(self, 'overscroll') then
        new_sx = clamp(new_sx, 0, max_x)
        new_sy = clamp(new_sy, 0, max_y)
    end

    local consumed_x = new_sx - sx
    local consumed_y = new_sy - sy

    rawset(self, '_scroll_x', new_sx)
    rawset(self, '_scroll_y', new_sy)
    apply_content_offset(self)
    update_scrollbar_geometry(self)
    self:invalidate_stage_update_token()

    return consumed_x, consumed_y
end

-- ── Remaining scroll range (for nested consumption) ─────────────────────────

local function has_remaining_range(self, dx, dy)
    local sx = rawget(self, '_scroll_x') or 0
    local sy = rawget(self, '_scroll_y') or 0
    local max_x = rawget(self, '_max_scroll_x') or 0
    local max_y = rawget(self, '_max_scroll_y') or 0

    if dx < 0 and sx > 0 then return true end
    if dx > 0 and sx < max_x then return true end
    if dy < 0 and sy > 0 then return true end
    if dy > 0 and sy < max_y then return true end

    return false
end

-- ── Velocity tracking ───────────────────────────────────────────────────────

local function record_velocity(self, dx, dy)
    rawset(self, '_velocity_x', dx)
    rawset(self, '_velocity_y', dy)
end

local function is_effectively_integer(value)
    return abs(value - math.floor(value + 0.5)) <= DELTA_EPSILON
end

-- ── Overscroll snap-back ────────────────────────────────────────────────────

local function resolve_overscroll(self)
    local sx = rawget(self, '_scroll_x') or 0
    local sy = rawget(self, '_scroll_y') or 0
    local max_x = rawget(self, '_max_scroll_x') or 0
    local max_y = rawget(self, '_max_scroll_y') or 0
    local snapping = false

    if sx < 0 then
        sx = sx * (1 - OVERSCROLL_SNAP_SPEED)
        if abs(sx) < 0.5 then
            sx = 0
        else
            snapping = true
        end
    elseif sx > max_x then
        sx = max_x + (sx - max_x) * (1 - OVERSCROLL_SNAP_SPEED)
        if abs(sx - max_x) < 0.5 then
            sx = max_x
        else
            snapping = true
        end
    end

    if sy < 0 then
        sy = sy * (1 - OVERSCROLL_SNAP_SPEED)
        if abs(sy) < 0.5 then
            sy = 0
        else
            snapping = true
        end
    elseif sy > max_y then
        sy = max_y + (sy - max_y) * (1 - OVERSCROLL_SNAP_SPEED)
        if abs(sy - max_y) < 0.5 then
            sy = max_y
        else
            snapping = true
        end
    end

    rawset(self, '_scroll_x', sx)
    rawset(self, '_scroll_y', sy)
    return snapping
end

-- ── __index / __newindex ────────────────────────────────────────────────────

function ScrollableContainer.__index(self, key)
    -- Expose internal role nodes as read-only
    if key == 'content' then
        return rawget(self, '_content')
    end

    if key == 'viewport' then
        return rawget(self, '_viewport')
    end

    local val = Container._walk_hierarchy(getmetatable(self), key)
    if val ~= nil then return val end

    val = Container._walk_hierarchy(ScrollableContainer, key)
    if val ~= nil then return val end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        local public_values = rawget(self, '_public_values')
        return public_values and public_values[key]
    end

    return nil
end

function ScrollableContainer.__newindex(self, key, value)
    if key == 'content' or key == 'viewport' then
        Assert.fail('ScrollableContainer.' .. key .. ' is read-only', 2)
    end

    local allowed_public_keys = rawget(self, '_allowed_public_keys')
    if allowed_public_keys and allowed_public_keys[key] then
        Container._set_public_value(self, key, value, 2)

        local rule = allowed_public_keys[key]
        if Types.is_table(rule) and Types.is_function(rule.set) then
            rule.set(self, value)
        end
        return
    end

    rawset(self, key, value)
end

-- ── Constructor ─────────────────────────────────────────────────────────────

function ScrollableContainer:constructor(opts)
    self:_initialize(opts, ScrollableContainer._schema)

    rawset(self, '_ui_scrollable_instance', true)

    -- Scroll state
    rawset(self, '_scroll_x', 0)
    rawset(self, '_scroll_y', 0)
    rawset(self, '_velocity_x', 0)
    rawset(self, '_velocity_y', 0)
    rawset(self, '_scroll_state', STATE_IDLE)
    rawset(self, '_max_scroll_x', 0)
    rawset(self, '_max_scroll_y', 0)
    rawset(self, '_content_width', 0)
    rawset(self, '_content_height', 0)

    -- Drag tracking
    rawset(self, '_drag_start_x', 0)
    rawset(self, '_drag_start_y', 0)
    rawset(self, '_drag_scroll_start_x', 0)
    rawset(self, '_drag_scroll_start_y', 0)
    rawset(self, '_prev_drag_delta_x', 0)
    rawset(self, '_prev_drag_delta_y', 0)

    -- ── Build anatomy ───────────────────────────────────────────────────

    -- Viewport: clips children
    local viewport = Container({
        tag = 'scroll_viewport',
        width = 0,
        height = 0,
        clipChildren = true,
        interactive = true,
    })
    Container._allow_fill_from_parent(viewport, { width = true, height = true })

    -- Content: user-facing child container
    local content = Container({
        tag = 'scroll_content',
        width = 'fill',
        height = 'fill',
    })
    Container._allow_fill_from_parent(content, { width = true, height = true })
    Container._allow_child_fill(content, { width = true, height = true })

    Container.addChild(viewport, content)
    Container.addChild(self, viewport)

    rawset(self, '_viewport', viewport)
    rawset(self, '_content', content)

    -- ── Scrollbar parts (optional) ──────────────────────────────────────

    -- Vertical scrollbar track + thumb
    local v_track = Drawable({
        tag = 'scrollbar_v_track',
        width = SCROLLBAR_SIZE,
        height = 'fill',
        interactive = false,
        focusable = false,
        visible = false,
    })
    Container._allow_fill_from_parent(v_track, { height = true })
    local v_thumb = Drawable({
        tag = 'scrollbar_v_thumb',
        width = SCROLLBAR_SIZE,
        height = SCROLLBAR_MIN_THUMB,
        interactive = false,
        focusable = false,
    })
    Container.addChild(v_track, v_thumb)
    Container.addChild(self, v_track)
    rawset(self, '_scrollbar_v_track', v_track)
    rawset(self, '_scrollbar_v_thumb', v_thumb)

    -- Horizontal scrollbar track + thumb
    local h_track = Drawable({
        tag = 'scrollbar_h_track',
        height = SCROLLBAR_SIZE,
        width = 'fill',
        interactive = false,
        focusable = false,
        visible = false,
    })
    Container._allow_fill_from_parent(h_track, { width = true })
    local h_thumb = Drawable({
        tag = 'scrollbar_h_thumb',
        height = SCROLLBAR_SIZE,
        width = SCROLLBAR_MIN_THUMB,
        interactive = false,
        focusable = false,
    })
    Container.addChild(h_track, h_thumb)
    Container.addChild(self, h_track)
    rawset(self, '_scrollbar_h_track', h_track)
    rawset(self, '_scrollbar_h_thumb', h_thumb)

    -- ── Wire events ─────────────────────────────────────────────────────
    self:_wire_scroll_events()
end

function ScrollableContainer.new(opts)
    return ScrollableContainer(opts)
end

-- ── Event wiring ────────────────────────────────────────────────────────────

function ScrollableContainer:_wire_scroll_events()
    local self_ref = self

    -- Wheel / keyboard scroll
    self:_add_event_listener('ui.scroll', function(event)
        if rawget(self_ref, '_destroyed') then return end

        local dx = event.deltaX or 0
        local dy = event.deltaY or 0
        local step = get_public(self_ref, 'scrollStep') or 40
        local is_wheel_event = event.x ~= nil and event.y ~= nil

        -- Check if we can consume this input
        if not has_remaining_range(self_ref, dx, dy) then
            return  -- let it bubble to parent scroll container
        end

        local consumed_x, consumed_y = apply_scroll(self_ref, dx, dy, false)

        -- Preserve native high-resolution wheel streams (for example macOS
        -- trackpad inertia) without adding a second inertial model. For coarse
        -- wheel deltas, synthesize momentum when enabled.
        if get_public(self_ref, 'momentum') and is_wheel_event then
            local abs_dx = abs(dx)
            local abs_dy = abs(dy)
            local dominant = max(abs_dx, abs_dy)
            local high_resolution_wheel =
                not is_effectively_integer(dx) or
                not is_effectively_integer(dy) or
                (dominant > 0 and dominant < (step - DELTA_EPSILON))

            if not high_resolution_wheel then
                record_velocity(self_ref, consumed_x, consumed_y)
                if abs(consumed_x) > 0 or abs(consumed_y) > 0 then
                    rawset(self_ref, '_scroll_state', STATE_INERTIAL)
                    self_ref:invalidate_stage_update_token()
                end
            end
        end

        event:stopPropagation()
    end)

    -- Drag start
    self:_add_event_listener('ui.drag', function(event)
        if rawget(self_ref, '_destroyed') then return end

        if event.dragPhase == 'start' then
            rawset(self_ref, '_scroll_state', STATE_DRAGGING)
            rawset(self_ref, '_drag_start_x', event.x or 0)
            rawset(self_ref, '_drag_start_y', event.y or 0)
            rawset(self_ref, '_drag_scroll_start_x', rawget(self_ref, '_scroll_x') or 0)
            rawset(self_ref, '_drag_scroll_start_y', rawget(self_ref, '_scroll_y') or 0)
            -- Drag deltas are cumulative from gesture origin; seed previous
            -- deltas on start so first move uses only incremental motion.
            rawset(self_ref, '_prev_drag_delta_x', event.deltaX or 0)
            rawset(self_ref, '_prev_drag_delta_y', event.deltaY or 0)
            record_velocity(self_ref, 0, 0)
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'move' then
            if rawget(self_ref, '_scroll_state') ~= STATE_DRAGGING then return end

            local prev_dx = rawget(self_ref, '_prev_drag_delta_x') or 0
            local prev_dy = rawget(self_ref, '_prev_drag_delta_y') or 0
            local cur_dx = event.deltaX or 0
            local cur_dy = event.deltaY or 0
            local dx = -(cur_dx - prev_dx)
            local dy = -(cur_dy - prev_dy)
            rawset(self_ref, '_prev_drag_delta_x', cur_dx)
            rawset(self_ref, '_prev_drag_delta_y', cur_dy)

            local can_overscroll = get_public(self_ref, 'overscroll')
            local consumed_x, consumed_y = apply_scroll(self_ref, dx, dy, can_overscroll)
            record_velocity(self_ref, consumed_x, consumed_y)
            event:stopPropagation()
            return
        end

        if event.dragPhase == 'end' then
            if rawget(self_ref, '_scroll_state') ~= STATE_DRAGGING then return end

            if get_public(self_ref, 'momentum') then
                rawset(self_ref, '_scroll_state', STATE_INERTIAL)
            else
                -- Clamp and return to idle
                clamp_offsets(self_ref, false)
                apply_content_offset(self_ref)
                update_scrollbar_geometry(self_ref)
                rawset(self_ref, '_scroll_state', STATE_IDLE)
                rawset(self_ref, '_velocity_x', 0)
                rawset(self_ref, '_velocity_y', 0)
            end
            event:stopPropagation()
            return
        end
    end)
end

-- ── Inertial frame update ───────────────────────────────────────────────────

function ScrollableContainer:_update_inertial()
    if rawget(self, '_scroll_state') ~= STATE_INERTIAL then return end

    local vx = rawget(self, '_velocity_x') or 0
    local vy = rawget(self, '_velocity_y') or 0
    local decay = get_public(self, 'momentumDecay') or 0.95

    -- Apply velocity
    apply_scroll(self, vx, vy, get_public(self, 'overscroll'))

    -- Decay
    vx = vx * decay
    vy = vy * decay

    -- Resolve overscroll snap-back
    local snapping = resolve_overscroll(self)
    if snapping then
        apply_content_offset(self)
        update_scrollbar_geometry(self)
    end

    -- Stop threshold
    if abs(vx) < VELOCITY_STOP_THRESHOLD and abs(vy) < VELOCITY_STOP_THRESHOLD and not snapping then
        rawset(self, '_velocity_x', 0)
        rawset(self, '_velocity_y', 0)
        clamp_offsets(self, false)
        apply_content_offset(self)
        update_scrollbar_geometry(self)
        rawset(self, '_scroll_state', STATE_IDLE)
    else
        rawset(self, '_velocity_x', vx)
        rawset(self, '_velocity_y', vy)
    end
end

-- ── Viewport sizing ─────────────────────────────────────────────────────────
-- Since ScrollableContainer is not a LayoutNode, 'fill' can't resolve on the
-- viewport. We sync the viewport's dimensions to match our own resolved size
-- before each update so that layout children get proper constraints.

local function sync_viewport_size(self)
    local viewport_node = rawget(self, '_viewport')
    if not viewport_node then return end

    local w = self._resolved_width  or 0
    local h = self._resolved_height or 0

    local vpv = rawget(viewport_node, '_public_values')
    local vev = rawget(viewport_node, '_effective_values')
    local changed = false

    if vpv then
        if vpv.width ~= w then
            vpv.width = w
            changed = true
        end
        if vpv.height ~= h then
            vpv.height = h
            changed = true
        end
    end

    if vev then
        if vev.width ~= w then
            vev.width = w
            changed = true
        end
        if vev.height ~= h then
            vev.height = h
            changed = true
        end
    end

    if rawget(viewport_node, '_measurement_context_width') ~= w then
        rawset(viewport_node, '_measurement_context_width', w)
        changed = true
    end

    if rawget(viewport_node, '_measurement_context_height') ~= h then
        rawset(viewport_node, '_measurement_context_height', h)
        changed = true
    end

    if not changed then
        return
    end

    rawset(viewport_node, '_measurement_dirty', true)
    rawset(viewport_node, '_local_transform_dirty', true)
    rawset(viewport_node, '_bounds_dirty', true)
    viewport_node:invalidate_world()
    viewport_node:invalidate_descendant_geometry()

    local function mark_layout_subtree_dirty(node)
        local children = rawget(node, '_children') or {}
        for i = 1, #children do
            local child = children[i]
            child:mark_layout_node_dirty()
            mark_layout_subtree_dirty(child)
        end
    end

    mark_layout_subtree_dirty(viewport_node)
end

function ScrollableContainer:_prepare_for_layout_pass()
    Container._prepare_for_layout_pass(self)
    -- Ensure viewport constraints are current before the stage layout traversal
    -- prepares/runs descendants.
    sync_viewport_size(self)
    return self
end

-- ── Update override ─────────────────────────────────────────────────────────

function ScrollableContainer:update(dt)
    -- Sync viewport dimensions before layout
    sync_viewport_size(self)

    Container.update(self, dt)

    -- Recompute content extent and clamp after layout
    clamp_offsets(self, rawget(self, '_scroll_state') ~= STATE_IDLE)
    apply_content_offset(self)
    update_scrollbar_geometry(self)

    -- Process inertial state
    self:_update_inertial()

    return self
end

-- ── Programmatic scrolling ──────────────────────────────────────────────────

function ScrollableContainer:_scroll_to(x, y)
    Assert.number('x', x, 2)
    Assert.number('y', y, 2)

    rawset(self, '_scroll_x', x)
    rawset(self, '_scroll_y', y)
    clamp_offsets(self, false)
    apply_content_offset(self)
    update_scrollbar_geometry(self)
    rawset(self, '_scroll_state', STATE_IDLE)
    rawset(self, '_velocity_x', 0)
    rawset(self, '_velocity_y', 0)
    self:invalidate_stage_update_token()
    return self
end

function ScrollableContainer:_scroll_by(dx, dy)
    Assert.number('dx', dx, 2)
    Assert.number('dy', dy, 2)

    apply_scroll(self, dx, dy, false)
    return self
end

-- ── Query ───────────────────────────────────────────────────────────────────

function ScrollableContainer:_get_scroll_offset()
    return rawget(self, '_scroll_x') or 0, rawget(self, '_scroll_y') or 0
end

function ScrollableContainer:_get_scroll_state()
    return rawget(self, '_scroll_state') or STATE_IDLE
end

function ScrollableContainer:_cancel_momentum()
    if rawget(self, '_scroll_state') ~= STATE_INERTIAL then
        return self
    end

    rawset(self, '_velocity_x', 0)
    rawset(self, '_velocity_y', 0)
    rawset(self, '_scroll_state', STATE_IDLE)
    clamp_offsets(self, false)
    apply_content_offset(self)
    update_scrollbar_geometry(self)
    self:invalidate_stage_update_token()

    return self
end

function ScrollableContainer:_get_content_extent()
    return rawget(self, '_content_width') or 0, rawget(self, '_content_height') or 0
end

function ScrollableContainer:_get_scroll_range()
    return rawget(self, '_max_scroll_x') or 0, rawget(self, '_max_scroll_y') or 0
end

-- ── TextArea integration boundary ───────────────────────────────────────────
-- Internal factory for text-area reuse without new public API surface.

function ScrollableContainer._create_scroll_region(config)
    config = config or {}
    return ScrollableContainer({
        scrollXEnabled = config.scroll_x or false,
        scrollYEnabled = config.scroll_y ~= false,
        momentum       = config.momentum or false,
        overscroll     = false,
        showScrollbars = config.show_scrollbars ~= false,
        width          = config.width or 'fill',
        height         = config.height or 'fill',
    })
end

-- ── addChild override ───────────────────────────────────────────────────────
-- Block direct child insertion — content goes through self.content

function ScrollableContainer:addChild()
    Assert.fail(
        'ScrollableContainer does not support direct child insertion; ' ..
        'add children to scrollable.content instead',
        2
    )
end

function ScrollableContainer:removeChild()
    Assert.fail(
        'ScrollableContainer does not support direct child removal; ' ..
        'remove children from scrollable.content instead',
        2
    )
end

function ScrollableContainer:removeAllChildren()
    Assert.fail(
        'ScrollableContainer does not support direct child removal; ' ..
        'remove children from scrollable.content instead',
        2
    )
end

return ScrollableContainer
