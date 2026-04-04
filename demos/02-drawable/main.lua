package.path = '../../?.lua;../../?/init.lua;' .. package.path
require('demos.common.bootstrap').init()
local screen_modules = require('demos.02-drawable.screens')
local run_demo = require('demos.00-common-base.main')

run_demo({
    profiling = {
        jit_prefix = 'drawable-render',
        timing_prefix = 'drawable-timing',
        memory_prefix = 'drawable-memory',
    },
    screen_modules = screen_modules,
})
