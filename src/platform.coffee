define [
  'phaser'
], () ->

  Tilemap = Phaser.Tilemap
  Point = Phaser.Point
  Collision = Phaser.Collision

  # Platform that can dynamically generate a map, and track the dynamically
  # generated ledges. This makes up for FlxTilemap's lack of an API to get
  # tile groups (ledges) that have meta-data. Only supports the `SIDE_TO_SIDE`
  # generation scheme for now.

  class Platform extends Tilemap

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

    startingPoint: null
    endingPoint: null
    distanceToTravel: null

    delegate: null

    ledges: null
    ledgesRowCount: 0

    @EMPTY_TILE: '0'
    @LEDGE_ROW: '1'
    @META_TILE: '2'

    @EMPTY_ROW: 0
    @LEDGE_ROW: 1
    @SOLID_ROW: 2

    @_TOP_BOTTOM: 1
    @_BOTTOM_TOP: 2

    #
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
      @ledges = []

    destroy: ->
      super()
    #
    # Own Methods
    # -----------
    numRows: -> Math.floor @bounds.height / @tileHeight
    numCols: -> Math.floor @bounds.width / @tileWidth
    initialize: ->
    generateData: ->
    makeMap: ->
    isAtEndingPoint: (gObject) ->

  C = Platform
