local Assert = require('lib.ui.utils.assert')

local ContentFillGuard = {}

local function child_is_visible(child)
    local effective_values = rawget(child, '_effective_values')

    if effective_values == nil then
        return true
    end

    return effective_values.visible ~= false
end

function ContentFillGuard.assert_valid(kind, parent_values, children, axis_keys, level)
    parent_values = parent_values or {}
    children = children or {}
    axis_keys = axis_keys or {}

    for axis_index = 1, #axis_keys do
        local axis_key = axis_keys[axis_index]

        if parent_values[axis_key] == 'content' then
            for child_index = 1, #children do
                local child = children[child_index]
                local child_values = rawget(child, '_effective_values') or {}

                if child_is_visible(child) and child_values[axis_key] == 'fill' then
                    Assert.fail(
                        kind ..
                            ' has a circular measurement dependency because ' ..
                            axis_key ..
                            ' = "content" and a visible child has ' ..
                            axis_key ..
                            ' = "fill"',
                        level or 1
                    )
                end
            end
        end
    end
end

return ContentFillGuard
