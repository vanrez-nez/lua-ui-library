package.path = '../../?.lua;../../?/init.lua;' .. package.path
require('demos.common.bootstrap').init()
local screen_modules = require('demos.04-graphics.screens')
local run_demo = require('demos.00-common-base.main')

run_demo({
    profiling = {
        jit_prefix = 'graphics-render',
        timing_prefix = 'graphics-timing',
        memory_prefix = 'graphics-memory',
    },
    screen_modules = screen_modules,
})
