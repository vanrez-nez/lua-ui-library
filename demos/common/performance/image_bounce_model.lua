local ImageBounceModel = {}
ImageBounceModel.__index = ImageBounceModel

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

function ImageBounceModel.new(opts)
    opts = opts or {}

    return setmetatable({
        items = {},
        item_width = opts.item_width or 50,
        item_height = opts.item_height or 50,
        spawn_jitter = opts.spawn_jitter or 30,
        min_speed = opts.min_speed or 120,
        max_speed = opts.max_speed or 240,
        create_item = opts.create_item,
        sync_item = opts.sync_item,
    }, ImageBounceModel)
end

function ImageBounceModel:_random_velocity()
    local angle = love.math.random() * (math.pi * 2)
    local speed = love.math.random(self.min_speed, self.max_speed)

    return math.cos(angle) * speed, math.sin(angle) * speed
end

function ImageBounceModel:add(count, bounds_width, bounds_height, spawn_x, spawn_y)
    local max_x = math.max(0, bounds_width - self.item_width)
    local max_y = math.max(0, bounds_height - self.item_height)

    for _ = 1, count do
        local x = spawn_x
        local y = spawn_y

        if x == nil then
            x = love.math.random(0, max_x)
        else
            x = clamp(x + love.math.random(-self.spawn_jitter, self.spawn_jitter), 0, max_x)
        end

        if y == nil then
            y = love.math.random(0, max_y)
        else
            y = clamp(y + love.math.random(-self.spawn_jitter, self.spawn_jitter), 0, max_y)
        end

        local velocity_x, velocity_y = self:_random_velocity()
        local item = nil

        if type(self.create_item) == 'function' then
            item = self.create_item(x, y, velocity_x, velocity_y)
        end

        if item == nil then
            item = {
                x = x,
                y = y,
                velocity_x = velocity_x,
                velocity_y = velocity_y,
            }
        end

        self.items[#self.items + 1] = item
    end
end

function ImageBounceModel:update(dt, bounds_width, bounds_height)
    local max_x = math.max(0, bounds_width - self.item_width)
    local max_y = math.max(0, bounds_height - self.item_height)

    for index = 1, #self.items do
        local item = self.items[index]
        local next_x = item.x + (item.velocity_x * dt)
        local next_y = item.y + (item.velocity_y * dt)

        if next_x <= 0 then
            next_x = 0
            item.velocity_x = math.abs(item.velocity_x)
        elseif next_x >= max_x then
            next_x = max_x
            item.velocity_x = -math.abs(item.velocity_x)
        end

        if next_y <= 0 then
            next_y = 0
            item.velocity_y = math.abs(item.velocity_y)
        elseif next_y >= max_y then
            next_y = max_y
            item.velocity_y = -math.abs(item.velocity_y)
        end

        item.x = next_x
        item.y = next_y

        if type(self.sync_item) == 'function' then
            self.sync_item(item)
        end
    end
end

function ImageBounceModel:count()
    return #self.items
end

return ImageBounceModel
