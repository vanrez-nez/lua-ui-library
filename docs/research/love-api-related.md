# LÖVE UI-Related API

Source: https://love2d-community.github.io/love-api/ (love-api 11.5)

## Callbacks
```text
love.load( arg, unfilteredArg ): This function is called exactly once at the beginning of the game
love.update( dt ): Callback function used to update the state of the game every frame
love.draw(): Callback function used to draw on the screen every frame
love.focus( focus ): Callback function triggered when window receives or loses focus
love.mousefocus( focus ): Callback function triggered when window receives or loses mouse focus
love.keypressed( key, scancode, isrepeat ): Callback function triggered when a key is pressed
love.keypressed( key, isrepeat ): Callback function triggered when a key is pressed
love.keyreleased( key, scancode ): Callback function triggered when a keyboard key is released
love.textinput( text ): Called when text has been entered by the user
love.textedited( text, start, length ): Called when the candidate text for an IME (Input Method Editor) has changed
love.mousemoved( x, y, dx, dy, istouch ): Callback function triggered when the mouse is moved
love.mousepressed( x, y, button, istouch, presses ): Callback function triggered when a mouse button is pressed
love.mousereleased( x, y, button, istouch, presses ): Callback function triggered when a mouse button is released
love.wheelmoved( x, y ): Callback function triggered when the mouse wheel is moved
love.touchmoved( id, x, y, dx, dy, pressure ): Callback function triggered when a touch press moves inside the touch screen
love.touchpressed( id, x, y, dx, dy, pressure ): Callback function triggered when the touch screen is touched
love.touchreleased( id, x, y, dx, dy, pressure ): Callback function triggered when the touch screen stops being touched
love.resize( w, h ): Called when the window is resized, for example if the user resizes the window, or if love.window.setMode is called with an unsupported width or height in fullscreen and the window chooses the closest appropriate size
love.visible( visible ): Callback function triggered when window is minimized/hidden or unminimized by the user
love.quit(): Callback function triggered when the game is closed
```

## Keyboard
```text
love.keyboard.getKeyFromScancode( scancode ): Gets the key corresponding to the given hardware scancode
love.keyboard.getScancodeFromKey( key ): Gets the hardware scancode corresponding to the given key
love.keyboard.hasKeyRepeat(): Gets whether key repeat is enabled
love.keyboard.hasScreenKeyboard(): Gets whether screen keyboard is supported
love.keyboard.hasTextInput(): Gets whether text input events are enabled
love.keyboard.isDown( key ): Checks whether a certain key is down
love.keyboard.isDown( key, ... ): Checks whether a certain key is down
love.keyboard.isScancodeDown( scancode, ... ): Checks whether the specified Scancodes are pressed
love.keyboard.setKeyRepeat( enable ): Enables or disables key repeat for love.keypressed
love.keyboard.setTextInput( enable ): Enables or disables text input events
love.keyboard.setTextInput( enable, x, y, w, h ): Enables or disables text input events
```

## Mouse
```text
love.mouse.getCursor(): Gets the current Cursor
love.mouse.getPosition(): Returns the current position of the mouse
love.mouse.getRelativeMode(): Gets whether relative mode is enabled for the mouse
love.mouse.getSystemCursor( ctype ): Gets a Cursor object representing a system-native hardware cursor
love.mouse.getX(): Returns the current x-position of the mouse
love.mouse.getY(): Returns the current y-position of the mouse
love.mouse.isCursorSupported(): Gets whether cursor functionality is supported
love.mouse.isDown( button, ... ): Checks whether a certain mouse button is down
love.mouse.isGrabbed(): Checks if the mouse is grabbed
love.mouse.isVisible(): Checks if the cursor is visible
love.mouse.newCursor( imageData, hotx, hoty ): Creates a new hardware Cursor object from an image file or ImageData
love.mouse.newCursor( filename, hotx, hoty ): Creates a new hardware Cursor object from an image file or ImageData
love.mouse.newCursor( fileData, hotx, hoty ): Creates a new hardware Cursor object from an image file or ImageData
love.mouse.setCursor( cursor ): Sets the current mouse cursor
love.mouse.setCursor(): Sets the current mouse cursor
love.mouse.setGrabbed( grab ): Grabs the mouse and confines it to the window
love.mouse.setPosition( x, y ): Sets the current position of the mouse
love.mouse.setRelativeMode( enable ): Sets whether relative mode is enabled for the mouse
love.mouse.setVisible( visible ): Sets the current visibility of the cursor
love.mouse.setX( x ): Sets the current X position of the mouse
love.mouse.setY( y ): Sets the current Y position of the mouse
Cursor:getType(): Gets the type of the Cursor
```

