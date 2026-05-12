local DemoColors = require('demos.common.colors')

local Setup = {}

local function find_required(root, id)
    local node = root:findById(id, -1)
    if node == nil then
        error('bounds_setup: missing node "' .. id .. '"', 2)
    end

    return node
end

local function apply_box(helpers, node, label, fill_color, line_color)
    helpers.mark_box(node, label, fill_color, line_color)
    helpers.set_hint_fields(node, {
        rows = {
            { label = 'position', source = 'opts', keys = { 'x', 'y' } },
            { label = 'dimensions', source = 'opts', keys = { 'width', 'height' } },
            { label = 'bounds.local', source = 'local_bounds', keys = { 'x', 'y', 'w', 'h' } },
            { label = 'bounds.world', source = 'world_bounds', keys = { 'x', 'y', 'w', 'h' } },
        },
    })
end

function Setup.install(args)
    local helpers = args.helpers
    local root = args.root

    local parent = find_required(root, 'bounds-parent')
    local child_a = find_required(root, 'bounds-child-a')
    local child_b = find_required(root, 'bounds-child-b')
    local grandchild = find_required(root, 'bounds-grandchild')
    local offset_child = find_required(root, 'bounds-offset-child')

    apply_box(
        helpers,
        parent,
        'parent',
        DemoColors.rgba(DemoColors.roles.accent_blue_fill, 0.24),
        DemoColors.roles.accent_blue_line
    )
    apply_box(
        helpers,
        child_a,
        'child A',
        DemoColors.rgba(DemoColors.roles.accent_green_fill, 0.22),
        DemoColors.roles.accent_green_line
    )
    apply_box(
        helpers,
        child_b,
        'child B',
        DemoColors.rgba(DemoColors.roles.accent_cyan_fill, 0.22),
        DemoColors.roles.accent_cyan_line
    )
    apply_box(
        helpers,
        grandchild,
        'grandchild',
        DemoColors.rgba(DemoColors.roles.accent_amber_fill, 0.24),
        DemoColors.roles.accent_amber_line
    )
    apply_box(
        helpers,
        offset_child,
        'offset child',
        DemoColors.rgba(DemoColors.roles.accent_red_fill, 0.22),
        DemoColors.roles.accent_red_line
    )
end

return Setup
