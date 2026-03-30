local Assert = require('lib.ui.core.assert')

local Event = {}
Event.__index = Event

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

    if type(current_target.worldToLocal) ~= 'function' then
        return
    end

    local local_x, local_y = current_target:worldToLocal(self.x, self.y)

    rawset(self, 'localX', local_x)
    rawset(self, 'localY', local_y)
end

function Event.new(opts)
    opts = opts or {}
    Assert.table('opts', opts, 2)
    Assert.string('Event.type', opts.type, 2)
    Assert.number('Event.timestamp', opts.timestamp, 2)

    if opts.phase ~= nil and not VALID_PHASES[opts.phase] then
        Assert.fail('Event.phase must be "capture", "target", or "bubble"', 2)
    end

    local self = setmetatable({
        type = opts.type,
        phase = opts.phase,
        target = opts.target,
        currentTarget = opts.currentTarget,
        path = clone_path(opts.path),
        timestamp = opts.timestamp,
        defaultPrevented = opts.defaultPrevented == true,
        propagationStopped = opts.propagationStopped == true,
        immediatePropagationStopped = opts.immediatePropagationStopped == true,
        pointerType = opts.pointerType,
        x = opts.x,
        y = opts.y,
        localX = nil,
        localY = nil,
        button = opts.button,
        direction = opts.direction,
        navigationMode = opts.navigationMode,
        deltaX = opts.deltaX,
        deltaY = opts.deltaY,
        axis = opts.axis,
        dragPhase = opts.dragPhase,
        originX = opts.originX,
        originY = opts.originY,
        text = opts.text,
        rangeStart = opts.rangeStart,
        rangeEnd = opts.rangeEnd,
        previousTarget = opts.previousTarget,
        nextTarget = opts.nextTarget,
    }, Event)

    update_local_coordinates(self)

    return self
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
