local Assert = require('lib.ui.utils.assert')
local Types = require('lib.ui.utils.types')
local Schema = require('lib.ui.utils.schema')
local ContainerSchema = require('lib.ui.core.container_schema')

local SCROLLABLE_CONTAINER_SCHEMA = Schema.merge(ContainerSchema, {
    scrollXEnabled = { type = 'boolean', default = false },
    scrollYEnabled = { type = 'boolean', default = true },
    momentum = { type = 'boolean', default = true },
    momentumDecay = {
        validate = function(key, value, ctx, level)
            Assert.number(key, value, level)
            if value <= 0 or value >= 1 then
                Assert.fail(key .. ' must be between 0 and 1 (exclusive)', level)
            end
            return value
        end,
        default = 0.95
    },
    overscroll = { type = 'boolean', default = false },
    scrollStep = {
        validate = function(key, value, ctx, level)
            Assert.number(key, value, level)
            if value <= 0 then
                Assert.fail(key .. ' must be greater than 0', level)
            end
            return value
        end,
        default = 40
    },
    showScrollbars = { type = 'boolean', default = true },
})

return SCROLLABLE_CONTAINER_SCHEMA
