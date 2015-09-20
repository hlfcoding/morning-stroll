# Helpers
# =======
# Misc. utilities and bits of custom functionality not specific to the game.

define [
  'dat.gui'
  'phaser'
  'underscore'
], (dat, Phaser, _) ->

  RegExps =
    PrettyHashRemove: /[{}"]/g
    PrettyHashPad: /[:,]/g

  # Camera
  # ------
  # Heavily inspired by dmaslov/phaser-screen-shake

  CameraMixin =

    updatePositionWithCursors: (cursors, velocity = 4) ->
      if cursors.up.isDown then @y -= velocity
      else if cursors.down.isDown then @y += velocity
      else if cursors.left.isDown then @x -= velocity
      else if cursors.right.isDown then @x += velocity

    # Shake Flixel shim:

    _shake:
      _counter: -1
      count: 4
      sensitivity: 4
      shakeX: on
      shakeY: on

    isShaking: -> @_shake._counter > 0

    shake: (config) ->
      _.extend @_shake, config
      @_shake._counter = @_shake.count

    updateShake: ->
      {_counter, sensitivity, shakeX, shakeY} = @_shake

      return no if _counter is 0

      # TODO: Directions should not always match.
      direction = if _counter % 2 is 0 then -1 else 1
      offset = _counter * sensitivity * direction

      {x, y} = @
      x += offset if shakeX
      y += offset if shakeY
      @setPosition x, y

      @_shake._counter-- if _counter > 0

  # Debugging
  # ---------

  DebugMixin =

    _initDebugMixin: (gui) ->
      @debugging = on
      @tracing = off
      @debugTextItems = {}

      return no unless gui?

      @gui = gui
      @gui.add(@, 'debugging').onFinishChange => @debugTextItems = {}
      @gui.add @, 'tracing'

      yes

    debug: (label, value, details) ->
      return unless @debugging

      value = parseFloat value.toFixed(2) if _.isNumber(value)
      value = @_prettyHash @_prettyPoint(value) if value instanceof Phaser.Point

      if details?.position and details.position instanceof Phaser.Point
        details.position = @_prettyPoint details.position

      if @tracing
        label = "#{@debugNamespace}:#{label}"
        if details? then console.trace label, value, details
        else console.trace label, value
      else
        if _.isArray(value) and (_.isArray(value[0]) or _.isPlainObject(value[0]))
          label = "#{@debugNamespace}:#{label}"
          console.groupCollapsed label
          console.table? value
          console.groupEnd()
        else
          details = if details? then @_prettyHash(details) else ''
          @debugTextItems[label] = "#{label}: #{value} #{details}".trim()

    _prettyPoint: (point) ->
      _.chain point
        .pick 'x', 'y'
        .mapObject (n) -> parseFloat n.toFixed(2)
        .value()

    _prettyHash: (hash) ->
      JSON.stringify hash
        .replace RegExps.PrettyHashRemove,''
        .replace RegExps.PrettyHashPad, '$& '

  kPhaserLayoutX = -8
  kPhaserLineRatio = 1.8

  DebugDisplayMixin =

    _initDebugDisplayMixin: (game) ->
      @debugFontSize ?= 9
      # Compute sizes.
      @_debugGutter = 2 * @debugFontSize
      @_debugLine = kPhaserLineRatio * @debugFontSize

      @debug = game.debug
      @debug.font = "#{@debugFontSize}px Menlo"

    resetDebugDisplayLayout: ->
      @_layoutX = @_debugGutter + kPhaserLayoutX
      @_layoutY = @_debugGutter

    renderDebugDisplayItems: (items, lines) ->
      if _.isFunction(items) and lines?
        items @_layoutX, @_layoutY
        @_layoutY += lines * @_debugLine

      else for own label, text of items
        @debug.text text, @_layoutX, @_layoutY, null, @debug.font
        @_layoutY += @_debugLine

  # Developing
  # ----------

  addOpenFolder = ->
    folder = @addFolder.apply @, arguments
    folder.open()
    folder

  addRange = (obj, prop, chain = yes) ->
    value = obj[prop]
    [min, max] = [value / 2, 2 * value]

    if value < 0 then gui = @.add obj, prop, max, min
    else if value > 0 then gui = @.add obj, prop, min, max
    else gui = @.add obj, prop

    if chain then @ else gui

  _.extend dat.GUI::, { addOpenFolder, addRange }

  # Flixel shims
  # ------------

  # Same behavior as Flixel, but a different, more straightforward implementation.
  autoSetTiles = (tiles) ->
    result = (_.clone row for row in tiles)

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

  # Underscore mixins
  # -----------------

  isPlainObject = (arg) -> _.isObject(arg) and not _.isFunction(arg)

  _.mixin { isPlainObject }

  # Export.

  { CameraMixin, DebugMixin, DebugDisplayMixin, RegExps, autoSetTiles }
