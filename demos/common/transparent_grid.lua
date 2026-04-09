local DemoColors = require('demos.common.colors')
local UI = require('lib.ui')

local Drawable = UI.Drawable

local TransparentGrid = {}

local DEFAULT_CELL_SIZE = 18
local DEFAULT_PRIMARY_COLOR = DemoColors.names.slate_900
local DEFAULT_SECONDARY_COLOR = DemoColors.names.slate_800

local function fill_rect(graphics, color, x, y, width, height)
    if graphics == nil or type(graphics.setColor) ~= 'function' or type(graphics.rectangle) ~= 'function' then
        return
    end

    graphics.setColor(color)
    graphics.rectangle('fill', x, y, width, height)
end

local function draw_checkerboard(self, graphics)
    local bounds = self:getWorldBounds()
    local cell_size = rawget(self, '_grid_cell_size') or DEFAULT_CELL_SIZE
    local primary_color = rawget(self, '_grid_primary_color') or DEFAULT_PRIMARY_COLOR
    local secondary_color = rawget(self, '_grid_secondary_color') or DEFAULT_SECONDARY_COLOR

    if cell_size <= 0 or bounds.width <= 0 or bounds.height <= 0 then
        return
    end

    fill_rect(graphics, primary_color, bounds.x, bounds.y, bounds.width, bounds.height)

    local row_index = 0
    local y = bounds.y

    while y < bounds.y + bounds.height do
        local column_index = row_index % 2
        local x = bounds.x
        local cell_height = math.min(cell_size, (bounds.y + bounds.height) - y)

        while x < bounds.x + bounds.width do
            local cell_width = math.min(cell_size, (bounds.x + bounds.width) - x)

            if column_index == 1 then
                fill_rect(graphics, secondary_color, x, y, cell_width, cell_height)
            end

            x = x + cell_size
            column_index = (column_index + 1) % 2
        end

        y = y + cell_size
        row_index = row_index + 1
    end
end

function TransparentGrid.new(opts)
    opts = opts or {}

    local grid = Drawable.new({
        id = opts.id,
        internal = opts.internal,
        x = opts.x or 0,
        y = opts.y or 0,
        width = opts.width or 0,
        height = opts.height or 0,
        zIndex = opts.zIndex or 0,
        interactive = false,
        backgroundColor = nil,
        borderWidth = 0,
    })

    rawset(grid, '_grid_cell_size', opts.cellSize or DEFAULT_CELL_SIZE)
    rawset(grid, '_grid_primary_color', opts.primaryColor or DEFAULT_PRIMARY_COLOR)
    rawset(grid, '_grid_secondary_color', opts.secondaryColor or DEFAULT_SECONDARY_COLOR)
    rawset(grid, '_draw_control', draw_checkerboard)

    return grid
end

return TransparentGrid
