local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local Event = require('lib.ui.event.event')
local Insets = require('lib.ui.core.insets')
local Rectangle = require('lib.ui.core.rectangle')
local Responsive = require('lib.ui.layout.responsive')

local max = math.max
local huge = math.huge

local Stage = {}

local DRAG_THRESHOLD = 4
local DRAG_THRESHOLD_SQUARED = DRAG_THRESHOLD * DRAG_THRESHOLD
local WHEEL_DELTA_PIXELS = 40
local KEYBOARD_SCROLL_STEP = 40

local STAGE_PUBLIC_KEYS = {
    width = true,
    height = true,
    safeAreaInsets = true,
}

local TWO_PASS_VIOLATION =
    'Stage.draw() called without a preceding Stage.update() in this frame. ' ..
    'The two-pass contract requires update to complete before draw begins.'

local active_stage = nil
local build_target_path

local function fail(message, level)
    error(message, (level or 1) + 1)
end

local function assert_number(name, value, level)
    if type(value) ~= 'number' then
        fail(name .. ' must be a number', level or 1)
    end
end

local function assert_table(name, value, level)
    if type(value) ~= 'table' then
        fail(name .. ' must be a table', level or 1)
    end
end

local function assert_not_destroyed(self, level)
    if self._destroyed then
        fail('cannot use a destroyed Stage', level or 1)
    end
end

local function get_public_value(self, key)
    local public_values = rawget(self, '_public_values')

    if public_values == nil then
        return nil
    end

    return public_values[key]
end

local function copy_options(opts)
    if opts == nil then
        return {}
    end

    assert_table('opts', opts, 2)

    local copy = {}

    for key, value in pairs(opts) do
        if not STAGE_PUBLIC_KEYS[key] then
            fail('Stage does not support prop "' .. tostring(key) .. '"', 3)
        end

        copy[key] = value
    end

    return copy
end

local function copy_array(values)
    local copy = {}

    for index = 1, #values do
        copy[index] = values[index]
    end

    return copy
end

local function assert_container_node(name, value, level)
    if type(value) ~= 'table' or value._ui_container_instance ~= true then
        fail(name .. ' must be a Container', level or 1)
    end
end

local function set_stored_focus_owner(self, node)
    rawset(self, '_focus_owner', node)
    rawset(self, '_focused_node', node)
end

local function get_stored_focus_owner(self)
    local owner = rawget(self, '_focus_owner')

    if owner == nil then
        owner = rawget(self, '_focused_node')
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
    local effective_values = rawget(node, '_effective_values')

    if effective_values ~= nil and effective_values[key] ~= nil then
        return effective_values[key]
    end

    local public_values = rawget(node, '_public_values')

    if public_values ~= nil then
        return public_values[key]
    end

    return nil
end

local function is_attached_visible_to_stage(self, node)
    if node == nil or node._destroyed or not is_descendant_or_same(self, node) then
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
    if node == nil or node._destroyed or not is_descendant_or_same(self, node) then
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
    return rawget(node, '_focus_contract_internal')
end

local function is_active_focus_scope_node(self, node)
    if node == self then
        return true
    end

    local contract = get_internal_focus_contract(node)

    return type(contract) == 'table' and contract.scope == true and
        is_attached_visible_to_stage(self, node)
end

local function is_active_focus_trap_node(self, node)
    local contract = get_internal_focus_contract(node)

    return type(contract) == 'table' and contract.scope == true and
        contract.trap == true and
        is_descendant_or_same(self.overlayLayer, node) and
        is_attached_visible_to_stage(self, node)
end