## Touch
```text
love.touch.getPosition( id ): Gets the current position of the specified touch-press, in pixels
love.touch.getPressure( id ): Gets the current pressure of the specified touch-press
love.touch.getTouches(): Gets a list of all active touch-presses
```

## Window
```text
love.window.close(): Closes the window
love.window.fromPixels( pixelvalue ): Converts a number from pixels to density-independent units
love.window.fromPixels( px, py ): Converts a number from pixels to density-independent units
love.window.getDPIScale(): Gets the DPI scale factor associated with the window
love.window.getDesktopDimensions( displayindex ): Gets the width and height of the desktop
love.window.getDisplayCount(): Gets the number of connected monitors
love.window.getDisplayName( displayindex ): Gets the name of a display
love.window.getDisplayOrientation( displayindex ): Gets current device display orientation
love.window.getFullscreen(): Gets whether the window is fullscreen
love.window.getFullscreenModes( displayindex ): Gets a list of supported fullscreen modes
love.window.getIcon(): Gets the window icon
love.window.getMode(): Gets the display mode and properties of the window
love.window.getPosition(): Gets the position of the window on the screen
love.window.getSafeArea(): Gets area inside the window which is known to be unobstructed by a system title bar, the iPhone X notch, etc
love.window.getTitle(): Gets the window title
love.window.getVSync(): Gets current vertical synchronization (vsync)
love.window.hasFocus(): Checks if the game window has keyboard focus
love.window.hasMouseFocus(): Checks if the game window has mouse focus
love.window.isDisplaySleepEnabled(): Gets whether the display is allowed to sleep while the program is running
love.window.isMaximized(): Gets whether the Window is currently maximized
love.window.isMinimized(): Gets whether the Window is currently minimized
love.window.isOpen(): Checks if the window is open
love.window.isVisible(): Checks if the game window is visible
love.window.maximize(): Makes the window as large as possible
love.window.minimize(): Minimizes the window to the system's task bar / dock
love.window.requestAttention( continuous ): Causes the window to request the attention of the user if it is not in the foreground
love.window.restore(): Restores the size and position of the window if it was minimized or maximized
love.window.setDisplaySleepEnabled( enable ): Sets whether the display is allowed to sleep while the program is running
love.window.setFullscreen( fullscreen ): Enters or exits fullscreen
love.window.setFullscreen( fullscreen, fstype ): Enters or exits fullscreen
love.window.setIcon( imagedata ): Sets the window icon until the game is quit
love.window.setMode( width, height, flags ): Sets the display mode and properties of the window
love.window.setPosition( x, y, displayindex ): Sets the position of the window on the screen
love.window.setTitle( title ): Sets the window title
love.window.setVSync( vsync ): Sets vertical synchronization mode
love.window.showMessageBox( title, message, type, attachtowindow ): Displays a message box dialog above the love window
love.window.showMessageBox( title, message, buttonlist, type, attachtowindow ): Displays a message box dialog above the love window
love.window.toPixels( value ): Converts a number from density-independent units to pixels
love.window.toPixels( x, y ): Converts a number from density-independent units to pixels
love.window.updateMode( width, height, settings ): Sets the display mode and properties of the window, without modifying unspecified properties
```

## System
```text
love.system.getClipboardText(): Gets text from the clipboard
love.system.setClipboardText( text ): Puts text in the clipboard
love.system.openURL( url ): Opens a URL with the user's web or file browser
```

