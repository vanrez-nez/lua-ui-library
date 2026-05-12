package.path = '../../?.lua;../../?/init.lua;' .. package.path
require('demos.common.bootstrap').init()
local screen_modules = require('demos.06-performance.screens')
local run_demo = require('demos.00-common-base.main')

run_demo({
    profiling = {
        jit_prefix = 'performance-render',
        timing_prefix = 'performance-timing',
        memory_prefix = 'performance-memory',
    },
    screen_modules = screen_modules,
})
