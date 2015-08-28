# Platform
# ========
# Platform that can dynamically generate a map, and track the dynamically
# generated ledges. Only supports the `SIDE_TO_SIDE` generation scheme for now.

define [
  'phaser'
], (Phaser) ->

  'use strict'

  Tile =
    Empty: 0
    Solid: 1
    Meta: 2

  class Platforms

    constructor: (@config, game, gui) ->
      @_initialize game, gui

    _initialize: (game, gui) ->
      @minLedgeSize = 3
      @maxLedgeSize = 5
      @minLedgeSpacing = new Phaser.Point 4, 2
      @maxLedgeSpacing = new Phaser.Point 8, 4
      @ledgeThickness = 2
      @tileWidth = @tileHeight = 32

      @group = game.add.group()
      @group.enableBody = on
      @_initPhysics game.world

      @tilemap = game.add.tilemap null, @tileWidth, @tileHeight
      @ledges = []

    _initPhysics: (world) ->
      @ground = @group.create 0, world.height - @config.groundH # @test
      @ground.width = world.width
      @ground.height = @config.groundH
      @ground.body.collideWorldBounds = on
      @ground.body.immovable = on

    makeMap: ->
      @_generateTiles() unless @tiles?
      @tilemap.createFromTiles @tiles, null, @config.tileImageKey, 0, @group

    _generateTiles: ->
      mapSize = @group.game.world.getBounds()

      vars =
        facing: 'right' # left, right
        prevFacing: null

        iCol: -1
        iColStart: -1
        iColEnd: -1

        iRow: -1
        iRowStart: -1
        iRowEnd: 0

        iLedgeRow: -1
        iLedgeLayer: -1

        numCols: Math.floor mapSize.height / @tileHeight
        numRows: Math.floor mapSize.width / @tileWidth
        numRowsClearance: @minLedgeSpacing.y + @ledgeThickness
        numLedgeRows: -1

        rangeLedgeSize: @maxLedgeSize - @minLedgeSize
        rangeRowSpacing: @maxLedgeSpacing.y - @minLedgeSpacing.y

        rowSize: -1
        rowSpacing: -1
        rowTiles: null
        rowType: null # empty, ledge, solid

        tileTypeInverse: off

      @tiles = []

      numRowsLedge = (@maxLedgeSpacing.y + @minLedgeSpacing.y) / 2 + (@ledgeThickness - 1)
      vars.numLedgeRows = vars.numRows / numRowsLedge
      vars.iRow = vars.iRowStart = vars.numRows - 1

      until vars.iRow < vars.iRowEnd
        if vars.iRow is vars.iRowStart
          @_setupFloorRow vars

        else
          @_setupEachRow vars

          if (vars.iRow - vars.numRowsClearance) <= vars.iRowEnd
            # Fill out the last rows after last ledge.
            @_setupEmptyRow vars

            if vars.iLedgeLayer > 0
              vars.iLedgeLayer--
              _.last(@ledges).rowIndex = vars.iRowStart - vars.iRow
            else
              vars.rowTiles = []

          else
            if vars.rowSpacing is 0
              @_setupLedgeRow vars
              vars.iLedgeLayer = @ledgeThickness - 1

            else if vars.iLedgeLayer > 0
              vars.iLedgeLayer--

            else
              @_setupEmptyRow vars
              vars.rowSpacing--
              vars.iLedgeLayer = 0

        @_addRow vars

        vars.iRow--

      console.log @tiles, vars.iRowStart

    _addRow: (vars) ->

    _setupEmptyRow: (vars) ->
      # Prepare for emply plot.
      vars.iColStart = 0
      vars.iColEnd = 0
      vars.rowType = 'empty'

    _setupFloorRow: (vars) ->
      # Prepare for full plot.
      vars.iColStart = 0
      vars.iColEnd = vars.numCols - 1
      vars.rowSpacing = @minLedgeSpacing.y
      vars.rowTiles = []
      vars.rowType = 'solid'

    _setupLedgeRow: (vars) ->
      # Prepare for partial plot. This just does a simple random, anything
      # more complicated is delegated.
      vars.iLedgeRow++
      vars.rowSize = @minLedgeSize + parseInt(Math.random() * vars.sizeRange)
      vars.rowSpacing = @minLedgeSpacing.y + parseInt(Math.random() * vars.spacingRange) # Prepare for next ledge.
      vars.rowType = 'ledge'

      vars.prevFacing = vars.facing
      switch vars.facing
        when 'left'
          vars.iColStart = 0
          vars.iColEnd = vars.rowSize
          vars.facing = 'right' # Prepare for next ledge.
        when 'right'
          vars.iColStart = vars.numCols - vars.rowSize
          vars.iColEnd = vars.numCols
          vars.facing = 'left' # Prepare for next ledge.

    _setupEachRow: (vars) ->
      # Reset on each row.
      vars.tileTypeInverse = off
      vars.rowTiles = [] if vars.iLedgeLayer is 0

  class Ledge

    constructor: (@index, @rowIndex, @size, @spacing, @start, @end, @facing) ->


  Platforms
