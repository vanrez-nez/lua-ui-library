local Modal = require('lib.ui.controls.modal')
local Text = require('lib.ui.controls.text')
local Container = require('lib.ui.core.container')
local Column = require('lib.ui.layout.column')
local Row = require('lib.ui.layout.row')
local ControlUtils = require('lib.ui.controls.control_utils')
local Types = require('lib.ui.utils.types')
local Assert = require('lib.ui.utils.assert')

local Alert = Modal:extends('Alert')

local ALERT_PUBLIC_KEYS = {
    title = {
        default = nil,
        validate = function(_, value, _, level)
            if value == nil then
                return value
            end

            if Types.is_string(value) or Types.is_table(value) then
                return value
            end

            Assert.fail('Alert.title must be a string, content node, or nil', level or 1)
        end,
    },
    message = {
        default = nil,
        validate = function(_, value, _, level)
            if value == nil or Types.is_string(value) or Types.is_table(value) then
                return value
            end

            Assert.fail('Alert.message must be a string, content node, or nil', level or 1)
        end,
    },
    actions = {
        default = nil,
        validate = function(_, value, _, level)
            if value == nil or Types.is_table(value) then
                return value
            end

            Assert.fail('Alert.actions must be a container, list, or nil', level or 1)
        end,
    },
    variant = {
        default = 'default',
        validate = function(_, value, _, level)
            if value ~= 'default' and value ~= 'destructive' and
                value ~= 'success' and value ~= 'warning' then
                Assert.fail(
                    'Alert.variant must be "default", "destructive", "success", or "warning"',
                    level or 1
                )
            end

            return value
        end,
    },
    initialFocus = {
        default = nil,
        validate = function(_, value, _, level)
            if value ~= nil and not Types.is_string(value) then
                Assert.fail('Alert.initialFocus must be a string or nil', level or 1)
            end

            return value
        end,
    },
}

Alert._schema = ControlUtils.extend_schema(Modal._schema, ALERT_PUBLIC_KEYS)

local function is_content_node(value)
    return Types.is_table(value) and rawget(value, '_ui_container_instance') == true
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

            rawset(placeholder, 'text', value)

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

    if is_content_node(value) then
        return value
    end

    Assert.fail('Alert content must be a string or content node', 3)
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
        align = 'center',
        justify = 'end',
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
    if node == nil or rawget(node, '_destroyed') then
        return out
    end

    local is_action = node.focusable == true and (
        rawget(node, '_ui_button_control') == true or
        node.onActivate ~= nil
    )

    if is_action then
        out[#out + 1] = node
    end

    local children = rawget(node, '_children') or {}

    for index = 1, #children do
        collect_action_nodes(children[index], out)
    end

    return out
end

local function validate_title(value)
    if Types.is_string(value) then
        if value == '' then
            Assert.fail(
                'Alert title must be a non-empty string or a content node.',
                3
            )
        end

        return
    end

    if is_content_node(value) then
        return
    end

    Assert.fail(
        'Alert title must be a non-empty string or a content node.',
        3
    )
end

local function resolve_initial_action(self, actions)
    local preferred = self.initialFocus

    if preferred ~= nil then
        for index = 1, #actions do
            local action = actions[index]
            local identifier = rawget(action, 'actionId') or rawget(action, 'id') or action.tag

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
    validate_title(opts.title)

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
    local layout = Column.new({
        tag = 'alert.body',
        internal = true,
        width = 'fill',
        height = 'fill',
        gap = 16,
        align = 'stretch',
        justify = 'start',
    })
    Container._allow_fill_from_parent(layout, { width = true, height = true })

    layout:addChild(title_node)

    if message_node ~= nil then
        layout:addChild(message_node)
    end

    layout:addChild(actions_container)
    modal_opts.content = layout

    Modal.constructor(self, modal_opts)
    self.schema:define(ALERT_PUBLIC_KEYS)
    self.title = opts.title
    self.message = opts.message
    self.actions = opts.actions
    self.variant = opts.variant or 'default'
    self.initialFocus = opts.initialFocus

    rawset(self, '_ui_alert_control', true)
    rawset(self, '_title_node', title_node)
    rawset(self, '_message_node', message_node)
    rawset(self, '_actions_container', actions_container)

    rawset(self.surface, 'role', 'alertdialog')
    rawset(self.surface, 'accessibleName', Types.is_string(opts.title) and opts.title or nil)
end

function Alert.new(opts)
    return Alert(opts)
end

function Alert:_handle_overlay_opened_internal()
    local actions = collect_action_nodes(rawget(self, '_actions_container'), {})

    if #actions == 0 then
        Assert.fail('Alert requires at least one action node.', 2)
    end

    local target = resolve_initial_action(self, actions)

    if target ~= nil then
        ControlUtils.request_focus(target)
    end
end

return Alert
