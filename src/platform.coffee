# Platform
# ========
# Platform that can dynamically generate a map, and track the dynamically
# generated ledges. This makes up for `FlxTilemap`'s lack of an API to get
# tile groups (ledges) that have meta-data. Only supports the `SIDE_TO_SIDE`
# generation scheme for now.

# Dependencies
# ------------
define [
  'phaser'
], (Phaser) ->
  Collision = Phaser.Collision
  Point = Phaser.Point
  State = Phaser.State
  # Requires inherited properties:
  Tilemap = Phaser.Tilemap

  class Platform extends Tilemap

    # Properties
    # ----------

    minLedgeSize: 0
    maxLedgeSize: 0

    minLedgeSpacing: null
    maxLedgeSpacing: null

    ledgeThickness: 0

    bounds: null

    structureMode: 0
    @SIDE_TO_SIDE: 1

    tilingMode: 0
    tilingStart: 0

    hasCeiling: no
    hasFloor: no

    mapData: null

    startingPoint: null
    endingPoint: null
    distanceToTravel: null

    delegate: null

    ledges: null
    ledgesRowCount: 0

    @EMPTY_TILE: '0'
    @SOLID_TILE: '1'
    @META_TILE: '2'

    @EMPTY_ROW: 0
    @LEDGE_ROW: 1
    @SOLID_ROW: 2

    @_TOP_BOTTOM: 1
    @_BOTTOM_TOP: 2


    # Phaser Methods
    # --------------

    constructor: (@game) ->
      super @game
      @structureMode = C.SIDE_TO_SIDE
      #@tilingMode = Tilemap.AUTO
      @tilingStart = Collision.FLOOR
      @hasFloor = yes
      @startingPoint = new Point()
      @endingPoint = new Point()
      @maxLedgeSpacing = new Point()
      @minLedgeSpacing = new Point()
      @ledges = []

    destroy: ->
      super()

    # Own Methods
    # -----------

    numRows: -> Math.floor @bounds.height / @tileHeight
    numCols: -> Math.floor @bounds.width / @tileWidth
    initialize: ->

    generateData: ->
      rows = @numRows()
      cols = @numCols()
      mapData = ''
      sizeRange = @maxLedgeSize - @minLedgeSize
      spacingRange = @maxLedgeSpacing.y - @minLedgeSpacing.y
      rClearance = @minLedgeSpacing.y + @ledgeThickness
      facing = Collision.RIGHT
      if @tilingStart is Collision.FLOOR
        rStart = rows - 1
        rEnd = 0
        dir = C._BOTTOM_TOP
      else
        rEnd = rows - 1
        rStart = 0
        dir = C._TOP_BOTTOM
      # Estimate the ledge row count.
      @ledgeRowCount = rows /
        ((@maxLedgeSpacing.y + @minLedgeSpacing.y) / 2 +
          (@ledgeThickness - 1))
      #console.log 'Ledge row count', @ledgeRowCount

      # - Plot the row, given the type.
      addRow: =>

      # - Prepare for empty plot.
      setupEmptyRow: =>

      # - Prepare for full plot.
      setupFloorRow: =>

      # - Prepare for partial plot. This just does a simple random, anything
      #   more complicated is delegated.
      setupLedgeRow: =>

      # - Reset on each row.
      setupEachRow: =>


    makeMap: () ->
      if not @mapData? then @generateData()
      @parseTiledJSON @mapData, @key

    isAtEndingPoint: (gameObject) ->
      # Bottom-to-top.
      if @endingPoint.y < @startingPoint.y then gameObject <= @endingPoint.y
      # Top-to-bottom.
      else gameObject >= @endingPoint.y

  # Alias class.
  C = Platform
