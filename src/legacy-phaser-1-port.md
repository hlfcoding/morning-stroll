
```coffee
  Tilemap = Phaser.Tilemap

  class MorningStroll extends Phaser.Game

    # Own Methods
    # -----------

    onPreload: ->
      @load.tilemap 'balcony', @assetURL('tiles-auto-balcony.png'), null, '', Tilemap.CSV
      @load.audio 'bgm', ['morning-stroll.mp3'], yes

  # Alias class.
  C = MorningStroll
```

```coffee
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
```

```coffee
  Collision = Phaser.Collision
  Point = Phaser.Point
  Rectangle = Phaser.Rectangle
  Signal = Phaser.Signal
  # Requires inherited properties:
  State = Phaser.State

  class PlayState extends State

    # Properties
    # ----------

    # The dynamically generated and extended Tilemap.
    _platform: null
    @FLOOR_HEIGHT: 32
    didSetupPlatform: null

    # The extend Sprite.
    _player: null
    _mate: null
    @PLAYER_WIDTH: 72
    @PLAYER_HEIGHT: 72
    didSetupCharacters: null

    # The background with parallax.
    _bg: null
    didSetupBg: null

    # Some game switches.
    _shouldCheckFalling: undefined

    # Game state helpers.
    _statePollInterval: null
    _didEnding: undefined
    _endingDuration: 0
    @ENDING_FPS: 12

    # Music.
    _targetMusicVolume: 0
    _shouldPlayMusic: undefined
    @MUSIC_VOLUME_FACTOR: 1.3
    @MUSIC_VOLUME_MIN: 0.2
    @MUSIC_VOLUME_MAX: 0.8

    # Phaser Methods
    # --------------

    # `create`
    create: ->

      # - Set globals.
      @_shouldCheckFalling = off
      @_shouldPlayMusic = not window.DEBUG

      # - Set dispatch queues for events.
      @didSetupPlatform = new Signal()
      @didSetupCharacters = new Signal()
      @didSetupBg = new Signal()

      # - Setup our setup chain.
      #   For now, we add things in order to get correct layering.
      @world = @game.world
      add = _.bind @world.group.add, @world.group
      @didSetupBg.add ->
        @_setupPlatform()
        console.log 'Did setup background.'
      , @
      @didSetupPlatform.add ->
        @_setupPlayer @_platform.startingPoint
        @_setupPlayerToPlatform()
        @_setupMate @_platform.endingPoint
        console.log 'Did setup platform.'
      , @
      @didSetupCharacters.add ->
        @_setupCamera()
        @_setupAudio()
        console.log 'Did setup characters.'
      , @

      # - Start our setup chain.
      @_setupBg()

      # - Internals.
      #   Don't do expensive operations too often, if possible.
      _didEnding = no

    # `_setupPlatform`
    _setupPlatform: ->

      # - Creates a new tilemap with no arguments.
      @_platform = new Platform @game, 'balcony', 0, 0, no, 32, 32

      # - Customize our tile generation.
      #   Vertical ledge spacing and horizontal ledge size affect difficulty.
      @_platform.minLedgeSize = 3
      @_platform.maxLedgeSize = 5
      @_platform.minLedgeSpacing = new Point 4, 2
      @_platform.maxLedgeSpacing = new Point 8, 4
      @_platform.ledgeThickness = 2

      # - Set the bounds based on the background.
      #   FIXME: Parallax bug.
      @_platform.bounds = new Rectangle(
        @_bg.bounds.x, @_bg.bounds.y,
        @_bg.bounds.width, @_bg.bounds.height + C.FLOOR_HEIGHT
      )

      # - Make our platform.
      #   TODO: Image.
      @_platform.makeMap()

      # - Set points.
      #   TODO: Ledge.
      @_platform.startingPoint.x = C.PLAYER_WIDTH
      @_platform.startingPoint.y = @_platform.height - C.PLAYER_HEIGHT
      ledge = @_platform.ledges[@_platform.ledges.length-1]
      ###
      @_platform.endingPoint.y = (@_platform.numRows-1 - ledge.rowIndex) * @_platform.tileHeight
      @_platform.endingPoint.x = (ledge.size * @_platform.tileWidth) / 2
      if ledge.facing is Collision.RIGHT
        @_platform.endingPoint.x = @_platform.bounds.width - @_platform.endingPoint.x
      ###

      # - Hook.
      @didSetupPlatform.dispatch()

    # `_setupPlayer`
    _setupPlayer: (point) ->

      # - Hook.
      #   TODO: Use `_.after`.
      @didSetupCharacters.dispatch()

    _setupPlayerToPlatform: ->

      # - Move until we don't overlap.
      while @_platform.overlaps(@_player)
        if @_player.x <= 0 then @_player.x = @game.width
        @_player.x -= @_platform.tileWidth

    _setupCamera: ->
    _setupAudio: ->

    # Own Methods
    # -----------

    playerIsStill: (player) ->
      console.log 'I am still.', player

    playerIsFalling: (player) ->

  # Alias class.
  C = PlayState
```

```coffee
  Collision = Phaser.Collision
  GameObject = Phaser.GameObject
  Keyboard = Phaser.Keyboard
  Point = Phaser.Point
  Signal = Phaser.Signal
  # Requires inherited properties:
  #
  # - `acceleration`, `velocity`
  # - `drag`
  # - `animations`
  # - `touching`, `wasTouching`
  # - `_game`
  Sprite = Phaser.Sprite

  class Player extends Sprite

    # Properties
    # ----------

    # Unfulfilled action command bitmask and options.

    # Flags and bitmask.
    @NO_FLAGS:             0
    @IS_CONTROLLED:        1 << 0
    @NEEDS_CAMERA_REFOCUS: 1 << 10
    flags: @NO_FLAGS

    # Physics.
    _pVelocity: null
    accelFactor: 0.5

    # Rendering.
    facing: Collision.NONE
    offset: null

    # Camera.
    cameraFocus: null
    cameraSpeed: 30 # Basically, 1/n traveled per tween.

    # Phaser Methods
    # --------------

    constructor: ->
      super

      # Declare camera.
      @cameraFocus = new GameObject @_game, @x, @y, @width, @height
      @flags |= C.NEEDS_CAMERA_REFOCUS

      # Declare state events.
      evt.signal = new Signal() for name, evt of @_eAction

    update: ->
      super

      # Guards.
      if not (@flags & C.IS_CONTROLLED)
        # TODO: Move to setter.
        @velocity = new Point()
        @acceleration = new Point()
        return

      # Vertical.
      # - Handle focus.
      if @flags & C.NEEDS_CAMERA_REFOCUS
        @cameraFocus.x += Math.round (@x - @cameraFocus.x) / @cameraSpeed
        @cameraFocus.y += Math.round (@y - @cameraFocus.y) / @cameraSpeed
      # TODO: This may need to go elsewhere.
      @dispatchActionStateEvent()

    # Own Methods
    # -----------
    # Alphabetized.

    # `init`
    init: ->

      # - Start state.
      @dispatchActionStateEvent()

    dispatchActionStateEvent: ->
      evt = _.findWhere @_eAction, { state: @state }
      evt.signal.dispatch()

    dispatchActionCommandEvent: (name) -> @_eAction[name].signal.dispatch()

    # TODO: Figure out how to map this to `animations`.
    isFinished: -> yes

    jumpStart: ->
      @y-- # Is this a tweak?

  # Alias class.
  C = Player
```
