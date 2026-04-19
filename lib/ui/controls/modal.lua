local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local ControlUtils = require('lib.ui.controls.control_utils')
local Constants = require('lib.ui.core.constants')
local Types = require('lib.ui.utils.types')
local Assert = require('lib.ui.utils.assert')
local StyleScope = require('lib.ui.render.style_scope')

local Modal = Container:extends('Modal')
local MODAL_BACKDROP_SCOPE = StyleScope.create('modal', 'backdrop')
local MODAL_SURFACE_SCOPE = StyleScope.create('modal', 'surface')

local MODAL_PUBLIC_KEYS = {
    open = {
        default = nil,
        validate = function(_, value, _, level)
            if value ~= nil then
                Assert.boolean('Modal.open', value, level or 1)
            end

            return value
        end,
    },
    onOpenChange = {
        default = nil,
        validate = function(_, value, _, level)
            if value ~= nil and not Types.is_function(value) then
                Assert.fail('Modal.onOpenChange must be a function or nil', level or 1)
            end

            return value
        end,
    },
    dismissOnBackdrop = {
        type = 'boolean',
        default = true,
    },
    dismissOnEscape = {
        type = 'boolean',
        default = true,
    },
    trapFocus = {
        type = 'boolean',
        default = true,
    },
    restoreFocus = {
        type = 'boolean',
        default = true,
    },
    safeAreaAware = {
        type = 'boolean',
        default = true,
    },
    backdropDismissBehavior = {
        default = 'close',
        validate = function(_, value, _, level)
            if value ~= 'close' and value ~= 'ignore' then
                Assert.fail(
                    'Modal.backdropDismissBehavior must be "close" or "ignore"',
                    level or 1
                )
            end

            return value
        end,
    },
}

Modal._schema = ControlUtils.extend_schema(Container._schema, MODAL_PUBLIC_KEYS)
Modal:implements(ControlUtils.overlay_mixin)

local function get_effective_open(self)
    if self.open ~= nil then
        return self.open == true
    end

    return self._open_uncontrolled == true
end

local function clear_children(node)
    local children = node._children

    for index = #children, 1, -1 do
        node:removeChild(children[index])
    end
end

local function request_open_change(self, next_value)
    next_value = next_value == true

    if self.open == nil then
        self._open_uncontrolled = next_value
    end

    ControlUtils.call_if_function(self.onOpenChange, next_value)
end

local function should_close_from_backdrop(self)
    return self.dismissOnBackdrop == true and
        self.backdropDismissBehavior == 'close'
end

function Modal:_before_overlay_detach(mounted_stage, overlay_root)
    if mounted_stage == nil then
        return
    end

    if overlay_root ~= nil then
        mounted_stage:_set_focus_contract_internal(overlay_root, nil)
    end

    if self.restoreFocus == false then
        local trap_stack = mounted_stage._focus_trap_stack
        local history = mounted_stage._pre_trap_focus_history

        for index = #trap_stack, 1, -1 do
            if trap_stack[index] == overlay_root then
                history[index] = nil
                break
            end
        end
    end
end

function Modal:_detach_overlay()
    ControlUtils.overlay_mixin._detach_overlay(self)
    self._opened_once_for_mount = false
    self._last_open_state = get_effective_open(self)
end

function Modal:_overlay_focus_contract()
    if self.trapFocus == true then
        return {
            scope = true,
            trap = true,
        }
    end

    return {
        scope = true,
    }
end

local function sync_overlay_geometry(self, stage)
    local overlay_frame = self._overlay_frame
    local viewport = stage:getViewport()
    local safe_area_bounds = stage:getSafeAreaBounds()
    local target_bounds = self.safeAreaAware and safe_area_bounds or viewport

    overlay_frame.x = target_bounds.x
    overlay_frame.y = target_bounds.y
    overlay_frame.width = target_bounds.width
    overlay_frame.height = target_bounds.height
end

