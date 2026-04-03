local Hint = require('demos.common.hint')

local DemoInstruments = {}

local function has_insets(insets)
    return insets ~= nil
        and (insets.top ~= 0 or insets.right ~= 0 or insets.bottom ~= 0 or insets.left ~= 0)
end

local function append_inset_groups(entries, helpers, label, insets)
    if not has_insets(insets) then
        return
    end

    entries[#entries + 1] = {
        label = label .. '.vertical',
        badges = {
            helpers.badge('top', helpers.format_scalar(insets.top)),
            helpers.badge('bottom', helpers.format_scalar(insets.bottom)),
        },
    }

    entries[#entries + 1] = {
        label = label .. '.horizontal',
        badges = {
            helpers.badge('left', helpers.format_scalar(insets.left)),
            helpers.badge('right', helpers.format_scalar(insets.right)),
        },
    }
end

function DemoInstruments.decorate_drawable(node, style)
    rawset(node, '_demo_box', true)
    rawset(node, '_demo_label', style.label)
    rawset(node, '_demo_fill_color', style.fill)
    rawset(node, '_demo_line_color', style.line)
    Hint.set_hint_name(node, style.label)

    return node
end

function DemoInstruments.set_spacing_hint(node, helpers)
    helpers.set_hint(node, function(current)
        local entries = {
            {
                label = 'container',
                badges = {
                    helpers.badge('bounds', helpers.format_rect(current:getLocalBounds())),
                },
            },
            {
                label = 'target',
                badges = {
                    helpers.badge('content', helpers.format_rect(current:getContentRect())),
                },
            },
        }

        append_inset_groups(entries, helpers, 'padding', current.padding)
        append_inset_groups(entries, helpers, 'margin', current.margin)

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
