local Modal = require('lib.ui.controls.modal')
local Container = require('lib.ui.core.container')
local Drawable = require('lib.ui.core.drawable')
local Column = require('lib.ui.layout.column')
local Row = require('lib.ui.layout.row')
local ControlUtils = require('lib.ui.controls.control_utils')
local Schema = require('lib.ui.utils.schema')
local AlertSchema = require('lib.ui.controls.alert_schema')
local Constants = require('lib.ui.core.constants')
local Types = require('lib.ui.utils.types')
local Assert = require('lib.ui.utils.assert')
local StyleScope = require('lib.ui.render.style_scope')

local Alert = Modal:extends('Alert')
local ALERT_SCOPES = {
    surface = StyleScope.create('alert', 'surface'),
    backdrop = StyleScope.create('alert', 'backdrop'),
    title = StyleScope.create('alert', 'title'),
    message = StyleScope.create('alert', 'message'),
    actions = StyleScope.create('alert', 'actions')
}

Alert.schema = Schema.extend(Modal.schema, AlertSchema)

local function is_content_node(value)
    return Types.is_table(value) and value._ui_container_instance == true
end

local function build_actions_container(actions)
    if is_content_node(actions) then
        return actions
    end

    local container = Row.new({
        tag = 'alert.actions',
        internal = true,
        width = 0,
        height = 64,
        gap = 12,
        align = Constants.ALIGN_CENTER,
        justify = Constants.ALIGN_END,
    })

    if actions == nil then
        return container
    end

    local count = #actions

    for index = 1, count do
        container:addChild(actions[index])
    end

    return container
end

local function build_slot(part, child, variant)
    local slot = Drawable.new({
        tag = 'alert.' .. part,
        internal = true,
        width = Constants.SIZE_MODE_FILL,
        height = Constants.SIZE_MODE_CONTENT,
        interactive = false,
        focusable = false,
        style_scope = ALERT_SCOPES[part],
        style_variant = variant,
    })
    Container._allow_fill_from_parent(slot, { width = true })

    if child ~= nil then
        slot:addChild(child)
    end

    return slot
end

local function collect_action_nodes(node, out)
    if node == nil then
        return out
    end

    local is_action = node.focusable == true and (
        node._ui_button_control == true or
        node.onActivate ~= nil
    )

    if is_action then
        out[#out + 1] = node
    end

    local children = node._children

    for index = 1, #children do
        collect_action_nodes(children[index], out)
    end

    return out
end

local function resolve_initial_action(self, actions)
    local preferred = self.initialFocus

    if preferred ~= nil then
        for index = 1, #actions do
            local action = actions[index]
            local identifier = action.actionId or action.id or action.tag

            if identifier == preferred then
                return action
            end
        end
    end

    return actions[1]
end

function Alert:constructor(opts)
    opts = opts or {}
    Assert.table('opts', opts, 2)

    local modal_opts = ControlUtils.base_opts(opts, {
        safeAreaAware = true,
    })

    modal_opts.open = opts.open
    modal_opts.onOpenChange = opts.onOpenChange
    modal_opts.dismissOnBackdrop = opts.dismissOnBackdrop
    modal_opts.dismissOnEscape = opts.dismissOnEscape
    modal_opts.trapFocus = opts.trapFocus
    modal_opts.restoreFocus = opts.restoreFocus
    modal_opts.safeAreaAware = opts.safeAreaAware
    modal_opts.backdropDismissBehavior = opts.backdropDismissBehavior

    local title_node = ControlUtils.coerce_to_node(opts.title, 'alert.title')
    local message_node = ControlUtils.coerce_to_node(opts.message, 'alert.message')
    local actions_container = build_actions_container(opts.actions)
    local initial_variant = opts.variant or Constants.INTENT_DEFAULT
    local title_slot = build_slot('title', title_node, initial_variant)
    local message_slot = nil
    if message_node ~= nil then
        message_slot = build_slot('message', message_node, initial_variant)
    end
    local actions_slot = build_slot('actions', actions_container, initial_variant)

    local layout = Column.new({
        tag = 'alert.body',
        internal = true,
        width = Constants.SIZE_MODE_FILL,
        height = Constants.SIZE_MODE_FILL,
        gap = 16,
        align = Constants.ALIGN_STRETCH,
        justify = Constants.ALIGN_START,
    })
    Container._allow_fill_from_parent(layout, { width = true, height = true })

    layout:addChild(title_slot)

    if message_slot ~= nil then
        layout:addChild(message_slot)
    end

    layout:addChild(actions_slot)
    modal_opts.content = layout

    Modal.constructor(self, modal_opts)
    self.title = opts.title
    self.message = opts.message
    self.actions = opts.actions
    self.variant = initial_variant
    self.initialFocus = opts.initialFocus

    self._ui_alert_control = true
    self._title_node = title_node
    self._message_node = message_node
    self._actions_container = actions_container
    self._title_slot = title_slot
    self._message_slot = message_slot
    self._actions_slot = actions_slot
    self._last_pushed_variant = nil

    self.surface.role = Constants.ROLE_ALERT_DIALOG
    self.surface.accessibleName = Types.is_string(opts.title) and opts.title or nil
    self.surface:setStyleScope(ALERT_SCOPES.surface)
    self.backdrop:setStyleScope(ALERT_SCOPES.backdrop)
    self:_sync_style_variant()
end

function Alert.new(opts)
    return Alert(opts)
end

function Alert:_handle_overlay_opened_internal()
    local actions = collect_action_nodes(self._actions_container, {})

    if #actions == 0 then
        Assert.fail('Alert requires at least one action node.', 2)
    end

    local target = resolve_initial_action(self, actions)

    if target ~= nil then
        ControlUtils.request_focus(target)
    end
end

function Alert:_sync_style_variant()
    local variant = self.variant

    if variant == self._last_pushed_variant then
        return
    end

    if self._title_slot ~= nil then
        self._title_slot:setStyleVariant(variant)
    end

    if self._message_slot ~= nil then
        self._message_slot:setStyleVariant(variant)
    end

    if self._actions_slot ~= nil then
        self._actions_slot:setStyleVariant(variant)
    end

    if self.surface ~= nil then
        self.surface:setStyleVariant(variant)
    end

    if self.backdrop ~= nil then
        self.backdrop:setStyleVariant(variant)
    end

    self._last_pushed_variant = variant
end

function Alert:update(dt)
    Modal.update(self, dt)
    self:_sync_style_variant()
    return self
end

return Alert
