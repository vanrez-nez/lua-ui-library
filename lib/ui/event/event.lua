local Assert = require('lib.ui.utils.assert')
local Object = require('lib.cls')
local Types = require('lib.ui.utils.types')

local Event = Object:extends('Event')

local VALID_PHASES = {
    capture = true,
    target = true,
    bubble = true,
}

local function clone_path(path)
    if path == nil then
        return nil
    end

    local copy = {}

    for index = 1, #path do
        copy[index] = path[index]
    end

    return copy
end

local function update_local_coordinates(self)
    rawset(self, 'localX', nil)
    rawset(self, 'localY', nil)

    if self.pointerType == nil or self.currentTarget == nil then
        return
    end

    local current_target = self.currentTarget

    if not Types.is_function(current_target.worldToLocal) then
        return
    end

    local local_x, local_y = current_target:worldToLocal(self.x, self.y)

    rawset(self, 'localX', local_x)
    rawset(self, 'localY', local_y)
end

function Event:constructor(opts)
    opts = opts or {}
    Assert.table('opts', opts, 3)
    Assert.string('Event.type', opts.type, 3)
    Assert.number('Event.timestamp', opts.timestamp, 3)

    if opts.phase ~= nil and not VALID_PHASES[opts.phase] then
        Assert.fail('Event.phase must be "capture", "target", or "bubble"', 3)
    end

    self.type = opts.type
    self.phase = opts.phase
    self.target = opts.target
    self.currentTarget = opts.currentTarget
    self.path = clone_path(opts.path)
    self.timestamp = opts.timestamp
    self.defaultPrevented = opts.defaultPrevented == true
    self.propagationStopped = opts.propagationStopped == true
    self.immediatePropagationStopped = opts.immediatePropagationStopped == true
    self.pointerType = opts.pointerType
    self.x = opts.x
    self.y = opts.y
    self.localX = nil
    self.localY = nil
    self.button = opts.button
    self.direction = opts.direction
    self.navigationMode = opts.navigationMode
    self.deltaX = opts.deltaX
    self.deltaY = opts.deltaY
    self.axis = opts.axis
    self.dragPhase = opts.dragPhase
    self.originX = opts.originX
    self.originY = opts.originY
    self.text = opts.text
    self.rangeStart = opts.rangeStart
    self.rangeEnd = opts.rangeEnd
    self.previousTarget = opts.previousTarget
    self.nextTarget = opts.nextTarget

    update_local_coordinates(self)
end

function Event.new(opts)
    return Event(opts)
end

function Event:stopPropagation()
    self.propagationStopped = true
    return self
end

function Event:stopImmediatePropagation()
    self.propagationStopped = true
    self.immediatePropagationStopped = true
    return self
end

function Event:preventDefault()
    self.defaultPrevented = true
    return self
end

function Event:_set_phase(phase)
    if phase ~= nil and not VALID_PHASES[phase] then
        Assert.fail('phase must be "capture", "target", or "bubble"', 2)
    end

    rawset(self, 'phase', phase)
    return self
end

function Event:_set_current_target(current_target)
    rawset(self, 'currentTarget', current_target)
    update_local_coordinates(self)
    return self
end

return Event