## Transforms And Color
```text
love.math.colorFromBytes( rb, gb, bb, ab ): Converts a color from 0..255 to 0..1 range
love.math.colorToBytes( r, g, b, a ): Converts a color from 0..1 to 0..255 range
love.math.gammaToLinear( r, g, b ): Converts a color from gamma-space (sRGB) to linear-space (RGB)
love.math.gammaToLinear( color ): Converts a color from gamma-space (sRGB) to linear-space (RGB)
love.math.gammaToLinear( c ): Converts a color from gamma-space (sRGB) to linear-space (RGB)
love.math.linearToGamma( lr, lg, lb ): Converts a color from linear-space (RGB) to gamma-space (sRGB)
love.math.linearToGamma( color ): Converts a color from linear-space (RGB) to gamma-space (sRGB)
love.math.linearToGamma( lc ): Converts a color from linear-space (RGB) to gamma-space (sRGB)
love.math.newTransform(): Creates a new Transform object
love.math.newTransform( x, y, angle, sx, sy, ox, oy, kx, ky ): Creates a new Transform object
Transform:apply( other ): Applies the given other Transform object to this one
Transform:clone(): Creates a new copy of this Transform
Transform:getMatrix(): Gets the internal 4x4 transformation matrix stored by this Transform
Transform:inverse(): Creates a new Transform containing the inverse of this Transform
Transform:inverseTransformPoint( localX, localY ): Applies the reverse of the Transform object's transformation to the given 2D position
Transform:isAffine2DTransform(): Checks whether the Transform is an affine transformation
Transform:reset(): Resets the Transform to an identity state
Transform:rotate( angle ): Applies a rotation to the Transform's coordinate system
Transform:scale( sx, sy ): Scales the Transform's coordinate system
Transform:setMatrix( e1_1, e1_2, e1_3, e1_4, e2_1, e2_2, e2_3, e2_4, e3_1, e3_2, e3_3, e3_4, e4_1, e4_2, e4_3, e4_4 ): Directly sets the Transform's internal 4x4 transformation matrix
Transform:setMatrix( layout, e1_1, e1_2, e1_3, e1_4, e2_1, e2_2, e2_3, e2_4, e3_1, e3_2, e3_3, e3_4, e4_1, e4_2, e4_3, e4_4 ): Directly sets the Transform's internal 4x4 transformation matrix
Transform:setMatrix( layout, matrix ): Directly sets the Transform's internal 4x4 transformation matrix
Transform:setTransformation( x, y, angle, sx, sy, ox, oy, kx, ky ): Resets the Transform to the specified transformation parameters
Transform:shear( kx, ky ): Applies a shear factor (skew) to the Transform's coordinate system
Transform:transformPoint( globalX, globalY ): Applies the Transform object's transformation to the given 2D position
Transform:translate( dx, dy ): Applies a translation to the Transform's coordinate system
```

