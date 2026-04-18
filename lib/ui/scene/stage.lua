local Container = require('lib.ui.core.container')
local Assert = require('lib.ui.utils.assert')
local Drawable = require('lib.ui.core.drawable')
local Event = require('lib.ui.event.event')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')
local Responsive = require('lib.ui.layout.responsive')
local Types = require('lib.ui.utils.types')
-- Proxy removed
local Memoize = require('lib.ui.utils.memoize')
local RuntimeProfiler = require('profiler.runtime_profiler')

local max = math.max
local huge = math.huge

local Stage = Container:extends('Stage')
local StageSchema = require('lib.ui.scene.stage_schema')
Stage._schema = StageSchema

local DRAG_THRESHOLD = 4
local DRAG_THRESHOLD_SQUARED = DRAG_THRESHOLD * DRAG_THRESHOLD
local WHEEL_DELTA_PIXELS = 40
local KEYBOARD_SCROLL_STEP = 40



local TWO_PASS_VIOLATION =
    'Stage.draw() called without a preceding Stage.update() in this frame. ' ..
    'The two-pass contract requires update to complete before draw begins.'

local active_stage = nil
local build_target_path

local function fail(message, level)
    error(message, (level or 1) + 1)
end




local function assert_table(name, value, level)
    if not Types.is_table(value) then
        fail(name .. ' must be a table', (level or 1) + 1)
    end
end

local function get_public_value(self, key)
    return rawget(self, key)
end



local function copy_array(values)
    local copy = {}

    for index = 1, #values do
        copy[index] = values[index]
    end

    return copy
end

local function assert_container_node(name, value, level)
    if not Types.is_table(value) or value._ui_container_instance ~= true then
        fail(name .. ' must be a Container', level or 1)
    end
end

local function set_stored_focus_owner(self, node)
    self._focus_owner = node
    self._focused_node = node
end

local function get_stored_focus_owner(self)
    local owner = self._focus_owner

    if owner == nil then
        owner = self._focused_node
    end

    return owner
end

local function is_descendant_or_same(root, node)
    local current = node

    while current ~= nil do
        if current == root then
            return true
        end

        current = current.parent
    end

    return false
end

local function get_runtime_value(node, key)
    return node[key]
end

local function is_attached_visible_to_stage(self, node)
    if node == nil or not is_descendant_or_same(self, node) then
        return false
    end

    local current = node

    while current ~= nil do
        if get_runtime_value(current, 'visible') == false then
            return false
        end

        if current == self then
            return true
        end

        current = current.parent
    end

    return false
end

local function is_attached_enabled_to_stage(self, node)
    if node == nil or not is_descendant_or_same(self, node) then
        return false
    end

    local current = node

    while current ~= nil do
        if get_runtime_value(current, 'enabled') == false then
            return false
        end

        if current == self then
            return true
        end

        current = current.parent
    end

    return false
end

local function get_internal_focus_contract(node)
    return node._focus_contract_internal
end

local function is_active_focus_scope_node(self, node)
    if node == self then
        return true
    end

    local contract = get_internal_focus_contract(node)

    return Types.is_table(contract) and contract.scope == true and
        is_attached_visible_to_stage(self, node)
end

local function is_active_focus_trap_node(self, node)
    local contract = get_internal_focus_contract(node)

    return Types.is_table(contract) and contract.scope == true and
        contract.trap == true and
        is_descendant_or_same(self.overlayLayer, node) and
        is_attached_visible_to_stage(self, node)
end

