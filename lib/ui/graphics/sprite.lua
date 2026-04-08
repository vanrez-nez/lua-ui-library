local Object = require('lib.cls')
local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Texture = require('lib.ui.graphics.texture')
local Atlas = require('lib.ui.graphics.atlas')

local Sprite = Object:extends('Sprite')

local function warn(message)
    if print ~= nil then
        print('[ui.graphics] ' .. tostring(message))
    end
end

local function clip_region(texture, region)
    local max_width = texture:getWidth()
    local max_height = texture:getHeight()
    local x = region.x or 0
    local y = region.y or 0
    local width = region.width
    local height = region.height

    Assert.number('Sprite region width', width, 3)
    Assert.number('Sprite region height', height, 3)

    if width <= 0 or height <= 0 then
        Assert.fail('Sprite region width/height must be > 0', 3)
    end

    local clipped_x = math.max(0, math.min(x, max_width))
    local clipped_y = math.max(0, math.min(y, max_height))
    local clipped_right = math.max(clipped_x, math.min(x + width, max_width))
    local clipped_bottom = math.max(clipped_y, math.min(y + height, max_height))
    local clipped_width = clipped_right - clipped_x
    local clipped_height = clipped_bottom - clipped_y

    if clipped_width <= 0 or clipped_height <= 0 then
        Assert.fail('Sprite region clips to zero area', 3)
    end

    if clipped_x ~= x or clipped_y ~= y or clipped_width ~= width or clipped_height ~= height then
        warn('sprite region clipped to texture bounds')
    end

    return {
        x = clipped_x,
        y = clipped_y,
        width = clipped_width,
        height = clipped_height,
    }
end

function Sprite:constructor(opts)
    opts = opts or {}
    Assert.table('opts', opts, 2)

    local texture = opts.texture
    local region = opts.region

    if opts.atlas ~= nil then
        Assert.is_instance('Sprite.atlas', opts.atlas, Atlas, 'Atlas', 2)
        if not Types.is_string(region) then
            Assert.fail('Sprite.region must be a string when atlas is supplied', 2)
        end
        local resolved = opts.atlas:resolve(region)
        texture = resolved.texture
        region = resolved
    end

    Assert.is_instance('Sprite.texture', texture, Texture, 'Texture', 2)

    if region == nil then
        region = {
            x = 0,
            y = 0,
            width = texture:getWidth(),
            height = texture:getHeight(),
        }
    elseif not Types.is_table(region) then
        Assert.fail('Sprite.region must be a table, string atlas key, or nil', 2)
    end

    local clipped = clip_region(texture, region)

    rawset(self, 'texture', texture)
    rawset(self, 'region', clipped)
    rawset(self, 'width', clipped.width)
    rawset(self, 'height', clipped.height)
end

function Sprite.new(opts)
    return Sprite(opts)
end

function Sprite:getWidth()
    return rawget(self, 'width')
end

function Sprite:getHeight()
    return rawget(self, 'height')
end

function Sprite:getIntrinsicDimensions()
    return self:getWidth(), self:getHeight()
end

function Sprite:getTexture()
    return rawget(self, 'texture')
end

function Sprite:getRegion()
    local region = rawget(self, 'region')
    return {
        x = region.x,
        y = region.y,
        width = region.width,
        height = region.height,
    }
end

return Sprite
