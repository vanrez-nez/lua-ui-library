local Object = require('lib.cls')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local Texture = Object:extends('Texture')

local function read_dimension(source, method_name, fallback_key)
    if source == nil then
        return nil
    end

    local method = source[method_name]
    if Types.is_function(method) then
        local ok, value = pcall(method, source)
        if ok and Types.is_number(value) then
            return value
        end
    end

    local value = source[fallback_key]
    if Types.is_number(value) then
        return value
    end

    return nil
end

function Texture:constructor(opts)
    opts = opts or {}
    Assert.table('opts', opts, 2)

    local source = opts.source
    if source == nil then
        Assert.fail('Texture.source is required', 2)
    end

    local width = opts.width or read_dimension(source, 'getWidth', 'width')
    local height = opts.height or read_dimension(source, 'getHeight', 'height')

    if not Types.is_number(width) or width <= 0 then
        Assert.fail('Texture width must resolve to a number > 0', 2)
    end

    if not Types.is_number(height) or height <= 0 then
        Assert.fail('Texture height must resolve to a number > 0', 2)
    end

    rawset(self, 'source', source)
    rawset(self, 'width', width)
    rawset(self, 'height', height)
    rawset(self, 'resolvedSourceIdentity', opts.resolvedSourceIdentity or source)
end

function Texture.new(opts)
    return Texture(opts)
end

function Texture:getWidth()
    return rawget(self, 'width')
end

function Texture:getHeight()
    return rawget(self, 'height')
end

function Texture:getDrawable()
    return rawget(self, 'source')
end

return Texture
