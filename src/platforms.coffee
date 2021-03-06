# Platform
# ========
# Platform that can dynamically generate a `Phaser.Tilemap` (rendered on a
# single layer), and track the dynamically generated ledges. Only supports the
# `SIDE_TO_SIDE` generation scheme for now. The complexity in its code comes
# from the numerous knobs, including a difficulty dynamic.

# __See__: [tests](../tests/platforms.html).

define ['defines', 'helpers'], (defines, Helpers) ->

  {Point} = Phaser

  {autoSetTiles, DebugMixin} = Helpers

  Tile =
    Empty: 0
    Solid: 1
    Meta: 2

  class Platforms

    constructor: (@config, game, gui) ->
      @minLedgeSize = 3
      @maxLedgeSize = 5
      @minLedgeSpacing = new Point(4, 2)
      @maxLedgeSpacing = new Point(8, 4)
      @ledgeThickness = 2
      @tileWidth = @tileHeight = 32
      @ledges = []
      @tiles = []

      @_initialize(game, gui)

    _initialize: (game, gui) ->
      @game = game # FIXME: Not great, but easy.

      @_initDebugging(gui)

      @makeMap(game)
      return

    _initDebugging: (gui) ->
      @debugNamespace = 'platforms'

      {@debugging} = defines
      completedInit = @_initDebugMixin(gui)
      return unless completedInit

    destroy: ->
      # Null references to disposable objects we don't own.

    # Public
    # ------

    makeMap: (game) ->
      @_generateTiles() unless @tiles.length

      tilesCSV = (rowCSV = (row.join(',') for row in @tiles)).join("\n")
      game.load.tilemap('platforms', null, tilesCSV)

      @tilemap = game.add.tilemap('platforms', @tileWidth, @tileHeight)
      @tilemap.addTilesetImage(@config.tileImageKey)
      @tilemap.setCollisionBetween(1, 16)

      @layer = @tilemap.createLayer(0)
      @layer.resizeWorld()
      return

    # Internal
    # --------

    _createTileGeneratorState: ->
      mapSize = @game.world.getBounds()
      vars =
        facing: 'right' # left, right
        prevFacing: null

        iCol: -1
        iColStart: -1
        iColEnd: -1

        iRow: -1
        iRowStart: -1
        iRowEnd: 0

        iLedgeRow: -1 # when used, starts at 1
        iLedgeLayer: -1

        numCols: Math.floor(mapSize.width / @tileWidth)
        numRows: Math.floor(@config.mapH / @tileHeight)
        numRowsClearance: @minLedgeSpacing.y + @ledgeThickness
        numLedgeRows: -1

        rangeLedgeSize: @maxLedgeSize - @minLedgeSize
        rangeRowSpacing: @maxLedgeSpacing.y - @minLedgeSpacing.y

        rowSize: -1
        rowSpacing: -1
        rowTiles: null
        rowType: null # empty, ledge, solid

      numRowsLedge = (
        (@maxLedgeSpacing.y + @minLedgeSpacing.y) / 2 +
        (@ledgeThickness - 1)
      )
      vars.numLedgeRows = Math.round(vars.numRows / numRowsLedge)

      vars

    _generateTiles: ->
      vars = @_createTileGeneratorState()

      @tiles = [] # Reset.

      vars.iLedgeLayer = 0
      vars.iLedgeRow = 0
      vars.rowSpacing = @minLedgeSpacing.y

      vars.iRow = vars.iRowStart = vars.numRows - 1
      until vars.iRow < vars.iRowEnd
        @_setupEachRow(vars)

        if (vars.iRow - vars.numRowsClearance) <= vars.iRowEnd
          # Fill out the last rows after last ledge.
          @_setupEmptyRow(vars)

          if vars.iLedgeLayer > 0
            vars.iLedgeLayer--
            _.last(@ledges).rowIndex = vars.iRowStart - vars.iRow
          else
            vars.rowTiles = []

        else
          if vars.rowSpacing is 0
            @_setupLedgeRow(vars)
            vars.iLedgeLayer = @ledgeThickness - 1

          else if vars.iLedgeLayer > 0
            vars.iLedgeLayer--

          else
            @_setupEmptyRow(vars)
            vars.rowSpacing--
            vars.iLedgeLayer = 0

        @_addRow(vars)

        vars.iRow--

      @tiles.reverse()

      @tiles = autoSetTiles(@tiles)

      @debug('tiles', @tiles)
      return

    _addLedgeDifficulty: (ledge, vars) ->
      easiness = Math.pow((vars.numLedgeRows / ledge.index), 0.3)
      # Amplify.
      ledge.spacing = Math.round(ledge.spacing / easiness)
      ledge.size = Math.round(ledge.size * easiness)
      # Normalize.
      ledge.spacing = Phaser.Math.clamp(
        ledge.spacing, @minLedgeSpacing.y, @maxLedgeSpacing.y
      )
      ledge.size = Phaser.Math.clamp(ledge.size, @minLedgeSize, @maxLedgeSize)
      # Update.
      switch ledge.facing
        when 'left' then ledge.end = ledge.size - 1
        when 'right' then ledge.start = ledge.end + 1 - ledge.size
      return

    _addRow: (vars) ->
      if vars.rowType is 'ledge'
        ledge = new Ledge()
        ledge.index = vars.iLedgeRow
        ledge.rowIndex = vars.iRowStart - vars.iRow
        ledge.size = vars.rowSize
        ledge.spacing = vars.rowSpacing
        ledge.start = vars.iColStart
        ledge.end = vars.iColEnd
        ledge.facing = vars.prevFacing
        # Transform.
        @_addLedgeDifficulty(ledge, vars)
        # Save.
        @ledges.push(ledge)
        # Unpack.
        vars.iColStart = ledge.start
        vars.iColEnd = ledge.end

      # Build row's tiles.
      unless vars.rowTiles.length
        for index in [0...vars.numCols]
          vars.rowTiles.push(Tile.Empty) if (
            (0 <= index < vars.iColStart) or
            (vars.iColEnd < index < vars.numCols) or
            (vars.iColStart is vars.iColEnd)
          )
          vars.rowTiles.push(Tile.Solid) if (
            (vars.iColStart <= index <= vars.iColEnd) and
            (vars.iColStart isnt vars.iColEnd)
          )

      # Add tiles.
      @tiles.push(vars.rowTiles)
      return

    _setupEmptyRow: (vars) ->
      # Prepare for empty plot.
      vars.iColStart = 0
      vars.iColEnd = 0
      vars.rowType = 'empty'
      return

    _setupLedgeRow: (vars) ->
      # Prepare for partial plot. This just does a simple random, anything
      # more complicated is delegated to _addLedgeDifficulty.
      vars.iLedgeRow++
      vars.rowSize = @minLedgeSize +
        parseInt(Math.random() * vars.rangeLedgeSize)
      # Prepare for next ledge.
      vars.rowSpacing = @minLedgeSpacing.y +
        parseInt(Math.random() * vars.rangeRowSpacing)
      vars.rowType = 'ledge'

      vars.prevFacing = vars.facing
      switch vars.facing
        when 'left'
          vars.iColStart = 0
          vars.iColEnd = vars.rowSize - 1
          vars.facing = 'right' # Prepare for next ledge.
        when 'right'
          vars.iColStart = vars.numCols - vars.rowSize
          vars.iColEnd = vars.numCols - 1
          vars.facing = 'left' # Prepare for next ledge.
      return

    _setupEachRow: (vars) ->
      # Reset on each row.
      vars.rowTiles = [] if vars.iLedgeLayer is 0
      return

  class Ledge

    constructor: ->
      @index = -1
      @rowIndex = -1
      @size = -1
      @spacing = -1
      @start = -1
      @end = -1
      @facing = 'left'
      return

    createMidpoint: (platforms) ->
      point = new Point()
      point.x = (@size / 2) * platforms.tileWidth
      point.x = platforms.tilemap.widthInPixels - point.x if @facing is 'right'
      point.y = ((platforms.tiles.length - 1) - @rowIndex) *
        platforms.tileHeight
      point

  _.extend(Platforms::, DebugMixin)

  _.extend(Platforms, { Ledge, Tile })
