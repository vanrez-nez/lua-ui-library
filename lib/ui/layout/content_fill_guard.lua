local Assert = require('lib.ui.utils.assert')
local Constants = require('lib.ui.core.constants')

local ContentFillGuard = {}

local function child_is_visible(child)
    return child.visible ~= false
end

function ContentFillGuard.assert_valid(kind, parent_values, children, axis_keys, level)
    parent_values = parent_values or {}
    children = children or {}
    axis_keys = axis_keys or {}

    for axis_index = 1, #axis_keys do
        local axis_key = axis_keys[axis_index]

        if parent_values[axis_key] == Constants.SIZE_MODE_CONTENT then
            for child_index = 1, #children do
                local child = children[child_index]

                if child_is_visible(child) and child[axis_key] == Constants.SIZE_MODE_FILL then
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
