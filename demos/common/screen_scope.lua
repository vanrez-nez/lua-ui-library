local ScreenScope = {}
ScreenScope.__index = ScreenScope

local function call_release(value)
    if value == nil then
        return
    end

    local release = value.release
    if type(release) == 'function' then
        pcall(release, value)
    end
end

function ScreenScope.new()
    return setmetatable({
        resources = {},
        cleanups = {},
        released = false,
    }, ScreenScope)
end

function ScreenScope:track(value)
    if value ~= nil then
        self.resources[#self.resources + 1] = value
    end
    return value
end

function ScreenScope:on_cleanup(fn)
    if type(fn) == 'function' then
        self.cleanups[#self.cleanups + 1] = fn
    end
    return fn
end

function ScreenScope:font(...)
    return self:track(love.graphics.newFont(...))
end

function ScreenScope:image(...)
    return self:track(love.graphics.newImage(...))
end

function ScreenScope:image_data(...)
    return self:track(love.image.newImageData(...))
end

function ScreenScope:canvas(...)
    return self:track(love.graphics.newCanvas(...))
end

function ScreenScope:shader(...)
    return self:track(love.graphics.newShader(...))
end

function ScreenScope:mesh(...)
    return self:track(love.graphics.newMesh(...))
end

function ScreenScope:quad(...)
    return self:track(love.graphics.newQuad(...))
end

function ScreenScope:source(...)
    return self:track(love.audio.newSource(...))
end

function ScreenScope:cleanup()
    if self.released then
        return
    end

    for index = #self.cleanups, 1, -1 do
        pcall(self.cleanups[index])
    end

    for index = #self.resources, 1, -1 do
        call_release(self.resources[index])
        self.resources[index] = nil
    end

    self.cleanups = {}
    self.resources = {}
    self.released = true
    collectgarbage('collect')
end

return ScreenScope