function Modal:constructor(opts)
    opts = opts or {}
    Assert.table('opts', opts, 2)

    local content = opts.content
    local modal_opts = ControlUtils.base_opts(opts, {
        width = 0,
        height = 0,
        visible = false,
        interactive = false,
        focusable = false,
    })

    modal_opts.open = opts.open
    modal_opts.onOpenChange = opts.onOpenChange
    modal_opts.dismissOnBackdrop = opts.dismissOnBackdrop
    modal_opts.dismissOnEscape = opts.dismissOnEscape
    modal_opts.trapFocus = opts.trapFocus
    modal_opts.restoreFocus = opts.restoreFocus
    modal_opts.safeAreaAware = opts.safeAreaAware
    modal_opts.backdropDismissBehavior = opts.backdropDismissBehavior

    ControlUtils.assert_controlled_pair(
        'open',
        opts.open,
        'onOpenChange',
        opts.onOpenChange,
        2
    )

    Container.constructor(self, modal_opts, MODAL_PUBLIC_KEYS)
    self.open = opts.open
    self.onOpenChange = opts.onOpenChange
    if opts.dismissOnBackdrop ~= nil then self.dismissOnBackdrop = opts.dismissOnBackdrop end
    if opts.dismissOnEscape ~= nil then self.dismissOnEscape = opts.dismissOnEscape end
    if opts.trapFocus ~= nil then self.trapFocus = opts.trapFocus end
    if opts.restoreFocus ~= nil then self.restoreFocus = opts.restoreFocus end
    if opts.safeAreaAware ~= nil then self.safeAreaAware = opts.safeAreaAware end
    if opts.backdropDismissBehavior ~= nil then
        self.backdropDismissBehavior = opts.backdropDismissBehavior
    end

    self._ui_modal_control = true
    self._open_uncontrolled = opts.open == true
    self._mounted_stage = nil
    self._opened_once_for_mount = false

    local overlay_root = Container.new({
        tag = (self.tag and (self.tag .. '.overlay')) or 'modal.overlay',
        internal = true,
        width = 'fill',
        height = 'fill',
        interactive = false,
    })
    Container._allow_fill_from_parent(overlay_root, { width = true, height = true })
    local backdrop = Drawable.new({
        tag = (self.tag and (self.tag .. '.backdrop')) or 'modal.backdrop',
        internal = true,
        width = 'fill',
        height = 'fill',
        interactive = true,
        style_scope = MODAL_BACKDROP_SCOPE,
    })
    Container._allow_fill_from_parent(backdrop, { width = true, height = true })
    local overlay_frame = Container.new({
        tag = (self.tag and (self.tag .. '.frame')) or 'modal.frame',
        internal = true,
        width = 0,
        height = 0,
        interactive = false,
    })
    local surface = Drawable.new({
        tag = (self.tag and (self.tag .. '.surface')) or 'modal.surface',
        internal = true,
        width = '80%',
        height = '80%',
        minWidth = 160,
        minHeight = 80,
        maxWidth = 720,
        maxHeight = 520,
        anchorX = 0.5,
        anchorY = 0.5,
        pivotX = 0.5,
        pivotY = 0.5,
        interactive = false,
        focusable = false,
        padding = { 20, 20, 20, 20 },
        alignX = 'stretch',
        alignY = 'stretch',
        style_scope = MODAL_SURFACE_SCOPE,
    })
    surface.role = Constants.ROLE_DIALOG
    local content_slot = Container.new({
        tag = (self.tag and (self.tag .. '.content')) or 'modal.content',
        internal = true,
        width = 'fill',
        height = 0,
        interactive = false,
    })
    Container._allow_fill_from_parent(content_slot, { width = true, height = true })
    Container._allow_child_fill(content_slot, { width = true, height = true })

    overlay_root:addChild(backdrop)
    overlay_root:addChild(overlay_frame)
    overlay_frame:addChild(surface)
    surface:addChild(content_slot)

    ControlUtils.add_control_listener(self, backdrop, 'ui.activate', function(event)
        if should_close_from_backdrop(self) then
            request_open_change(self, false)
            event:stopPropagation()
            return
        end

        event:preventDefault()
        event:stopPropagation()
    end)

    ControlUtils.add_control_listener(self, overlay_root, 'ui.dismiss', function(event)
        if self.dismissOnEscape == true then
            request_open_change(self, false)
            event:stopPropagation()
            return
        end

        event:preventDefault()
        event:stopPropagation()
    end)

    self._overlay_root = overlay_root
    self._overlay_backdrop = backdrop
    self._overlay_frame = overlay_frame
    self._overlay_surface = surface
    self._content_slot = content_slot

    self.root = overlay_root
    self.backdrop = backdrop
    self.surface = surface
    self.content = content_slot

    if content ~= nil then
        self:addChild(content)
    end
end

function Modal.new(opts)
    return Modal(opts)
end

function Modal:addChild(child)
    return self._content_slot:addChild(child)
end

function Modal:removeChild(child)
    return self._content_slot:removeChild(child)
end

function Modal:removeAllChildren()
    clear_children(self._content_slot)
    return self
end

function Modal:isOpen()
    return get_effective_open(self)
end

function Modal:open_internal()
    request_open_change(self, true)
    return self
end

function Modal:close_internal()
    request_open_change(self, false)
    return self
end

function Modal:_sync_overlay_mount()
    local stage = ControlUtils.find_stage(self)
    local mounted_stage = self._mounted_stage
    local wants_open = get_effective_open(self)

    if mounted_stage ~= nil and mounted_stage ~= stage then
        self:_detach_overlay()
        mounted_stage = nil
    end

    if not wants_open or stage == nil then
        if mounted_stage ~= nil then
            self:_detach_overlay()
        end

        return self
    end

    sync_overlay_geometry(self, stage)

    if mounted_stage == nil then
        self:_attach_overlay(stage)
        self._opened_once_for_mount = true
    else
        stage:_set_focus_contract_internal(self._overlay_root, self:_overlay_focus_contract())
    end

    return self
end

function Modal:update(dt)
    local was_open = self._last_open_state
    self:_sync_overlay_mount()
    Container.update(self, dt)
    local is_open = get_effective_open(self)
    if was_open ~= is_open then
        self:_raise_motion(is_open and 'open' or 'close', {
            defaultTarget = 'surface',
        })
    end
    self._last_open_state = is_open
    return self
end

function Modal:on_destroy()
    ControlUtils.remove_control_listeners(self)
    self:_detach_overlay()

    self._overlay_root:destroy()

    Container.on_destroy(self)
end

return Modal
