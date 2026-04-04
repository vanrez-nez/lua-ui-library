local Hint = require('demos.common.hint')

local DemoInstruments = {}

local function has_insets(insets)
    return insets ~= nil
        and (insets.top ~= 0 or insets.right ~= 0 or insets.bottom ~= 0 or insets.left ~= 0)
end

local function append_inset_row(entries, helpers, label, insets)
    if not has_insets(insets) then
        return
    end

    entries[#entries + 1] = {
        label = label,
        badges = {
            helpers.badge('left', helpers.format_scalar(insets.left)),
            helpers.badge('top', helpers.format_scalar(insets.top)),
            helpers.badge('right', helpers.format_scalar(insets.right)),
            helpers.badge('bottom', helpers.format_scalar(insets.bottom)),
        },
    }
end

local function append_rect_row(entries, helpers, label, rect)
    entries[#entries + 1] = {
        label = label,
        badges = {
            helpers.badge('x', helpers.format_scalar(rect.x)),
            helpers.badge('y', helpers.format_scalar(rect.y)),
            helpers.badge('width', helpers.format_scalar(rect.width)),
            helpers.badge('height', helpers.format_scalar(rect.height)),
        },
    }
end

function DemoInstruments.decorate_drawable(node, style)
    rawset(node, '_demo_label', style.label)
    node.backgroundColor = style.fill
    node.borderColor = style.line
    node.borderWidth = 1
    Hint.set_hint_name(node, style.label)

    return node
end

function DemoInstruments.set_spacing_hint(node, helpers, type_label)
    helpers.set_hint(node, function(current)
        local bounds = current:getLocalBounds()
        local content = current:getContentRect()
        local entries = {
            {
                label = 'type',
                badges = {
                    helpers.badge(nil, type_label or 'Drawable'),
                },
            },
        }

        append_rect_row(entries, helpers, 'child.container', bounds)
        append_rect_row(entries, helpers, 'child.content', content)
        append_inset_row(entries, helpers, 'padding', current.padding)
        append_inset_row(entries, helpers, 'margin', current.margin)

        return entries
    end)
end

function DemoInstruments.to_world_rect(node, rect)
    local x, y = node:localToWorld(rect.x, rect.y)
    return {
        x = x,
        y = y,
        width = rect.width,
        height = rect.height,
    }
end

function DemoInstruments.has_insets(insets)
    return has_insets(insets)
end

return DemoInstruments
