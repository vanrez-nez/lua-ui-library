package.path = '../../?.lua;../../?/init.lua;' .. package.path
require('demos.common.bootstrap').init()
local screen_modules = require('demos.05-controls.screens')
local run_demo = require('demos.00-common-base.main')

run_demo({
    profiling = {
        jit_prefix = 'controls-render',
        timing_prefix = 'controls-timing',
        memory_prefix = 'controls-memory',
    },
    screen_modules = screen_modules,
})
