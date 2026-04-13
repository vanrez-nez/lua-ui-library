local Object = require('lib.cls')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Utils = require('lib.ui.utils.common')

local EventDispatcher = Object:extends('EventDispatcher')

local VALID_EVENT_LISTENER_PHASES = {
    capture = true,
    bubble = true,
}

local function validate_listener_phase(phase, level)
    if not VALID_EVENT_LISTENER_PHASES[phase] then
        Assert.fail('listener phase must be "capture" or "bubble"', level or 1)
    end

    return phase
end

function EventDispatcher:constructor()
    rawset(self, '_event_listeners', {
        capture = {},
        bubble = {},
    })
    rawset(self, '_event_default_actions', {})
end

function EventDispatcher:_add_event_listener(event_type, listener, phase)
    Assert.string('event_type', event_type, 2)

    if not Types.is_function(listener) then
        Assert.fail('listener must be a function', 2)
    end

    phase = validate_listener_phase(phase or 'bubble', 2)

    local event_listeners = self._event_listeners
    local listeners_by_type = event_listeners[phase]
    local listeners = listeners_by_type[event_type]

    if listeners == nil then
        listeners = {}
        listeners_by_type[event_type] = listeners
    end

    listeners[#listeners + 1] = listener

    return listener
end

function EventDispatcher:_remove_event_listener(event_type, listener, phase)
    Assert.string('event_type', event_type, 2)

    if not Types.is_function(listener) then
        Assert.fail('listener must be a function', 2)
    end

    local phases = nil

    if phase == nil then
        phases = { 'capture', 'bubble' }
    else
        validate_listener_phase(phase, 2)
        phases = { phase }
    end

    local event_listeners = self._event_listeners
    for index = 1, #phases do
        local listeners = event_listeners[phases[index]][event_type]

        if listeners ~= nil then
            for listener_index = #listeners, 1, -1 do
                if listeners[listener_index] == listener then
                    table.remove(listeners, listener_index)
                end
            end

            if #listeners == 0 then
                event_listeners[phases[index]][event_type] = nil
            end
        end
    end

    return self
end

function EventDispatcher:_get_event_listener_snapshot(event_type, phase)
    Assert.string('event_type', event_type, 2)
    phase = validate_listener_phase(phase, 2)

    local event_listeners = self._event_listeners
    local listeners = event_listeners[phase][event_type]

    if listeners == nil then
        return {}
    end

    return Utils.copy_array(listeners)
end

function EventDispatcher:_set_event_default_action(event_type, handler)
    Assert.string('event_type', event_type, 2)

    if handler ~= nil and not Types.is_function(handler) then
        Assert.fail('handler must be a function or nil', 2)
    end

    local event_default_actions = self._event_default_actions
    event_default_actions[event_type] = handler

    return self
end

function EventDispatcher:_get_event_default_action(event_type)
    Assert.string('event_type', event_type, 2)
    local event_default_actions = self._event_default_actions
    return event_default_actions and event_default_actions[event_type]
end

return EventDispatcher
