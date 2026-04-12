local Setup = {}

local FRAME_GAP_X = 30
local FRAME_GAP_Y = 34
local BOTTOM_GAP = 24

local CASES = {
    {
        id = 'image-contain',
        label = 'contain',
        source = 'Sprite',
    },
    {
        id = 'image-cover',
        label = 'cover',
        source = 'Sprite',
    },
    {
        id = 'image-stretch',
        label = 'stretch',
        source = 'Sprite',
    },
    {
        id = 'image-none-center',
        label = 'none / center',
        source = 'Sprite',
    },
    {
        id = 'image-none-start',
        label = 'none / start',
        source = 'Sprite',
    },
    {
        id = 'image-none-end',
        label = 'none / end',
        source = 'Sprite',
    },
    {
        id = 'image-texture-source',
        label = 'texture',
        source = 'Texture',
    },
    {
        id = 'image-nearest-detail',
        label = 'nearest detail',
        source = 'Sprite',
    },
    {
        id = 'image-transform',
        label = 'rotate + scale',
        source = 'Sprite',
    },
}

local function round(value)
    return math.floor((value or 0) + 0.5)
end

local function find_required(root, id)
    local node = root:findById(id, -1)

    if node == nil then
        error('image_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function set_panel_hint(helpers, frame, image, source_label)
    helpers.set_hint_name(frame, rawget(frame, '_demo_label') or 'Image')
    helpers.set_hint(frame, function()
        local content_rect = image:getContentRect()
        local draw_rect, region = image:resolveImageRect(content_rect)

        return {
            {
                label = 'source',
                badges = {
                    helpers.badge(nil, source_label),
                },
            },
            {
                label = 'image',
                badges = {
                    helpers.badge('fit', tostring(image.fit)),
                    helpers.badge('alignX', tostring(image.alignX)),
                    helpers.badge('alignY', tostring(image.alignY)),
                    helpers.badge('sampling', tostring(image.sampling)),
                },
            },
            {
                label = 'transform',
                badges = {
                    helpers.badge('scaleX', helpers.format_scalar(image.scaleX)),
                    helpers.badge('scaleY', helpers.format_scalar(image.scaleY)),
                    helpers.badge('rotation', helpers.format_scalar(image.rotation)),
                },
            },
            {
                label = 'image.rect',
                badges = {
                    helpers.badge('draw', helpers.format_rect(draw_rect)),
                    helpers.badge('region', helpers.format_rect(region)),
                },
            },
            {
                label = 'rect.content',
                badges = {
                    helpers.badge('content', helpers.format_rect(content_rect)),
                },
            },
        }
    end)
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root
    local stage = args.stage
    local frames = {}

    for index = 1, #CASES do
        local case = CASES[index]
        local frame = find_required(root, case.id .. '-frame')
        local image = find_required(root, case.id .. '-image')

        rawset(frame, '_demo_label', case.label)
        rawset(frame, '_demo_label_align', 'center')
        rawset(frame, '_demo_label_valign', 'start')
        rawset(frame, '_demo_label_inset_y', 10)

        set_panel_hint(helpers, frame, image, case.source)

        frames[#frames + 1] = frame
    end

    rawset(stage, '_demo_screen_hooks', {
        update = function()
            local frame = frames[1]
            local screen_width = stage.width
            local screen_height = stage.height
            local total_width = (frame.width * 3) + (FRAME_GAP_X * 2)
            local total_height = (frame.height * 3) + (FRAME_GAP_Y * 2)
            local base_x = round((screen_width - total_width) * 0.5)
            local base_y = round((screen_height - total_height - BOTTOM_GAP) * 0.5)

            for index = 1, #frames do
                local column = (index - 1) % 3
                local row = math.floor((index - 1) / 3)
                local current = frames[index]

                current.x = base_x + (column * (current.width + FRAME_GAP_X))
                current.y = base_y + (row * (current.height + FRAME_GAP_Y))
            end
        end,
    })
end

return Setup
