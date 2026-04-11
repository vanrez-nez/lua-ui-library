local CanvasPool = require('lib.ui.render.canvas_pool')

local CanvasPoolRegistry = {}

local canvas_pools = setmetatable({}, { __mode = 'k' })

function CanvasPoolRegistry.get_for(graphics_adapter)
    local pool = canvas_pools[graphics_adapter]

    if pool == nil then
        pool = CanvasPool.new({
            graphics = graphics_adapter,
        })
        canvas_pools[graphics_adapter] = pool
    end

    return pool
end

return CanvasPoolRegistry
