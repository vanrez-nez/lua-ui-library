local Object = require('lib.cls')
local Assert = require('lib.ui.utils.assert')
local Texture = require('lib.ui.graphics.texture')

local Atlas = Object:extends('Atlas')

local function normalize_region(name, default_texture, region)
    Assert.table('Atlas region ' .. tostring(name), region, 3)

    local texture = region.texture or default_texture
    Assert.is_instance('Atlas region texture', texture, Texture, 'Texture', 3)

    local x = region.x or 0
    local y = region.y or 0
    local width = region.width
    local height = region.height

    Assert.number('Atlas region x', x, 3)
    Assert.number('Atlas region y', y, 3)
    Assert.number('Atlas region width', width, 3)
    Assert.number('Atlas region height', height, 3)

    if width <= 0 or height <= 0 then
        Assert.fail('Atlas region "' .. tostring(name) .. '" must have width/height > 0', 3)
    end

    return {
        name = name,
        texture = texture,
        x = x,
        y = y,
        width = width,
        height = height,
    }
end

function Atlas:constructor(opts)
    opts = opts or {}
    Assert.table('opts', opts, 2)

    local regions = opts.regions
    Assert.table('Atlas.regions', regions, 2)

    local default_texture = opts.texture
    if default_texture ~= nil then
        Assert.is_instance('Atlas.texture', default_texture, Texture, 'Texture', 2)
    end

    local normalized = {}
    for name, region in pairs(regions) do
        normalized[name] = normalize_region(name, default_texture, region)
    end

    self.texture = default_texture
    self.regions = normalized
end

function Atlas.new(opts)
    return Atlas(opts)
end

function Atlas:resolve(name)
    local region = self.regions[name]
    if region == nil then
        Assert.fail('Unknown atlas region "' .. tostring(name) .. '"', 2)
    end

    return {
        name = region.name,
        texture = region.texture,
        x = region.x,
        y = region.y,
        width = region.width,
        height = region.height,
    }
end

return Atlas
