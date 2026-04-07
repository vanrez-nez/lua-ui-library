package.path = '../../?.lua;../../?/init.lua;' .. package.path
require('demos.common.bootstrap').init()
local screen_modules = require('demos.02-shape.screens')
local run_demo = require('demos.00-common-base.main')

run_demo({
    screen_modules = screen_modules,
})