## Graphics
```text
love.graphics.applyTransform( transform ): Applies the given Transform object to the current coordinate transformation
love.graphics.arc( drawmode, x, y, radius, angle1, angle2, segments ): Draws a filled or unfilled arc at position (x, y)
love.graphics.arc( drawmode, arctype, x, y, radius, angle1, angle2, segments ): Draws a filled or unfilled arc at position (x, y)
love.graphics.circle( mode, x, y, radius ): Draws a circle
love.graphics.circle( mode, x, y, radius, segments ): Draws a circle
love.graphics.clear(): Clears the screen or active Canvas to the specified color
love.graphics.clear( r, g, b, a, clearstencil, cleardepth ): Clears the screen or active Canvas to the specified color
love.graphics.clear( color, ..., clearstencil, cleardepth ): Clears the screen or active Canvas to the specified color
love.graphics.clear( clearcolor, clearstencil, cleardepth ): Clears the screen or active Canvas to the specified color
love.graphics.draw( drawable, x, y, r, sx, sy, ox, oy, kx, ky ): Draws a Drawable object (an Image, Canvas, SpriteBatch, ParticleSystem, Mesh, Text object, or Video) on the screen with optional rotation, scaling and shearing
love.graphics.draw( texture, quad, x, y, r, sx, sy, ox, oy, kx, ky ): Draws a Drawable object (an Image, Canvas, SpriteBatch, ParticleSystem, Mesh, Text object, or Video) on the screen with optional rotation, scaling and shearing
love.graphics.draw( drawable, transform ): Draws a Drawable object (an Image, Canvas, SpriteBatch, ParticleSystem, Mesh, Text object, or Video) on the screen with optional rotation, scaling and shearing
love.graphics.draw( texture, quad, transform ): Draws a Drawable object (an Image, Canvas, SpriteBatch, ParticleSystem, Mesh, Text object, or Video) on the screen with optional rotation, scaling and shearing
love.graphics.ellipse( mode, x, y, radiusx, radiusy ): Draws an ellipse
love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments ): Draws an ellipse
love.graphics.getBackgroundColor(): Gets the current background color
love.graphics.getBlendMode(): Gets the blending mode
love.graphics.getCanvas(): Gets the current target Canvas
love.graphics.getColor(): Gets the current color
love.graphics.getColorMask(): Gets the active color components used when drawing
love.graphics.getDPIScale(): Gets the DPI scale factor of the window
love.graphics.getDefaultFilter(): Returns the default scaling filters used with Images, Canvases, and Fonts
love.graphics.getDimensions(): Gets the width and height in pixels of the window
love.graphics.getFont(): Gets the current Font object
love.graphics.getHeight(): Gets the height in pixels of the window
love.graphics.getLineJoin(): Gets the line join style
love.graphics.getLineStyle(): Gets the line style
love.graphics.getLineWidth(): Gets the current line width
love.graphics.getPixelDimensions(): Gets the width and height in pixels of the window
love.graphics.getPixelHeight(): Gets the height in pixels of the window
love.graphics.getPixelWidth(): Gets the width in pixels of the window
love.graphics.getPointSize(): Gets the point size
love.graphics.getScissor(): Gets the current scissor box
love.graphics.getShader(): Gets the current Shader
love.graphics.getStackDepth(): Gets the current depth of the transform / state stack (the number of pushes without corresponding pops)
love.graphics.getStencilTest(): Gets the current stencil test configuration
love.graphics.getWidth(): Gets the width in pixels of the window
love.graphics.intersectScissor( x, y, width, height ): Sets the scissor to the rectangle created by the intersection of the specified rectangle with the existing scissor
love.graphics.inverseTransformPoint( screenX, screenY ): Converts the given 2D position from screen-space into global coordinates
love.graphics.isActive(): Gets whether the graphics module is able to be used
love.graphics.line( x1, y1, x2, y2, ... ): Draws lines between points
love.graphics.line( points ): Draws lines between points
love.graphics.newCanvas(): Creates a new Canvas object for offscreen rendering
love.graphics.newCanvas( width, height ): Creates a new Canvas object for offscreen rendering
love.graphics.newCanvas( width, height, settings ): Creates a new Canvas object for offscreen rendering
love.graphics.newCanvas( width, height, layers, settings ): Creates a new Canvas object for offscreen rendering
love.graphics.newFont( filename ): Creates a new Font from a TrueType Font or BMFont file
love.graphics.newFont( filename, size, hinting, dpiscale ): Creates a new Font from a TrueType Font or BMFont file
love.graphics.newFont( filename, imagefilename ): Creates a new Font from a TrueType Font or BMFont file
love.graphics.newFont( size, hinting, dpiscale ): Creates a new Font from a TrueType Font or BMFont file
love.graphics.newImage( filename, settings ): Creates a new Image from a filepath, FileData, an ImageData, or a CompressedImageData, and optionally generates or specifies mipmaps for the image
love.graphics.newImage( fileData, settings ): Creates a new Image from a filepath, FileData, an ImageData, or a CompressedImageData, and optionally generates or specifies mipmaps for the image
love.graphics.newImage( imageData, settings ): Creates a new Image from a filepath, FileData, an ImageData, or a CompressedImageData, and optionally generates or specifies mipmaps for the image
love.graphics.newImage( compressedImageData, settings ): Creates a new Image from a filepath, FileData, an ImageData, or a CompressedImageData, and optionally generates or specifies mipmaps for the image
love.graphics.newImageFont( filename, glyphs ): Creates a new specifically formatted image
love.graphics.newImageFont( imageData, glyphs ): Creates a new specifically formatted image
love.graphics.newImageFont( filename, glyphs, extraspacing ): Creates a new specifically formatted image
love.graphics.newQuad( x, y, width, height, sw, sh ): Creates a new Quad
love.graphics.newQuad( x, y, width, height, texture ): Creates a new Quad
love.graphics.newShader( code ): Creates a new Shader object for hardware-accelerated vertex and pixel effects
love.graphics.newShader( pixelcode, vertexcode ): Creates a new Shader object for hardware-accelerated vertex and pixel effects
love.graphics.newSpriteBatch( image, maxsprites ): Creates a new SpriteBatch object
love.graphics.newSpriteBatch( image, maxsprites, usage ): Creates a new SpriteBatch object
love.graphics.newSpriteBatch( texture, maxsprites, usage ): Creates a new SpriteBatch object
love.graphics.newText( font, textstring ): Creates a new drawable Text object
love.graphics.newText( font, coloredtext ): Creates a new drawable Text object
love.graphics.origin(): Resets the current coordinate transformation
love.graphics.points( x, y, ... ): Draws one or more points
love.graphics.points( points ): Draws one or more points
love.graphics.polygon( mode, ... ): Draw a polygon
love.graphics.polygon( mode, vertices ): Draw a polygon
love.graphics.pop(): Pops the current coordinate transformation from the transformation stack
love.graphics.present(): Displays the results of drawing operations on the screen
love.graphics.print( text, x, y, r, sx, sy, ox, oy, kx, ky ): Draws text on screen
love.graphics.print( coloredtext, x, y, angle, sx, sy, ox, oy, kx, ky ): Draws text on screen
love.graphics.print( text, transform ): Draws text on screen
love.graphics.print( coloredtext, transform ): Draws text on screen
love.graphics.print( text, font, transform ): Draws text on screen
love.graphics.print( coloredtext, font, transform ): Draws text on screen
love.graphics.printf( text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky ): Draws formatted text, with word wrap and alignment
love.graphics.printf( text, font, x, y, limit, align, r, sx, sy, ox, oy, kx, ky ): Draws formatted text, with word wrap and alignment
love.graphics.printf( text, transform, limit, align ): Draws formatted text, with word wrap and alignment
love.graphics.printf( text, font, transform, limit, align ): Draws formatted text, with word wrap and alignment
love.graphics.printf( coloredtext, x, y, limit, align, angle, sx, sy, ox, oy, kx, ky ): Draws formatted text, with word wrap and alignment
love.graphics.printf( coloredtext, font, x, y, limit, align, angle, sx, sy, ox, oy, kx, ky ): Draws formatted text, with word wrap and alignment
love.graphics.printf( coloredtext, transform, limit, align ): Draws formatted text, with word wrap and alignment
love.graphics.printf( coloredtext, font, transform, limit, align ): Draws formatted text, with word wrap and alignment
love.graphics.push(): Copies and pushes the current coordinate transformation to the transformation stack
love.graphics.push( stack ): Copies and pushes the current coordinate transformation to the transformation stack
love.graphics.rectangle( mode, x, y, width, height ): Draws a rectangle
love.graphics.rectangle( mode, x, y, width, height, rx, ry, segments ): Draws a rectangle
love.graphics.replaceTransform( transform ): Replaces the current coordinate transformation with the given Transform object
love.graphics.reset(): Resets the current graphics settings
love.graphics.rotate( angle ): Rotates the coordinate system in two dimensions
love.graphics.scale( sx, sy ): Scales the coordinate system in two dimensions
love.graphics.setBackgroundColor( red, green, blue, alpha ): Sets the background color
love.graphics.setBackgroundColor( rgba ): Sets the background color
love.graphics.setBlendMode( mode ): Sets the blending mode
love.graphics.setBlendMode( mode, alphamode ): Sets the blending mode
love.graphics.setCanvas( canvas, mipmap ): Captures drawing operations to a Canvas
love.graphics.setCanvas(): Captures drawing operations to a Canvas
love.graphics.setCanvas( canvas1, canvas2, ... ): Captures drawing operations to a Canvas
love.graphics.setCanvas( canvas, slice, mipmap ): Captures drawing operations to a Canvas
love.graphics.setCanvas( setup ): Captures drawing operations to a Canvas
love.graphics.setColor( red, green, blue, alpha ): Sets the color used for drawing
love.graphics.setColor( rgba ): Sets the color used for drawing
love.graphics.setColorMask( red, green, blue, alpha ): Sets the color mask
love.graphics.setColorMask(): Sets the color mask
love.graphics.setDefaultFilter( min, mag, anisotropy ): Sets the default scaling filters used with Images, Canvases, and Fonts
love.graphics.setFont( font ): Set an already-loaded Font as the current font or create and load a new one from the file and size
love.graphics.setLineJoin( join ): Sets the line join style
love.graphics.setLineStyle( style ): Sets the line style
love.graphics.setLineWidth( width ): Sets the line width
love.graphics.setNewFont( size ): Creates and sets a new Font
love.graphics.setNewFont( filename, size ): Creates and sets a new Font
love.graphics.setNewFont( file, size ): Creates and sets a new Font
love.graphics.setNewFont( data, size ): Creates and sets a new Font
love.graphics.setNewFont( rasterizer ): Creates and sets a new Font
love.graphics.setPointSize( size ): Sets the point size
love.graphics.setScissor( x, y, width, height ): Sets or disables scissor
love.graphics.setScissor(): Sets or disables scissor
love.graphics.setShader( shader ): Sets or resets a Shader as the current pixel effect or vertex shaders
love.graphics.setShader(): Sets or resets a Shader as the current pixel effect or vertex shaders
love.graphics.setStencilTest( comparemode, comparevalue ): Configures or disables stencil testing
love.graphics.setStencilTest(): Configures or disables stencil testing
love.graphics.shear( kx, ky ): Shears the coordinate system
love.graphics.stencil( stencilfunction, action, value, keepvalues ): Draws geometry as a stencil
love.graphics.transformPoint( globalX, globalY ): Converts the given 2D position from global coordinates into screen-space
love.graphics.translate( dx, dy ): Translates the coordinate system in two dimensions
```

