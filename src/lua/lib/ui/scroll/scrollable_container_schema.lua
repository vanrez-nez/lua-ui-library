local Assert = require('lib.ui.utils.assert')
local Rule = require('lib.ui.utils.rule')
local ContainerSchema = require('lib.ui.core.container_schema')
local Utils = require('lib.ui.utils.common')

local function validate_momentum_decay(key, value, _, level)
    Assert.number(key, value, level)
    if value <= 0 or value >= 1 then
        Assert.fail(key .. ' must be between 0 and 1 (exclusive)', level)
    end
    return value
end

local function validate_scroll_step(key, value, _, level)
    Assert.number(key, value, level)
    if value <= 0 then
        Assert.fail(key .. ' must be greater than 0', level)
    end
    return value
end

local SCROLLABLE_CONTAINER_SCHEMA = Utils.merge_tables(Utils.copy_table(ContainerSchema), {
    scrollXEnabled = Rule.boolean(false),
    scrollYEnabled = Rule.boolean(true),
    momentum = Rule.boolean(true),
    momentumDecay = Rule.custom(validate_momentum_decay, { default = 0.95 }),
    overscroll = Rule.boolean(false),
    scrollStep = Rule.custom(validate_scroll_step, { default = 40 }),
    showScrollbars = Rule.boolean(true),
})

return SCROLLABLE_CONTAINER_SCHEMA