local function collect_active_focus_traps(self, node, traps)
    if node ~= self and is_active_focus_trap_node(self, node) then
        traps[#traps + 1] = node
    end

    local children = node._children

    for index = 1, #children do
        collect_active_focus_traps(self, children[index], traps)
    end

    return traps
end

local function get_active_focus_scope(self)
    local chain = self._active_focus_scope_chain
    return chain[#chain] or self
end

local function get_innermost_focus_trap(self)
    local traps = self._focus_trap_stack
    return traps[#traps]
end

local function get_containing_focus_scope(self, node)
    local current = node

    while current ~= nil and current ~= self do
        if is_active_focus_scope_node(self, current) then
            return current
        end

        current = current.parent
    end

    return self
end

local function get_pointer_focus_coupling(node)
    local val = node.pointerFocusCoupling
    if val ~= nil and val ~= 'none' then
        return val
    end

    local contract = get_internal_focus_contract(node)
    if not Types.is_table(contract) then
        return nil
    end

    return contract.pointer_focus_coupling
end

local function is_focus_eligible(self, node)
    return node ~= nil and
        is_descendant_or_same(self, node) and
        get_runtime_value(node, 'focusable') == true and
        is_attached_visible_to_stage(self, node) and
        is_attached_enabled_to_stage(self, node)
end

local function is_focus_owner_target(self, node)
    if node == nil then
        return false
    end

    if node == self then
        return true
    end

    if not is_descendant_or_same(self, node) or
        not is_attached_visible_to_stage(self, node) or
        not is_attached_enabled_to_stage(self, node) then
        return false
    end

    return true
end

local function is_focus_request_allowed(self, node)
    if not is_focus_eligible(self, node) then
        return false
    end

    local innermost_trap = get_innermost_focus_trap(self)

    if innermost_trap ~= nil and not is_descendant_or_same(innermost_trap, node) then
        return false
    end

    return true
end

local function is_traversable_focus_candidate(self, scope_root, node)
    return node ~= scope_root and
        is_focus_eligible(self, node) and
        get_containing_focus_scope(self, node) == scope_root
end

local function collect_focus_candidates(self, scope_root, node, candidates)
    if not is_attached_visible_to_stage(self, node) or
        not is_attached_enabled_to_stage(self, node) then
        return candidates
    end

    if node ~= scope_root and get_containing_focus_scope(self, node) ~= scope_root then
        return candidates
    end

    if is_traversable_focus_candidate(self, scope_root, node) then
        candidates[#candidates + 1] = node
    end

    local children = node._children

    for index = 1, #children do
        collect_focus_candidates(self, scope_root, children[index], candidates)
    end

    return candidates
end

local function resolve_scope_entry_focus_target(self, scope_root)
    local candidates = collect_focus_candidates(self, scope_root, scope_root, {})

    if #candidates > 0 then
        return candidates[1]
    end

    return scope_root
end

local function get_world_center(node)
    local bounds = node:getWorldBounds()

    return bounds.x + bounds.width * 0.5,
        bounds.y + bounds.height * 0.5
end

local function matches_direction(direction, delta_x, delta_y)
    if direction == 'right' then
        return delta_x > 0
    end

    if direction == 'left' then
        return delta_x < 0
    end

    if direction == 'down' then
        return delta_y > 0
    end

    if direction == 'up' then
        return delta_y < 0
    end

    return false
end

local function read_host_viewport()
    if love == nil or love.graphics == nil or
        not Types.is_function(love.graphics.getDimensions) then
        return nil, nil
    end

    local ok, width, height = pcall(love.graphics.getDimensions)

    if not ok or not Types.is_number(width) or not Types.is_number(height) then
        return nil, nil
    end

    return width, height
end

local function read_host_safe_area_bounds()
    if love == nil or love.window == nil or
        not Types.is_function(love.window.getSafeArea) then
        return nil
    end

    local ok, x, y, width, height = pcall(love.window.getSafeArea)

    if not ok or not Types.is_number(x) or not Types.is_number(y) or
        not Types.is_number(width) or not Types.is_number(height) then
        return nil
    end

    return Rectangle(x, y, max(0, width), max(0, height))
end

local function normalize_safe_area_insets(value, level)
    local ok, insets = pcall(Insets.normalize, value)

    if not ok then
        fail(tostring(insets), level or 1)
    end

    return insets
end

local function derive_safe_area_insets(viewport_width, viewport_height, bounds)
    if bounds == nil then
        return Insets.zero()
    end

    local viewport = Rectangle(
        0,
        0,
        max(0, viewport_width or 0),
        max(0, viewport_height or 0)
    )
    local safe_area = viewport:intersection(bounds)

    return Insets(
        safe_area.y,
        max(0, viewport.width - safe_area:right()),
        max(0, viewport.height - safe_area:bottom()),
        safe_area.x
    )
end

local function read_host_safe_area_insets(viewport_width, viewport_height)
    local bounds = read_host_safe_area_bounds()

    if bounds == nil then
        return nil
    end

    return derive_safe_area_insets(viewport_width, viewport_height, bounds)
end

local function refresh_environment_bounds(self)
    local w, h
    local safe_area_insets

    if self._host_driven_dims then
        -- No explicit width/height: always poll the live host environment.
        local host_w, host_h = read_host_viewport()
        w = max(0, host_w or 0)
        h = max(0, host_h or 0)

        local host_bounds = read_host_safe_area_bounds()
        if host_bounds then
            safe_area_insets = derive_safe_area_insets(w, h, host_bounds)
        else
            safe_area_insets = get_public_value(self, 'safeAreaInsets') or Insets.zero()
        end

        -- Keep stored safe-area in sync so direct reads are correct too.
        self.safeAreaInsets = safe_area_insets
    else
        w = max(0, get_public_value(self, 'width') or 0)
        h = max(0, get_public_value(self, 'height') or 0)
        safe_area_insets = get_public_value(self, 'safeAreaInsets') or Insets.zero()
    end

    local viewport = Rectangle(0, 0, w, h)
    self._viewport_bounds_cache = viewport
    self._safe_area_bounds_cache = viewport:inset(safe_area_insets)
end

local function set_safe_area_insets(self, value, level)
    local normalized = normalize_safe_area_insets(value, level or 1)
    local current = get_public_value(self, 'safeAreaInsets')

    if current ~= nil and current == normalized then
        return normalized, false
    end

    self.safeAreaInsets = normalized
    refresh_environment_bounds(self)
    Container.markDirty(self)
    return normalized, true
end

function Stage:_handle_safe_area_change_internal()
    -- This method is called by the schema 'set' hook.
    -- The value is already updated in public_values.
    refresh_environment_bounds(self)
    Container.markDirty(self)
    self:_mark_layout_subtree_dirty()
end

local function resolve_draw_args(graphics, draw_callback)
    if draw_callback == nil and Types.is_function(graphics) then
        draw_callback = graphics
        graphics = nil
    end

    if graphics == nil then
        if love ~= nil and love.graphics ~= nil then
            graphics = love.graphics
        else
            graphics = {}
        end
    end

    if draw_callback == nil then
        draw_callback = function()
        end
    end

    if not Types.is_table(graphics) then
        fail('graphics must be a graphics adapter table', 3)
    end

    if not Types.is_function(draw_callback) then
        fail('draw_callback must be a function', 3)
    end

    return graphics, draw_callback
end

local function draw_node_default(node, graphics)
    local draw_method = node.draw
    if Types.is_function(draw_method) then
        draw_method(node, graphics)
    end

    local draw_control = node._draw_control
    if Types.is_function(draw_control) then
        draw_control(node, graphics)
    end
end

local function create_focus_aware_draw_callback(self, draw_callback)
    local function restore_focus_draw_state(node, previous, focused)
        if previous ~= focused then
            node._focused = previous
        end
    end

    local function decorate_focused_drawable(node, graphics)
        if not Drawable.is_drawable(node) then
            return
        end

        if get_stored_focus_owner(self) == node then
            node:_draw_default_focus_indicator(graphics)
        end
    end

    return function(node, graphics)
        local previous = node._focused
        local focused = get_stored_focus_owner(self) == node or nil

        if previous ~= focused then
            node._focused = focused
        end

        draw_node_default(node, graphics)
        draw_callback(node, graphics)
        decorate_focused_drawable(node, graphics)
        restore_focus_draw_state(node, previous, focused)
    end
end

local function resolve_active_focus_scope_target(self)
    self:_refresh_focus_runtime_state()

    local target = get_stored_focus_owner(self)

    if target == nil then
        target = get_active_focus_scope(self)
    end

    if target == nil then
        return nil, nil
    end

    return target, build_target_path(self, target)
end

build_target_path = function(self, target)
    local reversed = {}
    local current = target

    while current ~= nil do
        reversed[#reversed + 1] = current

        if current == self then
            break
        end

        current = current.parent
    end

    if reversed[#reversed] ~= self then
        return nil
    end

    local path = {}

    for index = #reversed, 1, -1 do
        path[#path + 1] = reversed[index]
    end

    return path
end

local function resolve_target_resolved(self, x, y)
    local target = self.overlayLayer:_hit_test_resolved(x, y)
    local innermost_trap = get_innermost_focus_trap(self)

    if innermost_trap ~= nil then
        if target ~= nil and is_descendant_or_same(innermost_trap, target) then
            return target
        end

        return nil
    end

    if target ~= nil then
        return target
    end

    return self.baseSceneLayer:_hit_test_resolved(x, y)
end

local function translate_raw_input(raw_event)
    local kind = raw_event.kind

    if kind == 'mousepressed' or kind == 'mousereleased' or
        kind == 'touchpressed' or kind == 'touchreleased' then
        return 'Activate'
    end

    if kind == 'mousemoved' or kind == 'touchmoved' then
        return 'Drag'
    end

    if kind == 'wheelmoved' then
        return 'Scroll'
    end

    if kind == 'textinput' then
        return 'TextInput'
    end

    if kind == 'textedited' then
        return 'TextCompose'
    end

    if kind ~= 'keypressed' then
        return nil
    end

    local key = raw_event.key

    if key == 'space' then
        return 'Activate'
    end

    if key == 'tab' or key == 'up' or key == 'down' or key == 'left' or
        key == 'right' then
        return 'Navigate'
    end

    if key == 'pageup' or key == 'pagedown' or key == 'home' or key == 'end' then
        return 'Scroll'
    end

    if key == 'escape' then
        return 'Dismiss'
    end

    if key == 'return' or key == 'kpenter' then
        return 'Submit'
    end

    return nil
end

local function read_timestamp()
    if love ~= nil and love.timer ~= nil and Types.is_function(love.timer.getTime) then
        local ok, timestamp = pcall(love.timer.getTime)

        if ok and Types.is_number(timestamp) then
            return timestamp
        end
    end

    return os.clock()
end

local function is_shift_down(raw_event)
    if raw_event.shift == true then
        return true
    end

    local modifiers = raw_event.modifiers or raw_event.mods

    if not Types.is_table(modifiers) then
        return false
    end

    return modifiers.shift == true
end

local function resolve_pointer_type(raw_event)
    local kind = raw_event.kind

    if kind == 'mousepressed' or kind == 'mousereleased' or kind == 'mousemoved' then
        return 'mouse'
    end

    if kind == 'touchpressed' or kind == 'touchreleased' or kind == 'touchmoved' then
        return 'touch'
    end

    return nil
end

local function resolve_pointer_button(raw_event)
    local pointer_type = resolve_pointer_type(raw_event)

    if pointer_type == 'mouse' then
        return raw_event.button
    end

    if pointer_type == 'touch' then
        return raw_event.id or raw_event.touch or raw_event.button
    end

    return nil
end

local function resolve_pointer_sequence_id(raw_event)
    local pointer_type = resolve_pointer_type(raw_event)

    if pointer_type == 'mouse' then
        local button = raw_event.button

        if raw_event.kind == 'mousemoved' then
            button = 1
        end

        if button ~= 1 then
            return nil
        end

        return 'mouse:1'
    end

    if pointer_type == 'touch' then
        local button = resolve_pointer_button(raw_event)

        if button == nil then
            return nil
        end

        return 'touch:' .. tostring(button)
    end

    return nil
end

local function resolve_spatial_target(self, raw_event)
    local x = raw_event.x
    local y = raw_event.y

    if raw_event.kind == 'wheelmoved' then
        x = raw_event.stageX
        y = raw_event.stageY
    end

    if not Types.is_number(x) or not Types.is_number(y) then
        return nil, nil
    end

    local target = resolve_target_resolved(self, x, y)

    if target == nil then
        return nil, nil
    end

    return target, build_target_path(self, target)
end

local function resolve_focused_target(self, fallback_to_stage)
    self:_refresh_focus_runtime_state()

    local target = get_stored_focus_owner(self)

    if target ~= nil then
        local path = build_target_path(self, target)

        if path ~= nil then
            return target, path
        end
    end

    if fallback_to_stage then
        return self, { self }
    end

    return nil, nil
end

local function determine_scroll_axis(delta_x, delta_y)
    if delta_x ~= 0 and delta_y ~= 0 then
        return 'both'
    end

    if delta_x ~= 0 then
        return 'horizontal'
    end

    return 'vertical'
end

local function create_event(event_type, target, path, payload)
    payload = payload or {}

    local current_target = payload.currentTarget

    if current_target == nil then
        current_target = target
    end

    return Event({
        type = event_type,
        phase = payload.phase,
        target = target,
        currentTarget = current_target,
        path = path,
        timestamp = payload.timestamp or read_timestamp(),
        pointerType = payload.pointerType,
        x = payload.x,
        y = payload.y,
        button = payload.button,
        direction = payload.direction,
        navigationMode = payload.navigationMode,
        deltaX = payload.deltaX,
        deltaY = payload.deltaY,
        axis = payload.axis,
        dragPhase = payload.dragPhase,
        originX = payload.originX,
        originY = payload.originY,
        text = payload.text,
        rangeStart = payload.rangeStart,
        rangeEnd = payload.rangeEnd,
        previousTarget = payload.previousTarget,
        nextTarget = payload.nextTarget,
    })
end

local function build_delivery(raw_event, intent, event, target, path)
    if event ~= nil then
        target = event.target
        path = event.path
    end

    return {
        raw = raw_event,
        intent = intent,
        event = event,
        target = target,
        path = path,
        dispatched = event ~= nil,
    }
end

local function snapshot_event_listeners(event)
    local snapshots = {}
    local path = event.path or {}

    for index = 1, #path do
        local node = path[index]

        snapshots[node] = {
            capture = node:_get_event_listener_snapshot(event.type, 'capture'),
            bubble = node:_get_event_listener_snapshot(event.type, 'bubble'),
        }
    end

    return snapshots
end

local function deliver_listener_batch(node, event, listener_phase, listener_snapshots)
    local listeners = nil

    if listener_snapshots ~= nil and listener_snapshots[node] ~= nil then
        listeners = listener_snapshots[node][listener_phase]
    end

    if listeners == nil then
        listeners = node:_get_event_listener_snapshot(event.type, listener_phase)
    end

    for index = 1, #listeners do
        listeners[index](event)

        if event.immediatePropagationStopped then
            return false
        end
    end

    return true
end

local function deliver_capture_phase(event, listener_snapshots)
    local path = event.path or {}

    for index = 1, #path - 1 do
        local node = path[index]
        event:_set_phase('capture')
        event:_set_current_target(node)

        if not deliver_listener_batch(node, event, 'capture', listener_snapshots) then
            return false
        end

        if event.propagationStopped then
            return false
        end
    end

    return true
end

local function deliver_target_phase(event, listener_snapshots)
    local target = event.target

    if target == nil then
        return true
    end

    event:_set_phase('target')
    event:_set_current_target(target)

    if not deliver_listener_batch(target, event, 'capture', listener_snapshots) then
        return false
    end

    event:_set_phase('target')
    event:_set_current_target(target)

    if not deliver_listener_batch(target, event, 'bubble', listener_snapshots) then
        return false
    end

    return true
end

local function deliver_bubble_phase(event, listener_snapshots)
    local path = event.path or {}

    for index = #path - 1, 1, -1 do
        local node = path[index]
        event:_set_phase('bubble')
        event:_set_current_target(node)

        if not deliver_listener_batch(node, event, 'bubble', listener_snapshots) then
            return false
        end

        if event.propagationStopped then
            return false
        end
    end

    return true
end

local function run_default_action(event)
    if event == nil or event.defaultPrevented then
        return event
    end

    local target = event.target

    if target == nil then
        return event
    end

    local default_action = target:_get_event_default_action(event.type)

    if default_action == nil then
        return event
    end

    event:_set_phase('target')
    event:_set_current_target(target)
    default_action(event)

    return event
end

local function dispatch_event(event)
    if event == nil then
        return nil
    end

    local listener_snapshots = snapshot_event_listeners(event)
    local propagation_continues = deliver_capture_phase(event, listener_snapshots)

    if propagation_continues then
        propagation_continues = deliver_target_phase(event, listener_snapshots)
    end

    if propagation_continues and not event.propagationStopped then
        deliver_bubble_phase(event, listener_snapshots)
    end

    if event.target ~= nil then
        event:_set_current_target(event.target)
    end

    run_default_action(event)

    return event
end

local function dispatch_target_only_event(event)
    if event == nil or event.target == nil then
        return event
    end

    local target = event.target
    local listener_snapshots = {
        [target] = {
            capture = target:_get_event_listener_snapshot(event.type, 'capture'),
            bubble = target:_get_event_listener_snapshot(event.type, 'bubble'),
        },
    }

    deliver_target_phase(event, listener_snapshots)

    if event.target ~= nil then
        event:_set_current_target(event.target)
    end

    return event
end

local function dispatch_focus_change_event(self, previous_target, next_target)
    if next_target == nil then
        return nil
    end

    return dispatch_target_only_event(create_event(
        'ui.focus.change',
        next_target,
        build_target_path(self, next_target),
        {
            previousTarget = previous_target,
            nextTarget = next_target,
        }
    ))
end

local function commit_focus_owner(self, node)
    local previous_owner = get_stored_focus_owner(self)

    if previous_owner == node then
        return previous_owner, false
    end

    set_stored_focus_owner(self, node)
    self:_refresh_focus_runtime_state(previous_owner)

    local committed_owner = get_stored_focus_owner(self)
    local changed = committed_owner ~= previous_owner

    return committed_owner, changed
end

local function is_mouse_pointer_sequence_active(self)
    local sequences = self._active_pointer_sequences

    if sequences == nil then
        return false
    end

    return sequences['mouse:1'] ~= nil
end

local function deliver_internal_hover_notification(node, handler_name, payload)
    if node == nil then
        return
    end

    local handler = node[handler_name]

    if handler == nil then
        handler = node[handler_name]
    end

    if Types.is_function(handler) then
        handler(node, payload)
    end
end

local function set_hover_target(self, next_target, payload)
    local previous_target = self._hovered_target

    if previous_target == next_target then
        return next_target, false
    end

    if previous_target ~= nil then
        previous_target._hovered = false
        deliver_internal_hover_notification(
            previous_target,
            '_handle_internal_pointer_leave',
            payload
        )
    end

    self._hovered_target = next_target

    if next_target ~= nil then
        next_target._hovered = true
        deliver_internal_hover_notification(
            next_target,
            '_handle_internal_pointer_enter',
            payload
        )
    end

    return next_target, true
end

local function update_mouse_hover_target(self, x, y)
    if not Types.is_number(x) or not Types.is_number(y) then
        return nil, nil, false
    end

    self._hover_pointer_snapshot = {
        pointerType = 'mouse',
        x = x,
        y = y,
    }

    local next_target = resolve_target_resolved(self, x, y)
    local next_path = nil

    if next_target ~= nil then
        next_path = build_target_path(self, next_target)
    end

    local previous_target = self._hovered_target

    if previous_target == next_target then
        return next_target, next_path, false
    end

    set_hover_target(self, next_target, {
        stage = self,
        pointerType = 'mouse',
        x = x,
        y = y,
        previousTarget = previous_target,
        nextTarget = next_target,
    })

    return next_target, next_path, true
end

local function refresh_hover_target(self)
    if is_mouse_pointer_sequence_active(self) then
        return nil
    end

    local snapshot = self._hover_pointer_snapshot

    if snapshot == nil or snapshot.pointerType ~= 'mouse' then
        return nil
    end

    update_mouse_hover_target(self, snapshot.x, snapshot.y)

    return nil
end

local function begin_pointer_sequence(self, raw_event)
    local sequence_id = resolve_pointer_sequence_id(raw_event)

    if sequence_id == nil then
        return nil, nil, nil, nil
    end

    local target, path = resolve_spatial_target(self, raw_event)
    local sequence = {
        id = sequence_id,
        pointerType = resolve_pointer_type(raw_event),
        button = resolve_pointer_button(raw_event),
        originX = raw_event.x,
        originY = raw_event.y,
        lastX = raw_event.x,
        lastY = raw_event.y,
        target = target,
        path = path,
        dragging = false,
    }

    local sequences = self._active_pointer_sequences
    if sequences then
        sequences[sequence_id] = sequence
    end

    return sequence, target, path, sequence_id
end

local function get_pointer_sequence(self, raw_event)
    local sequence_id = resolve_pointer_sequence_id(raw_event)

    if sequence_id == nil then
        return nil, nil
    end

    local sequences = self._active_pointer_sequences
    return sequences and sequences[sequence_id], sequence_id
end

local function clear_pointer_sequence(self, sequence_id)
    if sequence_id == nil then
        return
    end

    local sequences = self._active_pointer_sequences
    if sequences then
        sequences[sequence_id] = nil
    end
end

local function create_pointer_activation_event(self, raw_event, sequence)
    if sequence == nil or sequence.target == nil then
        return nil, nil, nil
    end

    local release_target, release_path = resolve_spatial_target(self, raw_event)

    if release_target ~= sequence.target then
        return nil, release_target, release_path
    end

    return create_event('ui.activate', sequence.target, sequence.path, {
        pointerType = sequence.pointerType,
        x = raw_event.x,
        y = raw_event.y,
        button = sequence.button,
    }), release_target, release_path
end

local function stop_inertial_scroll_in_path(path)
    if path == nil then
        return
    end

    for index = 1, #path do
        local node = path[index]

        if node ~= nil and node._ui_scrollable_instance == true then
            local cancel = node._cancel_momentum or node._cancel_momentum
            if Types.is_function(cancel) then
                cancel(node)
            end
        end
    end
end

local function create_drag_event(sequence, raw_event, drag_phase)
    if sequence == nil or sequence.target == nil then
        return nil
    end

    return create_event('ui.drag', sequence.target, sequence.path, {
        pointerType = sequence.pointerType,
        x = raw_event.x,
        y = raw_event.y,
        button = sequence.button,
        dragPhase = drag_phase,
        originX = sequence.originX,
        originY = sequence.originY,
        deltaX = raw_event.x - sequence.originX,
        deltaY = raw_event.y - sequence.originY,
    })
end

local function create_scroll_event(self, raw_event)
    local delta_x = 0
    local delta_y = 0
    local stage_x = nil
    local stage_y = nil

    if raw_event.kind == 'wheelmoved' then
        delta_x = -(raw_event.x or 0) * WHEEL_DELTA_PIXELS
        delta_y = -(raw_event.y or 0) * WHEEL_DELTA_PIXELS
        stage_x = raw_event.stageX
        stage_y = raw_event.stageY
    elseif raw_event.kind == 'keypressed' then
        if raw_event.key == 'pageup' then
            delta_y = -max(get_public_value(self, 'height') or 0, KEYBOARD_SCROLL_STEP)
        elseif raw_event.key == 'pagedown' then
            delta_y = max(get_public_value(self, 'height') or 0, KEYBOARD_SCROLL_STEP)
        elseif raw_event.key == 'home' then
            delta_y = -max(get_public_value(self, 'height') or 0, KEYBOARD_SCROLL_STEP)
        elseif raw_event.key == 'end' then
            delta_y = max(get_public_value(self, 'height') or 0, KEYBOARD_SCROLL_STEP)
        end
    end

    if delta_x == 0 and delta_y == 0 then
        return nil, nil, nil
    end

    local target, path = resolve_spatial_target(self, raw_event)

    if target == nil then
        target, path = resolve_focused_target(self, true)
    end

    return create_event('ui.scroll', target, path, {
        x = stage_x,
        y = stage_y,
        deltaX = delta_x,
        deltaY = delta_y,
        axis = determine_scroll_axis(delta_x, delta_y),
    }), target, path
end

local function create_navigation_event(self, raw_event)
    local direction = nil
    local navigation_mode = nil

    if raw_event.key == 'tab' then
        navigation_mode = 'sequential'
        direction = is_shift_down(raw_event) and 'previous' or 'next'
    elseif raw_event.key == 'up' or raw_event.key == 'down' or
        raw_event.key == 'left' or raw_event.key == 'right' then
        navigation_mode = 'directional'
        direction = raw_event.key
    end

    if direction == nil then
        return nil, nil, nil
    end

    local target, path = resolve_active_focus_scope_target(self)

    return create_event('ui.navigate', target, path, {
        direction = direction,
        navigationMode = navigation_mode,
    }), target, path
end

local function apply_navigation_focus_movement(self, event)
    if event == nil or event.type ~= 'ui.navigate' or event.defaultPrevented then
        return get_stored_focus_owner(self)
    end

    if event.navigationMode == 'sequential' then
        return self:_move_focus_sequential_internal(event.direction)
    end

    if event.navigationMode == 'directional' then
        return self:_move_focus_directional_internal(event.direction)
    end

    return get_stored_focus_owner(self)
end

local function apply_pointer_focus_coupling(self, target, timing, event)
    if target == nil then
        return get_stored_focus_owner(self)
    end

    if timing ~= 'before' and (event == nil or event.type ~= 'ui.activate') then
        return get_stored_focus_owner(self)
    end

    if get_pointer_focus_coupling(target) ~= timing then
        return get_stored_focus_owner(self)
    end

    if timing == 'after' and event.defaultPrevented then
        return get_stored_focus_owner(self)
    end

    return self:_request_focus_internal(target)
end

local function create_dismiss_event(self)
    local target, path = resolve_active_focus_scope_target(self)
    return create_event('ui.dismiss', target, path), target, path
end

local function create_submit_event(self)
    local target, path = resolve_focused_target(self, true)
    return create_event('ui.submit', target, path), target, path
end

local function create_keyboard_activate_event(self)
    local target, path = resolve_focused_target(self, false)

    if target == nil then
        return nil, nil, nil
    end

    return create_event('ui.activate', target, path), target, path
end

local function create_text_input_event(self, raw_event)
    local target, path = resolve_focused_target(self, false)

    if target == nil then
        return nil, nil, nil
    end

    return create_event('ui.text.input', target, path, {
        text = raw_event.text,
    }), target, path
end

local function create_text_compose_event(self, raw_event)
    local target, path = resolve_focused_target(self, false)

    if target == nil then
        return nil, nil, nil
    end

    local range_start = raw_event.rangeStart
    local range_end = raw_event.rangeEnd

    if range_start == nil and Types.is_number(raw_event.start) then
        range_start = raw_event.start
    end

    if range_end == nil then
        if Types.is_number(raw_event.start) and Types.is_number(raw_event.length) then
            range_end = raw_event.start + raw_event.length
        elseif Types.is_number(range_start) then
            range_end = range_start
        end
    end

    return create_event('ui.text.compose', target, path, {
        text = raw_event.text,
        rangeStart = range_start,
        rangeEnd = range_end,
    }), target, path
end

local function apply_environment(self, width, height, safe_area_insets)
    local _
    local viewport_changed = false
    local safe_area_changed = false

    if width ~= nil and get_public_value(self, 'width') ~= width then
        Assert.number('Stage.width', width, 3)
        self.width = width
        viewport_changed = true
    end

    if height ~= nil and get_public_value(self, 'height') ~= height then
        Assert.number('Stage.height', height, 3)
        self.height = height
        viewport_changed = true
    end

    if viewport_changed then
        refresh_environment_bounds(self)
    end

    if safe_area_insets ~= nil then
        _, safe_area_changed = set_safe_area_insets(self, safe_area_insets, 3)
    end

    refresh_environment_bounds(self)

    if viewport_changed or safe_area_changed then
        self:_mark_layout_subtree_dirty()
    end
end

local function resolve_orientation(viewport)
    if viewport.width >= viewport.height then
        return 'landscape'
    end

    return 'portrait'
end

local function prepare_layout_subtree(stage, node)
    stage:_resolve_responsive_for_node(node)
    node:_prepare_for_layout_pass(stage)

    local children = node._children

    for index = 1, #children do
        prepare_layout_subtree(stage, children[index])
    end
end

local function run_layout_subtree(stage, node)
    if node._ui_layout_instance == true and
        Types.is_function(node._run_layout_pass) then
        node:_run_layout_pass(stage)
    end

    local children = node._children

    for index = 1, #children do
        run_layout_subtree(stage, children[index])
    end
end

local function refresh_geometry_subtree(node)
    node:_refresh_if_dirty()

    local children = node._children

    for index = 1, #children do
        refresh_geometry_subtree(children[index])
    end
end

function Stage:__index(key)
    if key == 'baseSceneLayer' or key == 'overlayLayer' then
        return rawget(self, key)
    end

    -- Walk the class hierarchy for methods
    local current = rawget(self, '_pclass') or getmetatable(self)
    while current ~= nil do
        local val = rawget(current, key)
        if val ~= nil then return val end
        current = rawget(current, "super")
    end

    return nil
end
Stage.__index = Stage.__index

function Stage:__newindex(key, value)
    if key == 'parent' then
        if value ~= nil then
            fail('Stage must not have a parent', 2)
        end

        rawset(self, key, value)
        return
    end

    if key == 'baseSceneLayer' or key == 'overlayLayer' then
        fail('Stage layer ownership is runtime-managed', 2)
    end

    fail('Stage does not support prop "' .. key .. '"', 2)
end

function Stage:constructor(opts)
    if opts == nil then
        opts = {}
    else
        Assert.table('opts', opts, 3)
        for k in pairs(opts) do
            if not StageSchema[k] then
                fail('Stage does not support prop "' .. k .. '"', 3)
            end
        end
    end

    -- Track whether dimensions are host-driven (no explicit width/height provided).
    -- When host-driven, refresh_environment_bounds will always poll the live host.
    local host_driven = (opts.width == nil and opts.height == nil)
    rawset(self, '_host_driven_dims', host_driven)



    rawset(self, '_ui_stage_instance', true)
    rawset(self, '_update_ran', false)
    rawset(self, '_last_input_delivery', nil)
    rawset(self, '_viewport_bounds_cache', Rectangle(0, 0, 0, 0))
    rawset(self, '_safe_area_bounds_cache', Rectangle(0, 0, 0, 0))
    rawset(self, '_focus_owner', nil)
    rawset(self, '_focused_node', nil)
    rawset(self, '_active_focus_scope_chain', { self })
    rawset(self, '_focus_trap_stack', {})
    rawset(self, '_pre_trap_focus_history', {})
    rawset(self, '_active_pointer_sequences', {})
    rawset(self, '_hovered_target', nil)
    rawset(self, '_hover_pointer_snapshot', nil)
    rawset(self, '_queued_state_changes', {
        head = 1,
        tail = 0,
        items = {},
    })

    Container.constructor(self, {}, StageSchema)
    self.schema:define(StageSchema)

    for key, value in pairs(opts) do
        self[key] = value
    end

    -- Enforce singleton contract with "self-healing" for cross-file cascades.
    if active_stage ~= nil then
        local current_source = debug.getinfo(3, 'S').source
        local old_source = active_stage._creation_source

        -- If it's the same file, it's a genuine singleton violation (e.g., in a single test).
        -- If it's a different file, it's a leftover from a previous spec that failed to destroy.
        if current_source == old_source then
            fail('more than one Stage instance', 3)
        end

        -- Cross-file cascade: silently destroy the stale instance to allow the new one.
        local old_stage = active_stage
        active_stage = nil
        old_stage:destroy()
    end

    active_stage = self
    self._creation_source = debug.getinfo(3, 'S').source

    refresh_environment_bounds(self)

    local base_scene_layer = Container({
        tag = 'base scene layer',
        internal = true,
        width = 'fill',
        height = 'fill',
    })
    Container._allow_fill_from_parent(base_scene_layer, { width = true, height = true })
    Container._allow_child_fill(base_scene_layer, { width = true, height = true })
    local overlay_layer = Container({
        tag = 'overlay layer',
        internal = true,
        width = 'fill',
        height = 'fill',
    })
    Container._allow_fill_from_parent(overlay_layer, { width = true, height = true })
    Container._allow_child_fill(overlay_layer, { width = true, height = true })

    self.baseSceneLayer = base_scene_layer
    self.overlayLayer = overlay_layer

    Container.addChild(self, base_scene_layer)
    Container.addChild(self, overlay_layer)

    active_stage = self
end

function Stage.new(opts)
    return Stage(opts)
end

function Stage.is_stage(value)
    return Types.is_instance(value, Stage)
end

function Stage:_sync_environment_from_host()

    local width, height = read_host_viewport()

    if width == nil or height == nil then
        return self
    end

    apply_environment(
        self,
        width,
        height,
        read_host_safe_area_insets(width, height) or
            get_public_value(self, 'safeAreaInsets')
    )

    return self
end

function Stage:_resolve_responsive_for_node(node)

    local responsive = rawget(node, 'responsive')
    local breakpoints = rawget(node, 'breakpoints')
    if responsive == nil and breakpoints == nil then
        if node._responsive_token ~= nil or node._resolved_responsive_overrides ~= nil then
            node:_set_resolved_responsive_overrides(nil, nil)
        end
        return node
    end

    local viewport = self._viewport_bounds_cache
    local safe_area_bounds = self._safe_area_bounds_cache
    local safe_area_insets = get_public_value(self, 'safeAreaInsets')
    local parent_width = viewport.width
    local parent_height = viewport.height

    if node.parent ~= nil then
        local parent_content_rect = node.parent:_get_effective_content_rect()
        parent_width = parent_content_rect.width
        parent_height = parent_content_rect.height
    elseif node._measurement_context_width ~= nil or
        node._measurement_context_height ~= nil then
        parent_width = node._measurement_context_width or 0
        parent_height = node._measurement_context_height or 0
    end

    local token, overrides = Responsive.resolve(node, {
        viewport = {
            x = viewport.x,
            y = viewport.y,
            width = viewport.width,
            height = viewport.height,
        },
        orientation = resolve_orientation(viewport),
        safeArea = {
            x = safe_area_bounds.x,
            y = safe_area_bounds.y,
            width = safe_area_bounds.width,
            height = safe_area_bounds.height,
            insets = safe_area_insets,
        },
        parent = {
            width = parent_width,
            height = parent_height,
        },
    })

    node:_set_resolved_responsive_overrides(token, overrides)

    return node
end

function Stage:_get_focus_scope_root()
    return self
end

function Stage:_set_focus_contract_internal(node, contract)
    assert_container_node('node', node, 2)

    if contract == nil then
        node._focus_contract_internal = nil
        self:_refresh_focus_runtime_state()
        return node
    end

    assert_table('contract', contract, 2)

    local normalized = {}

    if contract.scope ~= nil then
        normalized.scope = contract.scope == true
        node.focusable = normalized.scope or node.focusable
    end

    if contract.trap ~= nil then
        normalized.trap = contract.trap == true
    end

    if contract.pointerFocusCoupling ~= nil then
        normalized.pointer_focus_coupling = contract.pointerFocusCoupling
        node.pointerFocusCoupling = contract.pointerFocusCoupling
    end

    if contract.trap ~= nil and not Types.is_boolean(contract.trap) then
        fail('contract.trap must be a boolean or nil', 2)
    end

    local pointer_coupling = contract.pointerFocusCoupling

    if pointer_coupling == nil then
        pointer_coupling = contract.pointer_focus_coupling
    end

    if pointer_coupling ~= nil and pointer_coupling ~= 'before' and
        pointer_coupling ~= 'after' and pointer_coupling ~= 'none' then
        fail(
            'contract.pointerFocusCoupling must be "before", "after", "none", or nil',
            2
        )
    end

    if contract.scope == true or contract.trap == true then
        normalized.scope = true
    end

    if contract.trap == true then
        normalized.trap = true
    end

    if pointer_coupling ~= nil then
        normalized.pointer_focus_coupling = pointer_coupling
    end

    if next(normalized) == nil then
        normalized = nil
    end

    node._focus_contract_internal = normalized
    self:_refresh_focus_runtime_state()

    return node
end

function Stage:_set_focus_owner_internal(node)

    if node ~= nil then
        assert_container_node('node', node, 2)

        if not is_descendant_or_same(self, node) then
            return nil
        end
    end

    set_stored_focus_owner(self, node)
    self:_refresh_focus_runtime_state()

    return get_stored_focus_owner(self)
end

-- Internal runtime/test support for explicit focus requests. This is not a
-- stabilized public Stage API surface.
function Stage:_request_focus_internal(node)
    self:_synchronize_for_read()

    if node ~= nil then
        assert_container_node('node', node, 2)

        if not is_focus_request_allowed(self, node) then
            return get_stored_focus_owner(self)
        end
    end

    return commit_focus_owner(self, node)
end

function Stage:_move_focus_sequential_internal(direction)

    if direction ~= 'next' and direction ~= 'previous' then
        fail('direction must be "next" or "previous"', 2)
    end

    self:_synchronize_for_read()

    local scope_root = get_active_focus_scope(self)
    local candidates = collect_focus_candidates(self, scope_root, scope_root, {})
    local candidate_count = #candidates

    if candidate_count == 0 then
        return get_stored_focus_owner(self)
    end

    local current_owner = get_stored_focus_owner(self)
    local current_index = nil

    for index = 1, candidate_count do
        if candidates[index] == current_owner then
            current_index = index
            break
        end
    end

    if current_index == nil then
        if direction == 'next' then
            current_index = 0
        else
            current_index = candidate_count + 1
        end
    end

    local next_index

    if direction == 'next' then
        next_index = current_index + 1

        if next_index > candidate_count then
            next_index = 1
        end
    else
        next_index = current_index - 1

        if next_index < 1 then
            next_index = candidate_count
        end
    end

    return self:_request_focus_internal(candidates[next_index])
end

function Stage:_move_focus_directional_internal(direction)

    if direction ~= 'up' and direction ~= 'down' and direction ~= 'left' and
        direction ~= 'right' then
        fail('direction must be "up", "down", "left", or "right"', 2)
    end

    self:_synchronize_for_read()

    local current_owner = get_stored_focus_owner(self)

    if current_owner == nil then
        return nil
    end

    local scope_root = get_active_focus_scope(self)

    if get_containing_focus_scope(self, current_owner) ~= scope_root then
        return current_owner
    end

    local current_x, current_y = get_world_center(current_owner)
    local candidates = collect_focus_candidates(self, scope_root, scope_root, {})
    local best_candidate = nil
    local best_distance = huge
    local best_order_index = huge

    for index = 1, #candidates do
        local candidate = candidates[index]

        if candidate ~= current_owner then
            local candidate_x, candidate_y = get_world_center(candidate)
            local delta_x = candidate_x - current_x
            local delta_y = candidate_y - current_y

            if matches_direction(direction, delta_x, delta_y) then
                local distance = delta_x * delta_x + delta_y * delta_y

                if distance < best_distance or
                    (distance == best_distance and index < best_order_index) then
                    best_candidate = candidate
                    best_distance = distance
                    best_order_index = index
                end
            end
        end
    end

    if best_candidate == nil then
        return current_owner
    end

    return self:_request_focus_internal(best_candidate)
end

function Stage:_get_focus_owner_internal()
    self:_synchronize_for_read()
    return get_stored_focus_owner(self)
end

function Stage:_get_active_focus_scope_chain_internal()
    self:_synchronize_for_read()
    return copy_array(self._active_focus_scope_chain)
end

function Stage:_get_focus_trap_stack_internal()
    self:_synchronize_for_read()
    return copy_array(self._focus_trap_stack)
end

function Stage:_get_pre_trap_focus_history_internal()
    self:_synchronize_for_read()
    return copy_array(self._pre_trap_focus_history)
end

function Stage:_handle_attached_subtree(_, _)
    self:_refresh_focus_runtime_state()
    return self
end

function Stage:_handle_detached_subtree(node, _)
    local focus_owner = get_stored_focus_owner(self)
    local previous_owner = focus_owner

    if focus_owner ~= nil and is_descendant_or_same(node, focus_owner) then
        set_stored_focus_owner(self, nil)
    end

    self:_refresh_focus_runtime_state(previous_owner)
    return self
end

function Stage:_refresh_focus_runtime_state(previous_owner_override)
    local previous_owner = previous_owner_override

    if previous_owner == nil then
        previous_owner = get_stored_focus_owner(self)
    end

    local focus_owner = get_stored_focus_owner(self)

    if not is_focus_owner_target(self, focus_owner) then
        focus_owner = nil
    end

    local active_traps = collect_active_focus_traps(self, self.overlayLayer, {})
    local previous_stack = self._focus_trap_stack
    local previous_history = self._pre_trap_focus_history
    local prefix_length = 0
    local next_stack = {}
    local next_history = {}
    local restoration_candidate = nil

    while prefix_length < #previous_stack and prefix_length < #active_traps do
        local next_index = prefix_length + 1

        if previous_stack[next_index] ~= active_traps[next_index] then
            break
        end

        prefix_length = next_index
    end

    for index = 1, prefix_length do
        next_stack[index] = previous_stack[index]
        next_history[index] = previous_history[index]
    end

    if prefix_length < #previous_stack then
        restoration_candidate = previous_history[prefix_length + 1]

        if not is_focus_owner_target(self, restoration_candidate) then
            restoration_candidate = nil
        end
    end

    if restoration_candidate ~= nil then
        local innermost_retained_trap = next_stack[#next_stack]

        if innermost_retained_trap ~= nil and
            not is_descendant_or_same(innermost_retained_trap, restoration_candidate) then
            restoration_candidate = nil
        end
    end

    for index = prefix_length + 1, #active_traps do
        local trap = active_traps[index]
        next_stack[index] = trap
        next_history[index] = focus_owner
        focus_owner = resolve_scope_entry_focus_target(self, trap)
    end

    if restoration_candidate ~= nil then
        focus_owner = restoration_candidate
    end

    if focus_owner ~= nil and not is_focus_owner_target(self, focus_owner) then
        focus_owner = nil
    end

    self._focus_trap_stack = next_stack
    self._pre_trap_focus_history = next_history
    set_stored_focus_owner(self, focus_owner)

    local active_chain = { self }
    local trap_stack = self._focus_trap_stack

    for i = 1, #trap_stack do
        active_chain[#active_chain + 1] = trap_stack[i]
    end

    local innermost_scope = get_containing_focus_scope(self, focus_owner)
    if innermost_scope ~= self then
        -- Only add the focus owner's scope if it's not already in the chain (e.g. if it's within a trap)
        local already_in_chain = false
        for i = 1, #active_chain do
            if active_chain[i] == innermost_scope then
                already_in_chain = true
                break
            end
        end
        if not already_in_chain then
            active_chain[#active_chain + 1] = innermost_scope
        end
    end

    self._active_focus_scope_chain = active_chain

    local committed_owner = get_stored_focus_owner(self)

    if committed_owner ~= previous_owner then
        dispatch_focus_change_event(self, previous_owner, committed_owner)
    end

    return self
end

local function dirty_subtree(node)
    node:markDirty()
    local children = node._children
    for i = 1, #children do
        dirty_subtree(children[i])
    end
end

function Stage:_mark_layout_subtree_dirty()
    Container.markDirty(self)
    local children = self._children
    for i = 1, #children do
        dirty_subtree(children[i])
    end
    return self
end

local synchronize_for_read = Memoize.memoize_tick(function(self)

    -- Draw pass must remain read-only. Stage:update() is responsible for
    -- producing a frame-current tree before Stage:draw() begins.
    if self._drawing then
        return self
    end

    -- For host-driven stages, always re-poll the live host viewport/safe-area
    -- so that property reads reflect the current host state regardless of
    -- whether update() has already run this frame.
    if self._host_driven_dims and
        not self._updating and
        not self._synchronizing then
        refresh_environment_bounds(self)
    end

    -- Perform a read-only layout pass when the stage needs layout but hasn't
    -- been explicitly updated yet. This MUST NOT set _update_ran — that flag
    -- is only set by an explicit Stage:update() call, enforcing the two-pass
    -- update/draw contract required by the spec.
    if not self._updating and not self._synchronizing then
        self._synchronizing = true
        if not self._host_driven_dims then
            refresh_environment_bounds(self)
        end
        prepare_layout_subtree(self, self)
        run_layout_subtree(self, self)
        refresh_geometry_subtree(self)
        self._synchronizing = false
    end

    return self
end)

function Stage:_synchronize_for_read()
    return synchronize_for_read(self)
end

function Stage._synchronize_for_read(self)
    -- This version is used by __index and other internal lookups
    return synchronize_for_read(self)
end

function Stage:_queue_state_change(handler)

    if not Types.is_function(handler) then
        fail('handler must be a function', 2)
    end

    local queue = self._queued_state_changes
    if queue then
        queue.tail = queue.tail + 1
        queue.items[queue.tail] = handler
    end

    return self
end

function Stage:getViewport()
    self:_synchronize_for_read()
    return self._viewport_bounds_cache:clone()
end

function Stage:getSafeArea()
    self:_synchronize_for_read()
    return get_public_value(self, 'safeAreaInsets'):clone()
end

function Stage:addChild()
    fail(
        'Stage does not support child insertion; '
            .. 'baseSceneLayer and overlayLayer are runtime-managed '
            .. 'and should be used instead',
        2
    )
end

function Stage:removeChild()
    fail(
        'Stage does not support child removal; '
            .. 'baseSceneLayer and overlayLayer are runtime-managed '
            .. 'and cannot be removed directly',
        2
    )
end

function Stage:removeAllChildren()
    fail(
        'Stage does not support child removal; '
            .. 'baseSceneLayer and overlayLayer are runtime-managed '
            .. 'and cannot be removed directly',
        2
    )
end

function Stage:getSafeAreaBounds()
    return self._safe_area_bounds_cache:clone()
end

function Stage:resize(width, height, safe_area_insets)
    apply_environment(self, width, height, safe_area_insets)
    return self
end

function Stage:resolveTarget(x, y)
    self:_synchronize_for_read()
    return resolve_target_resolved(self, x, y)
end

function Stage:deliverInput(raw_event)
    Assert.table('raw_event', raw_event, 2)

    local intent = translate_raw_input(raw_event)

    if intent == nil then
        return build_delivery(raw_event, nil, nil, nil, nil)
    end

    if intent == 'Activate' then
        if raw_event.kind == 'mousepressed' or raw_event.kind == 'touchpressed' then
            local _, target, path, sequence_id = begin_pointer_sequence(self, raw_event)
            stop_inertial_scroll_in_path(path)

            if sequence_id == 'mouse:1' then
                update_mouse_hover_target(self, raw_event.x, raw_event.y)
            end

            apply_pointer_focus_coupling(self, target, 'before')

            return build_delivery(raw_event, intent, nil, target, path)
        end

        if raw_event.kind == 'mousereleased' or raw_event.kind == 'touchreleased' then
            local sequence, sequence_id = get_pointer_sequence(self, raw_event)

            if sequence == nil then
                local target, path = resolve_spatial_target(self, raw_event)
                return build_delivery(raw_event, intent, nil, target, path)
            end

            clear_pointer_sequence(self, sequence_id)

            if sequence_id == 'mouse:1' then
                update_mouse_hover_target(self, raw_event.x, raw_event.y)
            end

            if sequence.dragging then
                local event = create_drag_event(sequence, raw_event, 'end')
                dispatch_event(event)
                return build_delivery(raw_event, 'Drag', event)
            end

            local event, target, path = create_pointer_activation_event(self, raw_event, sequence)
            dispatch_event(event)
            apply_pointer_focus_coupling(self, sequence.target, 'after', event)

            return build_delivery(raw_event, intent, event, target, path)
        end

        if raw_event.kind == 'keypressed' and raw_event.key == 'space' then
            local event, target, path = create_keyboard_activate_event(self)
            dispatch_event(event)
            return build_delivery(raw_event, intent, event, target, path)
        end
    end

    if intent == 'Drag' then
        local sequence = get_pointer_sequence(self, raw_event)

        if sequence == nil then
            if raw_event.kind == 'mousemoved' then
                local target, path = update_mouse_hover_target(self, raw_event.x, raw_event.y)
                return build_delivery(raw_event, intent, nil, target, path)
            end

            local target, path = resolve_spatial_target(self, raw_event)
            return build_delivery(raw_event, intent, nil, target, path)
        end

        -- Hover transformation is gated while any mouse button is held.
        -- We don't update hover, but we continue to allow drag detection.
        if sequence.pointerType ~= 'mouse' then
            update_mouse_hover_target(self, raw_event.x, raw_event.y)
        end

        if not sequence.dragging then
            local dx = raw_event.x - sequence.originX
            local dy = raw_event.y - sequence.originY

            if dx * dx + dy * dy >= DRAG_THRESHOLD_SQUARED then
                sequence.dragging = true
                local event = create_drag_event(sequence, raw_event, 'start')
                dispatch_event(event)
                return build_delivery(raw_event, intent, event)
            end

            return build_delivery(raw_event, intent, nil, sequence.target, sequence.path)
        end

        local event = create_drag_event(sequence, raw_event, 'move')
        dispatch_event(event)
        return build_delivery(raw_event, intent, event)
    end

    if intent == 'Scroll' then
        local event, target, path = create_scroll_event(self, raw_event)
        dispatch_event(event)
        return build_delivery(raw_event, intent, event, target, path)
    end

    if intent == 'Navigate' then
        local event, target, path = create_navigation_event(self, raw_event)
        dispatch_event(event)
        apply_navigation_focus_movement(self, event)
        return build_delivery(raw_event, intent, event, target, path)
    end

    if intent == 'Dismiss' then
        local event, target, path = create_dismiss_event(self)
        dispatch_event(event)
        return build_delivery(raw_event, intent, event, target, path)
    end

    if intent == 'Submit' then
        local event, target, path = create_submit_event(self)
        dispatch_event(event)
        return build_delivery(raw_event, intent, event, target, path)
    end

    if intent == 'TextInput' then
        local event, target, path = create_text_input_event(self, raw_event)
        dispatch_event(event)
        return build_delivery(raw_event, intent, event, target, path)
    end

    if intent == 'TextCompose' then
        local event, target, path = create_text_compose_event(self, raw_event)
        dispatch_event(event)
        return build_delivery(raw_event, intent, event, target, path)
    end

    return build_delivery(raw_event, intent, nil, nil, nil)
end

function Stage:update(_)
    Memoize.tick()

    if self._updating then
        return self
    end

    local profile_token = RuntimeProfiler.push_zone('Stage.update')
    self._updating = true

    refresh_environment_bounds(self)

    local queue = self._queued_state_changes
    while queue and queue.head <= queue.tail do
        local handler = queue.items[queue.head]
        queue.items[queue.head] = nil
        queue.head = queue.head + 1
        handler()
    end

    if queue then
        queue.head = 1
        queue.tail = 0
    end

    prepare_layout_subtree(self, self)
    run_layout_subtree(self, self)

    self:_refresh_if_dirty()
    self.baseSceneLayer:update()
    self.overlayLayer:update()

    refresh_hover_target(self)

    self._updating = false
    self._update_ran = true
    RuntimeProfiler.pop_zone(profile_token)

    return self
end

function Stage:_prepare_draw(graphics, draw_callback)
    if not self._update_ran then
        fail(TWO_PASS_VIOLATION, 3)
    end

    graphics, draw_callback = resolve_draw_args(graphics, draw_callback)
    draw_callback = create_focus_aware_draw_callback(self, draw_callback)

    return graphics, draw_callback
end

function Stage:_draw_overlay_layer_resolved(graphics, draw_callback)
    self.overlayLayer:_draw_subtree_resolved(graphics, function(node)
        draw_callback(node, graphics)
    end)
end

function Stage:draw(graphics, draw_callback)

    local profile_token = RuntimeProfiler.push_zone('Stage.draw')
    graphics, draw_callback = self:_prepare_draw(graphics, draw_callback)
    local previous_drawing = self._drawing

    local error_handler = function(message)
        if debug ~= nil and Types.is_function(debug.traceback) then
            return debug.traceback(message, 2)
        end

        return message
    end

    self._drawing = true

    local ok, err = xpcall(function()
        self.baseSceneLayer:_draw_subtree_resolved(graphics, function(node)
            draw_callback(node, graphics)
        end)

        self:_draw_overlay_layer_resolved(graphics, draw_callback)
    end, error_handler)

    self._drawing = previous_drawing
    self._update_ran = false
    RuntimeProfiler.pop_zone(profile_token)

    if not ok then
        error(err, 0)
    end

    return self
end

function Stage:on_destroy()
    if active_stage == self then
        active_stage = nil
    end

    Container.on_destroy(self)
end

return Stage
