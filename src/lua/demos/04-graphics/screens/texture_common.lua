local DemoColors = require('demos.common.colors')
local UI = require('lib.ui')

local Drawable = UI.Drawable
local Sprite = UI.Sprite

local TextureCommon = {}

local floor = math.floor

TextureCommon.IMAGE_PATH = 'assets/images/image.png'
TextureCommon.CELL_SIZE = 128

local function resolve_row_index(label)
    return string.byte(label) - string.byte('A')
end

local function make_region(row_start, column_start, row_end, column_end)
    local cell_size = TextureCommon.CELL_SIZE
    local start_row_index = resolve_row_index(row_start)
    local end_row_index = resolve_row_index(row_end)

    return {
        x = (column_start - 1) * cell_size,
        y = start_row_index * cell_size,
        width = ((column_end - column_start) + 1) * cell_size,
        height = ((end_row_index - start_row_index) + 1) * cell_size,
    }
end

TextureCommon.SOURCE_OPTIONS = {
    {
        label = 'Texture',
        kind = 'texture',
    },
    {
        label = 'Sprite',
        kind = 'sprite',
    },
}

TextureCommon.REGION_OPTIONS = {
    {
        label = 'A1',
        region = make_region('A', 1, 'A', 1),
    },
    {
        label = 'B2',
        region = make_region('B', 2, 'B', 2),
    },
    {
        label = 'D4:E5',
        region = make_region('D', 4, 'E', 5),
    },
    {
        label = 'E1:H2',
        region = make_region('E', 1, 'H', 2),
    },
    {
        label = 'C3:F6',
        region = make_region('C', 3, 'F', 6),
    },
}

TextureCommon.ALIGN_OPTIONS = {
    { label = 'Start', value = 'start' },
    { label = 'Center', value = 'center' },
    { label = 'End', value = 'end' },
}

TextureCommon.OFFSET_OPTIONS = {
    { label = '-100', value = -100 },
    { label = '-50', value = -50 },
    { label = '0', value = 0 },
    { label = '50', value = 50 },
    { label = '100', value = 100 },
}

TextureCommon.REPEAT_OPTIONS = {
    {
        label = 'Off',
        repeatX = false,
        repeatY = false,
    },
    {
        label = 'X',
        repeatX = true,
        repeatY = false,
    },
    {
        label = 'Y',
        repeatX = false,
        repeatY = true,
    },
    {
        label = 'XY',
        repeatX = true,
        repeatY = true,
    },
}

function TextureCommon.cycle_index(index, delta, total)
    local next_index = index + delta

    if next_index < 1 then
        return total
    end

    if next_index > total then
        return 1
    end

    return next_index
end

function TextureCommon.find_required(root, id, owner_name)
    local node = root:findById(id, -1)

    if node == nil then
        error((owner_name or 'texture_common') .. ': missing node "' .. id .. '"', 2)
    end

    return node
end

function TextureCommon.resolve_source(texture, source_option, region_option)
    if source_option.kind == 'texture' then
        return texture
    end

    return Sprite.new({
        texture = texture,
        region = region_option.region,
    })
end

function TextureCommon.describe_region(region)
    if region == nil then
        return 'full'
    end

    return string.format(
        'x=%d y=%d w=%d h=%d',
        region.x or 0,
        region.y or 0,
        region.width or 0,
        region.height or 0
    )
end

local function draw_preview(self, graphics)
    local image = rawget(self, '_demo_source_image')

    if image == nil or type(graphics.draw) ~= 'function' then
        return
    end

    local bounds = self:getWorldBounds()
    local image_width = type(image.getWidth) == 'function' and image:getWidth() or image.width or 0
    local image_height = type(image.getHeight) == 'function' and image:getHeight() or image.height or 0

    if image_width <= 0 or image_height <= 0 then
        return
    end

    local scale = math.min(bounds.width / image_width, bounds.height / image_height)
    local draw_width = image_width * scale
    local draw_height = image_height * scale
    local draw_x = bounds.x + floor((bounds.width - draw_width) * 0.5)
    local draw_y = bounds.y + floor((bounds.height - draw_height) * 0.5)
    local region = rawget(self, '_demo_preview_region') or {
        x = 0,
        y = 0,
        width = image_width,
        height = image_height,
    }

    if type(graphics.setColor) == 'function' then
        graphics.setColor(1, 1, 1, 1)
    end
    graphics.draw(image, draw_x, draw_y, 0, scale, scale)

    if type(graphics.rectangle) ~= 'function' then
        return
    end

    if type(graphics.setColor) == 'function' then
        graphics.setColor(DemoColors.roles.border_light)
    end
    graphics.rectangle('line', draw_x, draw_y, draw_width, draw_height)

    if type(graphics.setLineWidth) == 'function' then
        graphics.setLineWidth(2)
    end
    if type(graphics.setColor) == 'function' then
        graphics.setColor(DemoColors.roles.accent_amber_line)
    end
    graphics.rectangle(
        'line',
        draw_x + ((region.x or 0) * scale),
        draw_y + ((region.y or 0) * scale),
        (region.width or image_width) * scale,
        (region.height or image_height) * scale
    )
    if type(graphics.setLineWidth) == 'function' then
        graphics.setLineWidth(1)
    end
end

function TextureCommon.add_source_preview(root, id_prefix, width, height)
    local frame = Drawable.new({
        id = id_prefix .. '-frame',
        width = width,
        height = height,
        backgroundColor = nil,
        borderColor = DemoColors.names.slate_400,
        borderWidth = 1,
        borderDashLength = 10,
        borderStyle = 'rough',
        borderPattern = 'dashed',
    })
    local preview = Drawable.new({
        id = id_prefix,
        x = 12,
        y = 12,
        width = width - 24,
        height = height - 24,
        interactive = false,
        backgroundColor = DemoColors.roles.surface,
        borderColor = DemoColors.roles.border_light,
        borderWidth = 1,
    })

    rawset(preview, '_draw_control', draw_preview)
    frame:addChild(preview)
    root:addChild(frame)

    return frame, preview
end

function TextureCommon.set_preview_source(preview, texture, source_option, region_option)
    local region = nil

    if texture ~= nil then
        if source_option.kind == 'texture' then
            region = {
                x = 0,
                y = 0,
                width = texture:getWidth(),
                height = texture:getHeight(),
            }
        else
            region = region_option.region
        end

        rawset(preview, '_demo_source_image', texture:getDrawable())
    else
        rawset(preview, '_demo_source_image', nil)
    end

    rawset(preview, '_demo_preview_region', region)
end

return TextureCommon
