local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')

local CanvasPool = {}
CanvasPool.__index = CanvasPool

local function bucket_size(value)
    value = math.max(1, math.floor(value or 1))
    return math.ceil(value / 64) * 64
end

function CanvasPool.new(opts)
    opts = opts or {}
    local self = setmetatable({}, CanvasPool)

    self.graphics = opts.graphics or (love and love.graphics) or {}
    self.buckets = {}
    self.owned = {}

    return self
end

function CanvasPool:acquire(width, height)
    Assert.number('width', width, 2)
    Assert.number('height', height, 2)

    local graphics = self.graphics

    if not Types.is_function(graphics.newCanvas) then
        error('canvas acquisition requires graphics.newCanvas', 2)
    end

    local bucket_w = bucket_size(width)
    local bucket_h = bucket_size(height)
    local key = tostring(bucket_w) .. 'x' .. tostring(bucket_h)
    local bucket = self.buckets[key]

    if bucket ~= nil and #bucket > 0 then
        local canvas = bucket[#bucket]
        bucket[#bucket] = nil
        self.owned[canvas] = key
        return canvas
    end

    local canvas = graphics.newCanvas(bucket_w, bucket_h)
    self.owned[canvas] = key
    return canvas
end

function CanvasPool:release(canvas)
    if canvas == nil then
        return nil
    end

    local key = self.owned[canvas]

    if key == nil then
        return nil
    end

    self.owned[canvas] = nil
    self.buckets[key] = self.buckets[key] or {}
    self.buckets[key][#self.buckets[key] + 1] = canvas

    return canvas
end

return CanvasPool