## Graphics Types
```text
Canvas:generateMipmaps(): Generates mipmaps for the Canvas, based on the contents of the highest-resolution mipmap level
Canvas:getMSAA(): Gets the number of multisample antialiasing (MSAA) samples used when drawing to the Canvas
Canvas:getMipmapMode(): Gets the MipmapMode this Canvas was created with
Canvas:newImageData(): Generates ImageData from the contents of the Canvas
Canvas:newImageData( slice, mipmap, x, y, width, height ): Generates ImageData from the contents of the Canvas
Canvas:renderTo( func, ... ): Render to the Canvas using a function
Font:getAscent(): Gets the ascent of the Font
Font:getBaseline(): Gets the baseline of the Font
Font:getDPIScale(): Gets the DPI scale factor of the Font
Font:getDescent(): Gets the descent of the Font
Font:getFilter(): Gets the filter mode for a font
Font:getHeight(): Gets the height of the Font
Font:getKerning( leftchar, rightchar ): Gets the kerning between two characters in the Font
Font:getKerning( leftglyph, rightglyph ): Gets the kerning between two characters in the Font
Font:getLineHeight(): Gets the line height
Font:getWidth( text ): Determines the maximum width (accounting for newlines) taken by the given string
Font:getWrap( text, wraplimit ): Gets formatting information for text, given a wrap limit
Font:getWrap( coloredtext, wraplimit ): Gets formatting information for text, given a wrap limit
Font:hasGlyphs( text ): Gets whether the Font can render a character or string
Font:hasGlyphs( character1, character2 ): Gets whether the Font can render a character or string
Font:hasGlyphs( codepoint1, codepoint2 ): Gets whether the Font can render a character or string
Font:setFallbacks( fallbackfont1, ... ): Sets the fallback fonts
Font:setFilter( min, mag, anisotropy ): Sets the filter mode for a font
Font:setLineHeight( height ): Sets the line height
Image:isCompressed(): Gets whether the Image was created from CompressedData
Image:isFormatLinear(): Gets whether the Image was created with the linear (non-gamma corrected) flag set to true
Image:replacePixels( data, slice, mipmap, x, y, reloadmipmaps ): Replace the contents of an Image
Quad:getTextureDimensions(): Gets reference texture dimensions initially specified in love.graphics.newQuad
Quad:getViewport(): Gets the current viewport of this Quad
Quad:setViewport( x, y, w, h, sw, sh ): Sets the texture coordinates according to a viewport
Shader:getWarnings(): Returns any warning and error messages from compiling the shader code
Shader:hasUniform( name ): Gets whether a uniform / extern variable exists in the Shader
Shader:send( name, number, ... ): Sends one or more values to a special (uniform) variable inside the shader
Shader:send( name, vector, ... ): Sends one or more values to a special (uniform) variable inside the shader
Shader:send( name, matrix, ... ): Sends one or more values to a special (uniform) variable inside the shader
Shader:send( name, texture ): Sends one or more values to a special (uniform) variable inside the shader
Shader:send( name, boolean, ... ): Sends one or more values to a special (uniform) variable inside the shader
Shader:send( name, matrixlayout, matrix, ... ): Sends one or more values to a special (uniform) variable inside the shader
Shader:send( name, data, offset, size ): Sends one or more values to a special (uniform) variable inside the shader
Shader:send( name, data, matrixlayout, offset, size ): Sends one or more values to a special (uniform) variable inside the shader
Shader:send( name, matrixlayout, data, offset, size ): Sends one or more values to a special (uniform) variable inside the shader
Shader:sendColor( name, color, ... ): Sends one or more colors to a special (extern / uniform) vec3 or vec4 variable inside the shader
SpriteBatch:add( x, y, r, sx, sy, ox, oy, kx, ky ): Adds a sprite to the batch
SpriteBatch:add( quad, x, y, r, sx, sy, ox, oy, kx, ky ): Adds a sprite to the batch
SpriteBatch:addLayer( layerindex, x, y, r, sx, sy, ox, oy, kx, ky ): Adds a sprite to a batch created with an Array Texture
SpriteBatch:addLayer( layerindex, quad, x, y, r, sx, sy, ox, oy, kx, ky ): Adds a sprite to a batch created with an Array Texture
SpriteBatch:addLayer( layerindex, transform ): Adds a sprite to a batch created with an Array Texture
SpriteBatch:addLayer( layerindex, quad, transform ): Adds a sprite to a batch created with an Array Texture
SpriteBatch:attachAttribute( name, mesh ): Attaches a per-vertex attribute from a Mesh onto this SpriteBatch, for use when drawing
SpriteBatch:clear(): Removes all sprites from the buffer
SpriteBatch:flush(): Immediately sends all new and modified sprite data in the batch to the graphics card
SpriteBatch:getBufferSize(): Gets the maximum number of sprites the SpriteBatch can hold
SpriteBatch:getColor(): Gets the color that will be used for the next add and set operations
SpriteBatch:getCount(): Gets the number of sprites currently in the SpriteBatch
SpriteBatch:getTexture(): Gets the texture (Image or Canvas) used by the SpriteBatch
SpriteBatch:set( spriteindex, x, y, r, sx, sy, ox, oy, kx, ky ): Changes a sprite in the batch
SpriteBatch:set( spriteindex, quad, x, y, r, sx, sy, ox, oy, kx, ky ): Changes a sprite in the batch
SpriteBatch:setColor( r, g, b, a ): Sets the color that will be used for the next add and set operations
SpriteBatch:setColor(): Sets the color that will be used for the next add and set operations
SpriteBatch:setDrawRange( start, count ): Restricts the drawn sprites in the SpriteBatch to a subset of the total
SpriteBatch:setDrawRange(): Restricts the drawn sprites in the SpriteBatch to a subset of the total
SpriteBatch:setLayer( spriteindex, layerindex, x, y, r, sx, sy, ox, oy, kx, ky ): Changes a sprite previously added with add or addLayer, in a batch created with an Array Texture
SpriteBatch:setLayer( spriteindex, layerindex, quad, x, y, r, sx, sy, ox, oy, kx, ky ): Changes a sprite previously added with add or addLayer, in a batch created with an Array Texture
SpriteBatch:setLayer( spriteindex, layerindex, transform ): Changes a sprite previously added with add or addLayer, in a batch created with an Array Texture
SpriteBatch:setLayer( spriteindex, layerindex, quad, transform ): Changes a sprite previously added with add or addLayer, in a batch created with an Array Texture
SpriteBatch:setTexture( texture ): Sets the texture (Image or Canvas) used for the sprites in the batch, when drawing
Text:add( textstring, x, y, angle, sx, sy, ox, oy, kx, ky ): Adds additional colored text to the Text object at the specified position
Text:add( coloredtext, x, y, angle, sx, sy, ox, oy, kx, ky ): Adds additional colored text to the Text object at the specified position
Text:addf( textstring, wraplimit, align, x, y, angle, sx, sy, ox, oy, kx, ky ): Adds additional formatted / colored text to the Text object at the specified position
Text:addf( coloredtext, wraplimit, align, x, y, angle, sx, sy, ox, oy, kx, ky ): Adds additional formatted / colored text to the Text object at the specified position
Text:clear(): Clears the contents of the Text object
Text:getDimensions(): Gets the width and height of the text in pixels
Text:getDimensions( index ): Gets the width and height of the text in pixels
Text:getFont(): Gets the Font used with the Text object
Text:getHeight(): Gets the height of the text in pixels
Text:getHeight( index ): Gets the height of the text in pixels
Text:getWidth(): Gets the width of the text in pixels
Text:getWidth( index ): Gets the width of the text in pixels
Text:set( textstring ): Replaces the contents of the Text object with a new unformatted string
Text:set( coloredtext ): Replaces the contents of the Text object with a new unformatted string
Text:setFont( font ): Replaces the Font used with the text
Text:setf( textstring, wraplimit, align ): Replaces the contents of the Text object with a new formatted string
Text:setf( coloredtext, wraplimit, align ): Replaces the contents of the Text object with a new formatted string
Texture:getDPIScale(): Gets the DPI scale factor of the Texture
Texture:getDepth(): Gets the depth of a Volume Texture
Texture:getDepthSampleMode(): Gets the comparison mode used when sampling from a depth texture in a shader
Texture:getDimensions(): Gets the width and height of the Texture
Texture:getFilter(): Gets the filter mode of the Texture
Texture:getFormat(): Gets the pixel format of the Texture
Texture:getHeight(): Gets the height of the Texture
Texture:getLayerCount(): Gets the number of layers / slices in an Array Texture
Texture:getMipmapCount(): Gets the number of mipmaps contained in the Texture
Texture:getMipmapFilter(): Gets the mipmap filter mode for a Texture
Texture:getPixelDimensions(): Gets the width and height in pixels of the Texture
Texture:getPixelHeight(): Gets the height in pixels of the Texture
Texture:getPixelWidth(): Gets the width in pixels of the Texture
Texture:getTextureType(): Gets the type of the Texture
Texture:getWidth(): Gets the width of the Texture
Texture:getWrap(): Gets the wrapping properties of a Texture
Texture:isReadable(): Gets whether the Texture can be drawn and sent to a Shader
Texture:setDepthSampleMode( compare ): Sets the comparison mode used when sampling from a depth texture in a shader
Texture:setFilter( min, mag, anisotropy ): Sets the filter mode of the Texture
Texture:setMipmapFilter( filtermode, sharpness ): Sets the mipmap filter mode for a Texture
Texture:setMipmapFilter(): Sets the mipmap filter mode for a Texture
Texture:setWrap( horiz, vert, depth ): Sets the wrapping properties of a Texture
```
