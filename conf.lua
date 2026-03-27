function love.conf(t)
    t.identity = "lua-ui-library"
    t.version = "11.5"

    t.window.title = "Lua UI Library"
    t.window.width = 960
    t.window.height = 640
    t.window.resizable = true
    t.window.vsync = 1
    t.window.highdpi = false

    t.modules.joystick = false
    t.modules.physics = false
end
