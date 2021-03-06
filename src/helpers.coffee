# Helpers
# =======
# Misc. utilities and bits of custom functionality not specific to the game.
# For now it's all in this one file, but eventually may become a separate
# module. Ideally this file should be short because we shouldn't need to patch
# or extend vendor code.

# __See__: [tests](../tests/helpers.html).

define [], ->

  {Easing, Point, RenderTexture, Sprite, Timer} = Phaser

  # Cache regex patterns.
  RegExps =
    PrettyHashRemove: /[{}"]/g
    PrettyHashPad: /[:,]/g

  # AnimationMixin
  # --------------
  # Requires DebugMixin. Some higher-level operations over Phaser animation
  # API. Apply this to any object that has an `animations` (`AnimationManager`)
  # property. It will set a current `animation` property. An `add`
  # (`GameObjectFactory`) property is also required.

  AnimationMixin =

    playAnimation: (nameOrFrame, interrupt = yes) ->
      return no if interrupt is no and @animation?.isPlaying

      if _.isNumber(nameOrFrame)
        frame = nameOrFrame
        @animations.frame = frame
        @animation = null

      else
        name = nameOrFrame
        return no if @animation?.name is name
        @animation = @animations.play name

      @debug? 'animation', nameOrFrame

      @animation

    fadeTo: (gameObject, duration, alpha, init = yes) ->
      gameObject.alpha = (if alpha is 0 then 1 else 0) if init
      tween = @add.tween(gameObject).to({ alpha }, duration, 'Cubic', yes)

  # CameraMixin
  # -----------
  # This should get applied directly to a camera instance.
  # `updatePositionWithCursors` is an abstraction over moving camera with
  # cursors.

  CameraMixin =

    updatePositionWithCursors: (cursors, velocity = 4) ->
      if cursors.up.isDown then @y -= velocity
      else if cursors.down.isDown then @y += velocity
      else if cursors.left.isDown then @x -= velocity
      else if cursors.right.isDown then @x += velocity
      return

  # Debugging Mixins
  # ----------------
  # Allows any object to debug to console or display with fancy and readable
  # formatting. Sets `debugTextItems` on the object for `DebugDisplayMixin` to
  # render. Also sets and works with `debugging`, `tracing`, `gui`. Requires
  # `debugNamespace` to be set.

  DebugMixin =

    _initDebugMixin: (gui) ->
      @debugging ?= on
      @tracing ?= off
      @debugTextItems = {}

      return no unless gui?

      @gui = gui

      toggle = @gui.add(@, 'debugging')
      toggle.listen()
      toggle.onFinishChange( => @debugTextItems = {}; return )

      @gui.add(@, 'tracing')

      yes

    debug: (label, value, details) ->
      return unless @debugging

      value = parseFloat(value.toFixed(2)) if _.isNumber(value)
      value = @_prettyHash(@_prettyPoint(value)) if value instanceof Point

      if details?.position and details.position instanceof Point
        details.position = @_prettyPoint(details.position)

      if @tracing
        label = "#{@debugNamespace}:#{label}"
        if details? then console.trace(label, value, details)
        else console.trace(label, value)
      else
        if (_.isArray(value) and
          (_.isArray(value[0]) or _.isPlainObject(value[0]))
        )
          label = "#{@debugNamespace}:#{label}"
          console.groupCollapsed(label)
          console.table?(value)
          console.groupEnd()
        else
          details = if details? then @_prettyHash(details) else ''
          @debugTextItems[label] = "#{label}: #{value} #{details}".trim()
      return

    _prettyPoint: (point) ->
      _.chain(point)
        .pick('x', 'y')
        .mapObject( (n) -> parseFloat(n.toFixed(2)) )
        .value()

    _prettyHash: (hash) ->
      JSON.stringify(hash)
        .replace(RegExps.PrettyHashRemove, '')
        .replace(RegExps.PrettyHashPad, '$& ')

  # Define Phaser-specific constants. Fragile.
  kPhaserLayoutX = -8
  kPhaserLineRatio = 1.8

  # Renders to game's `Phaser.Utils.Debug` display, which isn't the easiest to
  # extend correctly and requires manual layout bookkeeping. Sets and works
  # with `debugFontSize`. Requires game object. Sets some internal layout
  # properties.
  DebugDisplayMixin =

    # Only do the minimal setup here, so it can always run.
    _initDebugDisplayMixin: (game) ->
      @debugFontSize ?= 9
      # Compute sizes.
      @_debugGutter = 2 * @debugFontSize
      @_debugLine = kPhaserLineRatio * @debugFontSize

      @debugDisplay = game.debug
      @debugDisplay.font = "#{@debugFontSize}px Menlo"
      return

    resetDebugDisplayLayout: ->
      @_layoutX = @_debugGutter + kPhaserLayoutX
      @_layoutY = @_debugGutter
      return

    renderDebugDisplayItems: (items, lines) ->
      if _.isFunction(items) and lines?
        items(@_layoutX, @_layoutY)
        @_layoutY += lines * @_debugLine

      else for own label, text of items
        @debugDisplay.text(text, @_layoutX, @_layoutY, null, @debugDisplay.font)
        @_layoutY += @_debugLine
      return

  # Developing
  # ----------
  # Basic dat.GUI extensions to require less code.

  addOpenFolder = ->
    folder = @addFolder.apply(@, arguments)
    folder.open()
    folder

  addRange = (obj, prop, chain = yes) ->
    value = obj[prop]
    [min, max] = [value / 2, 2 * value]

    if value < 0 then gui = @.add(obj, prop, max, min)
    else if value > 0 then gui = @.add(obj, prop, min, max)
    else gui = @.add(obj, prop)

    if chain then @ else gui

  _.extend(dat.GUI::, { addOpenFolder, addRange })

  # Flixel Tilemap AUTO Layout Shim
  # -------------------------------
  # Same behavior as Flixel, but a different, more straightforward
  # implementation.

  autoSetTiles = (tiles) ->
    result = (_.clone(row) for row in tiles)

    for row, r in result
      for col, c in row when col is 1

        left = right = top = bottom = 1
        left    = tiles[r][c - 1] unless c is 0
        right   = tiles[r][c + 1] unless c is row.length - 1
        top     = tiles[r - 1][c] unless r is 0
        bottom  = tiles[r + 1][c] unless r is tiles.length - 1

        switch [top, right, bottom, left].join() # Tainted by CSS.
          when '0,0,0,0' then tile = 1 # all empty
          when '1,0,0,0' then tile = 2 # bottom tip
          when '0,1,0,0' then tile = 3 # left tip
          when '1,1,0,0' then tile = 4 # bottom-left corner
          when '0,0,1,0' then tile = 5 # top tip
          when '1,0,1,0' then tile = 6 # vertical segment
          when '0,1,1,0' then tile = 7 # top-left corner
          when '1,1,1,0' then tile = 8 # left edge
          when '0,0,0,1' then tile = 9 # right tip
          when '1,0,0,1' then tile = 10 # bottom-right corner
          when '0,1,0,1' then tile = 11 # horizontal segment
          when '1,1,0,1' then tile = 12 # bottom edge
          when '0,0,1,1' then tile = 13 # top-right corner
          when '1,0,1,1' then tile = 14 # right edge
          when '0,1,1,1' then tile = 15 # top edge
          when '1,1,1,1' then tile = 16 # body

        row[c] = tile

    result

  # PointMixin
  # ----------
  # Basic Phaser class extension for less code.

  PointMixin =
    addPoint: (point) -> @add(point.x, point.y)
    dividePoint: (point) -> @divide(point.x, point.y)
    multiplyPoint: (point) -> @multiply(point.x, point.y)
    subtractPoint: (point) -> @subtract(point.x, point.y)

  # StateManagerMixin
  # -----------------
  # Adds transitioning that's heavily inspired by aaccurso/phaser-state-
  # transition-plugin.
  # Given its complexity, coupling, and fragility, this one is manually
  # tested.

  # As far as what it does, it wraps the state's methods with logic to
  # screenshot the current viewport (with some weird offsetting logic). The
  # screenshot becomes a sprite that covers the new state and fades out on
  # create, giving the illusion of transitioning.

  StateManagerMixin =
    startWithTransition: (transitionOptions = {}, startArgs...) ->
      {duration, easing, properties} = _.defaults transitionOptions,
        duration: 2 * Timer.SECOND
        easing: Easing.Exponential.InOut
        properties: { alpha: 0 }

      [stateName] = startArgs
      state = @states[stateName]
      {init, create} = state

      @game.camera.unfollow() # Prevent flickering.
      @game.paused = yes
      texture = new RenderTexture(
        @game, @game.width, @game.height, "transition-to-#{stateName}"
      )
      texture.renderXY(@game.world, -@game.camera.x, -@game.camera.y)
      @game.paused = no

      interstitial = new Sprite(@game, 0, 0, texture)
      interstitial.fixedToCamera = on

      destroy = ->
        return unless texture? and interstitial?
        texture.destroy()
        interstitial.destroy()
        texture = interstitial = null
        state.init = init
        state.create = create
        return

      state.init = =>
        init?.apply(state, arguments)
        @game.add.existing(interstitial)
        return

      state.create = =>
        create?.apply(state, arguments)
        interstitial.bringToTop()
        @game.add.tween(interstitial)
          .to(properties, duration, easing, yes)
          .onComplete.addOnce(destroy)
        return

      _.delay(destroy, 2 * duration) # In case of failure.

      @start.apply(@, startArgs)
      return

  # TextMixin
  # ---------
  # Allows any object that has `add` (`GameObjectFactory`) and game `world` to
  # add text with some base layout.

  TextMixin =

    addCenteredText: (text, layout, style, group) ->
      _.defaults(style, { boundsAlignH: 'center', boundsAlignV: 'middle' })
      text = @add.text(@world.centerX, layout.y, text, style, group)
      text.anchor.setTo(0.5)
      layout.y += text.height + layout.baseline
      text

  # Underscore mixins
  # -----------------

  isPlainObject = (arg) -> _.isObject(arg) and not _.isFunction(arg)

  _.mixin({ isPlainObject })

  # Export.

  { AnimationMixin, CameraMixin, DebugMixin, DebugDisplayMixin, PointMixin,
    RegExps, StateManagerMixin, TextMixin, autoSetTiles }
