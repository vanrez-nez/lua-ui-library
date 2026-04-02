local Container = require('lib.ui.core.container')
local Row = require('lib.ui.layout.row')
local ControlUtils = require('lib.ui.controls.control_utils')
local Types = require('lib.ui.utils.types')
local Assert = require('lib.ui.utils.assert')

local Modal = Container:extends('Modal')

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

local function get_effective_open(self)
    if self.open ~= nil then
        return self.open == true
    end

    return rawget(self, '_open_uncontrolled') == true
end

local function clear_children(node)
    local children = rawget(node, '_children') or {}

    for index = #children, 1, -1 do
        node:removeChild(children[index])
    end
end

local function request_open_change(self, next_value)
    next_value = next_value == true

    if self.open == nil then
        rawset(self, '_open_uncontrolled', next_value)
    end

    ControlUtils.call_if_function(self.onOpenChange, next_value)
end

local function should_close_from_backdrop(self)
    return self.dismissOnBackdrop == true and
        self.backdropDismissBehavior == 'close'
end

local function detach_overlay_root(self)
    local mounted_stage = rawget(self, '_mounted_stage')

    if mounted_stage == nil then
        return
    end

    local overlay_root = rawget(self, '_overlay_root')

    if overlay_root ~= nil then
        mounted_stage:_set_focus_contract_internal(overlay_root, nil)
    end

    if self.restoreFocus == false then
        local trap_stack = rawget(mounted_stage, '_focus_trap_stack') or {}
        local history = rawget(mounted_stage, '_pre_trap_focus_history') or {}

        for index = #trap_stack, 1, -1 do
            if trap_stack[index] == overlay_root then
                history[index] = nil
                break
            end
        end
    end

    if overlay_root ~= nil and overlay_root.parent ~= nil then
        overlay_root.parent:removeChild(overlay_root)
    end

    rawset(self, '_mounted_stage', nil)
    rawset(self, '_opened_once_for_mount', false)
    rawset(self, '_last_open_state', get_effective_open(self))
end

local function attach_overlay_root(self, stage)
    local overlay_root = rawget(self, '_overlay_root')

    if overlay_root.parent ~= stage.overlayLayer then
        stage.overlayLayer:addChild(overlay_root)
    end

    if self.trapFocus == true then
        stage:_set_focus_contract_internal(overlay_root, {
            scope = true,
            trap = true,
        })
    else
        stage:_set_focus_contract_internal(overlay_root, {
            scope = true,
        })
    end

    rawset(self, '_mounted_stage', stage)
    rawset(self, '_opened_once_for_mount', true)

    local on_opened = rawget(self, '_handle_overlay_opened_internal') or
        self._handle_overlay_opened_internal

    if Types.is_function(on_opened) then
        on_opened(self, stage)
    end
end

local function sync_overlay_geometry(self, stage)
    local overlay_frame = rawget(self, '_overlay_frame')
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

    rawset(self, '_ui_modal_control', true)
    rawset(self, '_open_uncontrolled', opts.open == true)
    rawset(self, '_mounted_stage', nil)
    rawset(self, '_opened_once_for_mount', false)

    local overlay_root = Container.new({
        tag = (self.tag and (self.tag .. '.overlay')) or 'modal.overlay',
        width = 'fill',
        height = 'fill',
        interactive = false,
    })
    local backdrop = Container.new({
        tag = (self.tag and (self.tag .. '.backdrop')) or 'modal.backdrop',
        width = 'fill',
        height = 'fill',
        interactive = true,
    })
    local overlay_frame = Container.new({
        tag = (self.tag and (self.tag .. '.frame')) or 'modal.frame',
        width = 0,
        height = 0,
        interactive = false,
    })
    local surface = Row.new({
        tag = (self.tag and (self.tag .. '.surface')) or 'modal.surface',
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
        align = 'stretch',
        justify = 'start',
    })
    local content_slot = Container.new({
        tag = (self.tag and (self.tag .. '.content')) or 'modal.content',
        width = 'fill',
        height = 'fill',
        interactive = false,
    })

    overlay_root:addChild(backdrop)
    overlay_root:addChild(overlay_frame)
    overlay_frame:addChild(surface)
    surface:addChild(content_slot)

    backdrop:_add_event_listener('ui.activate', function(event)
        if rawget(self, '_destroyed') then
            return
        end

        if should_close_from_backdrop(self) then
            request_open_change(self, false)
            event:stopPropagation()
            return
        end

        event:preventDefault()
        event:stopPropagation()
    end)

    overlay_root:_add_event_listener('ui.dismiss', function(event)
        if rawget(self, '_destroyed') then
            return
        end

        if self.dismissOnEscape == true then
            request_open_change(self, false)
            event:stopPropagation()
            return
        end

        event:preventDefault()
        event:stopPropagation()
    end)

    rawset(self, '_overlay_root', overlay_root)
    rawset(self, '_overlay_backdrop', backdrop)
    rawset(self, '_overlay_frame', overlay_frame)
    rawset(self, '_overlay_surface', surface)
    rawset(self, '_content_slot', content_slot)

    rawset(self, 'root', overlay_root)
    rawset(self, 'backdrop', backdrop)
    rawset(self, 'surface', surface)
    rawset(self, 'content', content_slot)

    if content ~= nil then
        self:addChild(content)
    end
end

function Modal.new(opts)
    return Modal(opts)
end

function Modal:addChild(child)
    return rawget(self, '_content_slot'):addChild(child)
end

function Modal:removeChild(child)
    return rawget(self, '_content_slot'):removeChild(child)
end

function Modal:removeAllChildren()
    clear_children(rawget(self, '_content_slot'))
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
    if rawget(self, '_destroyed') then
        return self
    end

    local stage = ControlUtils.find_stage(self)
    local mounted_stage = rawget(self, '_mounted_stage')
    local wants_open = get_effective_open(self)

    if mounted_stage ~= nil and mounted_stage ~= stage then
        detach_overlay_root(self)
        mounted_stage = nil
    end

    if not wants_open or stage == nil then
        if mounted_stage ~= nil then
            detach_overlay_root(self)
        end

        return self
    end

    sync_overlay_geometry(self, stage)

    if mounted_stage == nil then
        attach_overlay_root(self, stage)
    else
        if self.trapFocus == true then
            stage:_set_focus_contract_internal(rawget(self, '_overlay_root'), {
                scope = true,
                trap = true,
            })
        else
            stage:_set_focus_contract_internal(rawget(self, '_overlay_root'), {
                scope = true,
            })
        end
    end

    return self
end

function Modal:update(dt)
    local was_open = rawget(self, '_last_open_state')
    self:_sync_overlay_mount()
    Container.update(self, dt)
    local is_open = get_effective_open(self)
    if was_open ~= is_open then
        self:_raise_motion(is_open and 'open' or 'close', {
            defaultTarget = 'surface',
        })
    end
    rawset(self, '_last_open_state', is_open)
    return self
end

function Modal:destroy()
    if rawget(self, '_destroyed') then
        return
    end

    detach_overlay_root(self)

    if not rawget(rawget(self, '_overlay_root'), '_destroyed') then
        rawget(self, '_overlay_root'):destroy()
    end

    Container.destroy(self)
end

return Modal
