local Modal = require('lib.ui.controls.modal')
local Text = require('lib.ui.controls.text')
local Container = require('lib.ui.core.container')
local Column = require('lib.ui.layout.column')
local Row = require('lib.ui.layout.row')
local ControlUtils = require('lib.ui.controls.control_utils')
local Schema = require('lib.ui.utils.schema')
local AlertSchema = require('lib.ui.controls.alert_schema')
local Constants = require('lib.ui.core.constants')
local Types = require('lib.ui.utils.types')
local Assert = require('lib.ui.utils.assert')

local Alert = Modal:extends('Alert')

Alert.schema = Schema.create(Alert, AlertSchema)
Alert.schema:copy_from(Schema.create(Alert, Modal._schema))

local function set_alert_styling_context(node, part)
    if node == nil then
        return
    end

    node._styling_context = {
        component = 'alert',
        part = part,
    }
end

local function is_content_node(value)
    return Types.is_table(value) and value._ui_container_instance == true
end

local function can_construct_text()
    return love ~= nil and love.graphics ~= nil and
        Types.is_function(love.graphics.newFont)
end

local function coerce_text_node(value, tag)
    if value == nil then
        return nil
    end

    if Types.is_string(value) then
        if not can_construct_text() then
            local placeholder = Column.new({
                tag = tag,
                internal = true,
                width = 0,
                height = 0,
                interactive = false,
                focusable = false,
            })

            placeholder.text = value

            return placeholder
        end

        local text_node = Text.new({
            tag = tag,
            internal = true,
            text = value,
            width = 0,
            wrap = true,
        })
        return text_node
    end

    return value
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

    local title_node = coerce_text_node(opts.title, 'alert.title')
    local message_node = coerce_text_node(opts.message, 'alert.message')
    local actions_container = build_actions_container(opts.actions)
    set_alert_styling_context(title_node, 'title')
    set_alert_styling_context(message_node, 'message')
    set_alert_styling_context(actions_container, 'actions')

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

    layout:addChild(title_node)

    if message_node ~= nil then
        layout:addChild(message_node)
    end

    layout:addChild(actions_container)
    modal_opts.content = layout

    Modal.constructor(self, modal_opts)
    self.schema:define(AlertSchema)
    self.title = opts.title
    self.message = opts.message
    self.actions = opts.actions
    self.variant = opts.variant or Constants.INTENT_DEFAULT
    self.initialFocus = opts.initialFocus

    self._ui_alert_control = true
    self._title_node = title_node
    self._message_node = message_node
    self._actions_container = actions_container

    self.surface.role = Constants.ROLE_ALERT_DIALOG
    self.surface.accessibleName = Types.is_string(opts.title) and opts.title or nil
    self.surface._styling_context = {
        component = 'alert',
        part = 'surface',
    }
    self.backdrop._styling_context = {
        component = 'alert',
        part = 'backdrop',
    }
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

return Alert
