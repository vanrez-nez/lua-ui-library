local screen_modules = {
    require('demos.04-graphics.screens.opacity'),
    require('demos.04-graphics.screens.blendmode'),
    require('demos.04-graphics.screens.render_effects'),
    require('demos.04-graphics.screens.texture_background'),
    require('demos.04-graphics.screens.texture_fill'),
}

screen_modules.helpers = require('demos.common.drawable_screen_helpers')

return screen_modules
