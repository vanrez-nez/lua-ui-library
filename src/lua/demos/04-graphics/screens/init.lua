local screen_modules = {
    require('demos.04-graphics.screens.opacity'),
    require('demos.04-graphics.screens.blendmode'),
    require('demos.04-graphics.screens.render_effects'),
    require('demos.04-graphics.screens.shader'),
    require('demos.04-graphics.screens.texture_surfaces'),
    require('demos.04-graphics.screens.image'),
}

screen_modules.helpers = require('demos.common.drawable_screen_helpers')

return screen_modules