local function collect_active_focus_traps(self, node, traps)
    if node ~= self and is_active_focus_trap_node(self, node) then
        traps[#traps + 1] = node
    end

    local children = rawget(node, '_children') or {}

    for index = 1, #children do
        collect_active_focus_traps(self, children[index], traps)
    end

    return traps
end

local function get_active_focus_scope(self)
    local chain = rawget(self, '_active_focus_scope_chain') or { self }
    return chain[#chain] or self
end

local function get_innermost_focus_trap(self)
    local traps = rawget(self, '_focus_trap_stack') or {}
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
    local contract = get_internal_focus_contract(node)

    if type(contract) ~= 'table' then
        return nil
    end

    return contract.pointer_focus_coupling
end

local function is_focus_eligible(self, node)
    return node ~= nil and
        not node._destroyed and
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

    if node._destroyed or not is_descendant_or_same(self, node) or
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
    return is_focus_eligible(self, node) and
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

    local children = rawget(node, '_children') or {}

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
        type(love.graphics.getDimensions) ~= 'function' then
        return nil, nil
    end

    local ok, width, height = pcall(love.graphics.getDimensions)

    if not ok or type(width) ~= 'number' or type(height) ~= 'number' then
        return nil, nil
    end

    return width, height
end

local function read_host_safe_area_bounds()
    if love == nil or love.window == nil or
        type(love.window.getSafeArea) ~= 'function' then
        return nil
    end

    local ok, x, y, width, height = pcall(love.window.getSafeArea)

    if not ok or type(x) ~= 'number' or type(y) ~= 'number' or
        type(width) ~= 'number' or type(height) ~= 'number' then
        return nil
    end

    return Rectangle.new(x, y, max(0, width), max(0, height))
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

    local viewport = Rectangle.new(
        0,
        0,
        max(0, viewport_width or 0),
        max(0, viewport_height or 0)
    )
    local safe_area = viewport:intersection(bounds)

    return Insets.new(
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
    local safe_area_insets = get_public_value(self, 'safeAreaInsets') or
        Insets.zero()
    local viewport = Rectangle.new(
        0,
        0,
        max(0, get_public_value(self, 'width') or 0),
        max(0, get_public_value(self, 'height') or 0)
    )

    rawset(self, '_viewport_bounds_cache', viewport)
    rawset(self, '_safe_area_bounds_cache', viewport:inset(safe_area_insets))
end

local function set_initial_safe_area_insets(self, value)
    local normalized = normalize_safe_area_insets(value, 3)

    self._public_values.safeAreaInsets = normalized
    self._effective_values.safeAreaInsets = normalized
end

local function set_safe_area_insets(self, value, level)
    local normalized = normalize_safe_area_insets(value, level or 1)
    local current = self._public_values.safeAreaInsets

    if current ~= nil and current == normalized then
        return normalized, false
    end

    self._public_values.safeAreaInsets = normalized
    self._effective_values.safeAreaInsets = normalized
    refresh_environment_bounds(self)
    Container.markDirty(self)
    return normalized, true
end

local function resolve_draw_args(graphics, draw_callback)
    if draw_callback == nil and type(graphics) == 'function' then
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

    if type(graphics) ~= 'table' then
        fail('graphics must be a graphics adapter table', 3)
    end

    if type(draw_callback) ~= 'function' then
        fail('draw_callback must be a function', 3)
    end

    return graphics, draw_callback
end

local function create_focus_aware_draw_callback(self, draw_callback)
    local function restore_focus_draw_state(node, previous, focused)
        if previous ~= focused then
            rawset(node, '_focused', previous)
        end
    end

    local function decorate_focused_drawable(node, graphics)
        if node._destroyed or not Drawable.is_drawable(node) then
            return
        end

        if get_stored_focus_owner(self) == node then
            node:_draw_default_focus_indicator(graphics)
        end
    end

    local error_handler = function(message)
        if debug ~= nil and type(debug.traceback) == 'function' then
            return debug.traceback(message, 2)
        end

        return message
    end

    return function(node, graphics)
        local previous = rawget(node, '_focused')
        local focused = get_stored_focus_owner(self) == node or nil

        if previous ~= focused then
            rawset(node, '_focused', focused)
        end

        local ok, err = xpcall(function()
            draw_callback(node)
            decorate_focused_drawable(node, graphics)
        end, error_handler)

        restore_focus_draw_state(node, previous, focused)

        if not ok then
            error(err, 0)
        end
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
    if love ~= nil and love.timer ~= nil and type(love.timer.getTime) == 'function' then
        local ok, timestamp = pcall(love.timer.getTime)

        if ok and type(timestamp) == 'number' then
            return timestamp
        end
    end

    return os.clock()
end

local function is_shift_down(raw_event)
    if raw_event.shift == true then
        return true
    end

    local modifiers = rawget(raw_event, 'modifiers') or rawget(raw_event, 'mods')

    if type(modifiers) ~= 'table' then
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

    if type(x) ~= 'number' or type(y) ~= 'number' then
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

    return Event.new({
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
    local sequences = rawget(self, '_active_pointer_sequences')

    if sequences == nil then
        return false
    end

    return sequences['mouse:1'] ~= nil
end

local function deliver_internal_hover_notification(node, handler_name, payload)
    if node == nil or node._destroyed then
        return
    end

    local handler = rawget(node, handler_name)

    if handler == nil then
        handler = node[handler_name]
    end

    if type(handler) == 'function' then
        handler(node, payload)
    end
end

local function set_hover_target(self, next_target, payload)
    local previous_target = rawget(self, '_hovered_target')

    if previous_target == next_target then
        return next_target, false
    end

    if previous_target ~= nil and not previous_target._destroyed then
        rawset(previous_target, '_hovered', false)
        deliver_internal_hover_notification(
            previous_target,
            '_handle_internal_pointer_leave',
            payload
        )
    end

    rawset(self, '_hovered_target', next_target)

    if next_target ~= nil then
        rawset(next_target, '_hovered', true)
        deliver_internal_hover_notification(
            next_target,
            '_handle_internal_pointer_enter',
            payload
        )
    end

    return next_target, true
end

local function update_mouse_hover_target(self, x, y)
    if type(x) ~= 'number' or type(y) ~= 'number' then
        return nil, nil, false
    end

    rawset(self, '_hover_pointer_snapshot', {
        pointerType = 'mouse',
        x = x,
        y = y,
    })

    local next_target = resolve_target_resolved(self, x, y)
    local next_path = nil

    if next_target ~= nil then
        next_path = build_target_path(self, next_target)
    end

    local previous_target = rawget(self, '_hovered_target')

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

    local snapshot = rawget(self, '_hover_pointer_snapshot')

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

    self._active_pointer_sequences[sequence_id] = sequence

    return sequence, target, path, sequence_id
end

local function get_pointer_sequence(self, raw_event)
    local sequence_id = resolve_pointer_sequence_id(raw_event)

    if sequence_id == nil then
        return nil, nil
    end

    return self._active_pointer_sequences[sequence_id], sequence_id
end

local function clear_pointer_sequence(self, sequence_id)
    if sequence_id == nil then
        return
    end

    self._active_pointer_sequences[sequence_id] = nil
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
            delta_y = -max(self.height, KEYBOARD_SCROLL_STEP)
        elseif raw_event.key == 'pagedown' then
            delta_y = max(self.height, KEYBOARD_SCROLL_STEP)
        elseif raw_event.key == 'home' then
            delta_y = -max(self.height, KEYBOARD_SCROLL_STEP)
        elseif raw_event.key == 'end' then
            delta_y = max(self.height, KEYBOARD_SCROLL_STEP)
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
    if target == nil or event == nil or event.type ~= 'ui.activate' then
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

    if range_start == nil and type(raw_event.start) == 'number' then
        range_start = raw_event.start
    end

    if range_end == nil then
        if type(raw_event.start) == 'number' and type(raw_event.length) == 'number' then
            range_end = raw_event.start + raw_event.length
        elseif type(range_start) == 'number' then
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
    local viewport_changed = false
    local safe_area_changed = false

    if width ~= nil and get_public_value(self, 'width') ~= width then
        assert_number('Stage.width', width, 3)
        Container.__newindex(self, 'width', width)
        viewport_changed = true
    end

    if height ~= nil and get_public_value(self, 'height') ~= height then
        assert_number('Stage.height', height, 3)
        Container.__newindex(self, 'height', height)
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

    local children = rawget(node, '_children') or {}

    for index = 1, #children do
        prepare_layout_subtree(stage, children[index])
    end
end

local function run_layout_subtree(stage, node)
    if node._ui_layout_instance == true and
        type(node._run_layout_pass) == 'function' then
        node:_run_layout_pass(stage)
    end

    local children = rawget(node, '_children') or {}

    for index = 1, #children do
        run_layout_subtree(stage, children[index])
    end
end

Stage.__index = function(self, key)
    local method = rawget(Stage, key)

    if method ~= nil then
        return method
    end

    if STAGE_PUBLIC_KEYS[key] then
        if rawget(self, '_ui_stage_instance') == true and not self._destroyed then
            Stage._synchronize_for_read(self)
        end

        return get_public_value(self, key)
    end

    if key == 'baseSceneLayer' or key == 'overlayLayer' then
        return rawget(self, key)
    end

    local container_method = rawget(Container, key)

    if container_method ~= nil then
        return container_method
    end

    return nil
end

Stage.__newindex = function(self, key, value)
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

    if key == 'safeAreaInsets' then
        assert_not_destroyed(self, 2)
        local _, changed = set_safe_area_insets(self, value, 2)

        if changed then
            self:_mark_layout_subtree_dirty()
        end

        return
    end

    if key == 'width' or key == 'height' then
        assert_not_destroyed(self, 2)
        assert_number('Stage.' .. key, value, 2)
        local previous = get_public_value(self, key)
        Container.__newindex(self, key, value)
        refresh_environment_bounds(self)

        if previous ~= value then
            self:_mark_layout_subtree_dirty()
        end

        return
    end

    if rawget(self, '_allowed_public_keys')[key] then
        fail('Stage does not support prop "' .. tostring(key) .. '"', 2)
    end

    rawset(self, key, value)
end

function Stage.new(opts)
    opts = copy_options(opts)

    local host_width, host_height = read_host_viewport()

    if opts.width == nil then
        opts.width = host_width or 0
    end

    if opts.height == nil then
        opts.height = host_height or 0
    end

    assert_number('Stage.width', opts.width, 2)
    assert_number('Stage.height', opts.height, 2)

    if opts.safeAreaInsets == nil then
        opts.safeAreaInsets =
            read_host_safe_area_insets(opts.width, opts.height) or Insets.zero()
    end

    if active_stage ~= nil and not active_stage._destroyed then
        fail('creating more than one Stage instance is invalid', 2)
    end

    local self = {}

    Container._initialize(self, {
        width = opts.width,
        height = opts.height,
    }, {
        safeAreaInsets = true,
    })

    set_initial_safe_area_insets(self, opts.safeAreaInsets)

    rawset(self, '_ui_stage_instance', true)
    rawset(self, '_update_ran', false)
    rawset(self, '_last_input_delivery', nil)
    rawset(self, '_viewport_bounds_cache', Rectangle.new(0, 0, 0, 0))
    rawset(self, '_safe_area_bounds_cache', Rectangle.new(0, 0, 0, 0))
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

    refresh_environment_bounds(self)

    local base_scene_layer = Container.new({
        tag = 'base scene layer',
        width = 'fill',
        height = 'fill',
    })
    local overlay_layer = Container.new({
        tag = 'overlay layer',
        width = 'fill',
        height = 'fill',
    })

    rawset(self, 'baseSceneLayer', base_scene_layer)
    rawset(self, 'overlayLayer', overlay_layer)

    Container.addChild(self, base_scene_layer)
    Container.addChild(self, overlay_layer)

    active_stage = self

    return setmetatable(self, Stage)
end

function Stage.is_stage(value)
    return type(value) == 'table' and value._ui_stage_instance == true
end

function Stage:_sync_environment_from_host()
    assert_not_destroyed(self, 2)

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
    assert_not_destroyed(self, 2)

    local viewport = rawget(self, '_viewport_bounds_cache')
    local safe_area_bounds = rawget(self, '_safe_area_bounds_cache')
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
    assert_not_destroyed(self, 2)
    return self
end

function Stage:_set_focus_contract_internal(node, contract)
    assert_not_destroyed(self, 2)
    assert_container_node('node', node, 2)

    if contract == nil then
        rawset(node, '_focus_contract_internal', nil)
        self:_refresh_focus_runtime_state()
        return node
    end

    assert_table('contract', contract, 2)

    local normalized = {}

    if contract.scope ~= nil and type(contract.scope) ~= 'boolean' then
        fail('contract.scope must be a boolean or nil', 2)
    end

    if contract.trap ~= nil and type(contract.trap) ~= 'boolean' then
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

    rawset(node, '_focus_contract_internal', normalized)
    self:_refresh_focus_runtime_state()

    return node
end

function Stage:_set_focus_owner_internal(node)
    assert_not_destroyed(self, 2)

    if node ~= nil then
        assert_container_node('node', node, 2)

        if not is_descendant_or_same(self, node) or node._destroyed then
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
    assert_not_destroyed(self, 2)
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
    assert_not_destroyed(self, 2)

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

    local next_index = nil

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
    assert_not_destroyed(self, 2)

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
    assert_not_destroyed(self, 2)
    self:_synchronize_for_read()
    return get_stored_focus_owner(self)
end

function Stage:_get_active_focus_scope_chain_internal()
    assert_not_destroyed(self, 2)
    self:_synchronize_for_read()
    return copy_array(rawget(self, '_active_focus_scope_chain') or { self })
end

function Stage:_get_focus_trap_stack_internal()
    assert_not_destroyed(self, 2)
    self:_synchronize_for_read()
    return copy_array(rawget(self, '_focus_trap_stack') or {})
end

function Stage:_get_pre_trap_focus_history_internal()
    assert_not_destroyed(self, 2)
    self:_synchronize_for_read()
    return copy_array(rawget(self, '_pre_trap_focus_history') or {})
end

function Stage:_handle_attached_subtree(_, _)
    if self._destroyed then
        return self
    end

    self:_refresh_focus_runtime_state()
    return self
end

function Stage:_handle_detached_subtree(node, _)
    if self._destroyed then
        return self
    end

    local focus_owner = get_stored_focus_owner(self)
    local previous_owner = focus_owner

    if focus_owner ~= nil and is_descendant_or_same(node, focus_owner) then
        set_stored_focus_owner(self, nil)
    end

    self:_refresh_focus_runtime_state(previous_owner)
    return self
end

function Stage:_refresh_focus_runtime_state(previous_owner_override)
    if self._destroyed then
        return self
    end

    local previous_owner = previous_owner_override

    if previous_owner == nil then
        previous_owner = get_stored_focus_owner(self)
    end

    local focus_owner = get_stored_focus_owner(self)

    if not is_focus_owner_target(self, focus_owner) then
        focus_owner = nil
    end

    local active_traps = collect_active_focus_traps(self, self.overlayLayer, {})
    local previous_stack = rawget(self, '_focus_trap_stack') or {}
    local previous_history = rawget(self, '_pre_trap_focus_history') or {}
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

        if innermost_retained_trap == nil or
            is_descendant_or_same(innermost_retained_trap, restoration_candidate) then
            focus_owner = restoration_candidate
        end
    end

    if focus_owner ~= nil and #next_stack > 0 then
        local innermost_retained_trap = next_stack[#next_stack]

        if not is_descendant_or_same(innermost_retained_trap, focus_owner) then
            focus_owner = nil
        end
    end

    for index = prefix_length + 1, #active_traps do
        local trap = active_traps[index]

        next_stack[#next_stack + 1] = trap
        next_history[#next_history + 1] = focus_owner

        if focus_owner == nil or not is_descendant_or_same(trap, focus_owner) then
            focus_owner = resolve_scope_entry_focus_target(self, trap)
        end
    end

    if focus_owner ~= nil and #next_stack > 0 then
        local innermost_trap = next_stack[#next_stack]

        if not is_descendant_or_same(innermost_trap, focus_owner) then
            focus_owner = nil
        end
    end

    if focus_owner == nil and #next_stack > 0 then
        focus_owner = resolve_scope_entry_focus_target(self, next_stack[#next_stack])
    end

    if not is_focus_owner_target(self, focus_owner) then
        focus_owner = nil
    end

    rawset(self, '_focus_trap_stack', next_stack)
    rawset(self, '_pre_trap_focus_history', next_history)
    set_stored_focus_owner(self, focus_owner)

    local chain = { self }
    local seen = {
        [self] = true,
    }

    for index = 1, #next_stack do
        local scope = next_stack[index]

        if not seen[scope] then
            chain[#chain + 1] = scope
            seen[scope] = true
        end
    end

    if focus_owner ~= nil then
        local scope_path = {}
        local current = focus_owner

        while current ~= nil and current ~= self do
            if is_active_focus_scope_node(self, current) then
                scope_path[#scope_path + 1] = current
            end

            current = current.parent
        end

        for index = #scope_path, 1, -1 do
            local scope = scope_path[index]

            if not seen[scope] then
                if #next_stack == 0 or is_descendant_or_same(next_stack[#next_stack], scope) then
                    chain[#chain + 1] = scope
                    seen[scope] = true
                end
            end
        end
    end

    rawset(self, '_active_focus_scope_chain', chain)

    if previous_owner ~= focus_owner and focus_owner ~= nil then
        dispatch_focus_change_event(self, previous_owner, focus_owner)
    end

    return self
end

function Stage:_invalidate_update_token()
    if self._destroyed then
        return self
    end

    rawset(self, '_update_ran', false)
    return self
end

function Stage:_queue_state_change(callback)
    assert_not_destroyed(self, 2)

    if type(callback) ~= 'function' then
        fail('callback must be a function', 2)
    end

    local queue = rawget(self, '_queued_state_changes')
    local next_tail = queue.tail + 1

    queue.tail = next_tail
    queue.items[next_tail] = callback
    rawset(self, '_update_ran', false)

    return self
end

function Stage:_flush_queued_state_changes()
    assert_not_destroyed(self, 2)

    local queue = rawget(self, '_queued_state_changes')
    local processed = false

    while queue.head <= queue.tail do
        local index = queue.head
        local callback = queue.items[index]

        queue.items[index] = nil
        queue.head = index + 1
        processed = true

        callback()
    end

    if queue.head > queue.tail then
        queue.head = 1
        queue.tail = 0
    end

    return processed
end

function Stage:_mark_layout_subtree_dirty(node)
    assert_not_destroyed(self, 2)

    if node == nil then
        node = self
    end

    if node._ui_layout_instance == true then
        node._layout_dirty = true
    end

    local children = rawget(node, '_children') or {}

    for index = 1, #children do
        self:_mark_layout_subtree_dirty(children[index])
    end

    return self
end

function Stage:_run_layout_pass()
    assert_not_destroyed(self, 2)

    prepare_layout_subtree(self, self)
    run_layout_subtree(self, self)

    return self
end

function Stage:_synchronize_for_read(dt)
    assert_not_destroyed(self, 2)
    self:_sync_environment_from_host()

    while true do
        self:_run_layout_pass()
        Container.update(self, dt)

        if not self:_flush_queued_state_changes() then
            break
        end
    end

    self:_refresh_focus_runtime_state()
    refresh_hover_target(self)

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

function Stage:getSafeAreaBounds()
    self:_synchronize_for_read()
    return self._safe_area_bounds_cache:clone()
end

function Stage:resize(width, height, safe_area_insets)
    assert_not_destroyed(self, 2)
    assert_number('width', width, 2)
    assert_number('height', height, 2)

    if safe_area_insets == nil then
        safe_area_insets =
            read_host_safe_area_insets(width, height) or
                get_public_value(self, 'safeAreaInsets')
    end

    apply_environment(self, width, height, safe_area_insets)
    rawset(self, '_update_ran', false)
    return self
end

function Stage:update(dt)
    assert_not_destroyed(self, 2)
    self:_synchronize_for_read(dt)
    rawset(self, '_update_ran', true)
    return self
end

function Stage:_prepare_draw(graphics, draw_callback)
    assert_not_destroyed(self, 2)
    self:_sync_environment_from_host()

    if not self._update_ran then
        fail(TWO_PASS_VIOLATION, 2)
    end

    graphics, draw_callback = resolve_draw_args(graphics, draw_callback)
    rawset(self, '_update_ran', false)

    return graphics, draw_callback
end

function Stage:_draw_base_layer_resolved(graphics, draw_callback)
    assert_not_destroyed(self, 2)
    local focus_aware_draw = create_focus_aware_draw_callback(self, draw_callback)
    self.baseSceneLayer:_draw_subtree_resolved(
        graphics,
        function(node)
            focus_aware_draw(node, graphics)
        end
    )
    return self
end

function Stage:_draw_overlay_layer_resolved(graphics, draw_callback)
    assert_not_destroyed(self, 2)
    local focus_aware_draw = create_focus_aware_draw_callback(self, draw_callback)
    self.overlayLayer:_draw_subtree_resolved(
        graphics,
        function(node)
            focus_aware_draw(node, graphics)
        end
    )
    return self
end

function Stage:draw(graphics, draw_callback)
    graphics, draw_callback = self:_prepare_draw(graphics, draw_callback)

    self:_draw_base_layer_resolved(graphics, draw_callback)
    self:_draw_overlay_layer_resolved(graphics, draw_callback)

    return self
end

function Stage:resolveTarget(x, y)
    assert_not_destroyed(self, 2)
    assert_number('x', x, 2)
    assert_number('y', y, 2)

    self:_synchronize_for_read()
    return resolve_target_resolved(self, x, y)
end

function Stage:deliverInput(raw_event)
    assert_not_destroyed(self, 2)
    assert_table('raw_event', raw_event, 2)

    if type(raw_event.kind) ~= 'string' then
        fail('raw_event.kind must be a string', 2)
    end

    self:_synchronize_for_read()

    local intent = translate_raw_input(raw_event)
    local kind = raw_event.kind
    local event = nil
    local target = nil
    local path = nil

    if kind == 'mousepressed' or kind == 'touchpressed' then
        _, target, path = begin_pointer_sequence(self, raw_event)
    elseif kind == 'mousereleased' or kind == 'touchreleased' then
        local sequence, sequence_id = get_pointer_sequence(self, raw_event)

        if sequence ~= nil then
            target = sequence.target
            path = sequence.path

            if sequence.dragging then
                event = create_drag_event(sequence, raw_event, 'end')
            else
                event, target, path = create_pointer_activation_event(
                    self,
                    raw_event,
                    sequence
                )
            end

            clear_pointer_sequence(self, sequence_id)
        end

        if kind == 'mousereleased' then
            update_mouse_hover_target(self, raw_event.x, raw_event.y)
        end
    elseif kind == 'mousemoved' or kind == 'touchmoved' then
        local sequence = get_pointer_sequence(self, raw_event)

        if sequence ~= nil and type(raw_event.x) == 'number' and
            type(raw_event.y) == 'number' then
            sequence.lastX = raw_event.x
            sequence.lastY = raw_event.y
            target = sequence.target
            path = sequence.path

            local delta_x = raw_event.x - sequence.originX
            local delta_y = raw_event.y - sequence.originY

            if sequence.dragging then
                event = create_drag_event(sequence, raw_event, 'move')
            elseif delta_x * delta_x + delta_y * delta_y >= DRAG_THRESHOLD_SQUARED then
                sequence.dragging = true
                event = create_drag_event(sequence, raw_event, 'start')
            end
        elseif kind == 'mousemoved' then
            target, path = update_mouse_hover_target(self, raw_event.x, raw_event.y)
        end
    elseif kind == 'wheelmoved' or
        (kind == 'keypressed' and intent == 'Scroll') then
        event, target, path = create_scroll_event(self, raw_event)
    elseif kind == 'keypressed' and intent == 'Navigate' then
        event, target, path = create_navigation_event(self, raw_event)
    elseif kind == 'keypressed' and intent == 'Dismiss' then
        event, target, path = create_dismiss_event(self)
    elseif kind == 'keypressed' and intent == 'Submit' then
        event, target, path = create_submit_event(self)
    elseif kind == 'keypressed' and intent == 'Activate' then
        event, target, path = create_keyboard_activate_event(self)
    elseif kind == 'textinput' then
        event, target, path = create_text_input_event(self, raw_event)
    elseif kind == 'textedited' then
        event, target, path = create_text_compose_event(self, raw_event)
    elseif type(raw_event.x) == 'number' and type(raw_event.y) == 'number' then
        target, path = resolve_spatial_target(self, raw_event)
    end

    if event ~= nil and event.type == 'ui.activate' and event.pointerType ~= nil then
        apply_pointer_focus_coupling(self, event.target, 'before', event)
    end

    if event ~= nil then
        event = dispatch_event(event)

        if event.type == 'ui.navigate' then
            apply_navigation_focus_movement(self, event)
        elseif event.type == 'ui.activate' and event.pointerType ~= nil then
            apply_pointer_focus_coupling(self, event.target, 'after', event)
        end
    end

    local delivery = build_delivery(raw_event, intent, event, target, path)

    rawset(self, '_last_input_delivery', delivery)

    return delivery
end

function Stage:addChild(_)
    fail('Stage children are runtime-managed; mount content into baseSceneLayer or overlayLayer', 2)
end

function Stage:removeChild(_)
    fail('Stage children are runtime-managed; Stage layers cannot be removed directly', 2)
end

function Stage:destroy()
    if active_stage == self then
        active_stage = nil
    end

    Container.destroy(self)
end

return Stage
