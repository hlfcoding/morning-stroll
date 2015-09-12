
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

    startingPoint: null
    endingPoint: null
    distanceToTravel: null

    # Own Methods
    # -----------

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
  # Requires inherited properties:
  State = Phaser.State

  class PlayState extends State

    # Properties
    # ----------

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

      # - Internals.
      #   Don't do expensive operations too often, if possible.
      _didEnding = no

    # `_setupPlatform`
    _setupPlatform: ->

      # - Creates a new tilemap with no arguments.
      @_platform = new Platform @game, 'balcony', 0, 0, no, 32, 32

      # - Set points.
      #   TODO: Ledge.
      @_platform.startingPoint.x = C.PLAYER_WIDTH
      @_platform.startingPoint.y = @_platform.height - C.PLAYER_HEIGHT
      ledge = @_platform.ledges[@_platform.ledges.length-1]

      @_platform.endingPoint.y = (@_platform.numRows-1 - ledge.rowIndex) * @_platform.tileHeight
      @_platform.endingPoint.x = (ledge.size * @_platform.tileWidth) / 2
      if ledge.facing is Collision.RIGHT
        @_platform.endingPoint.x = @_platform.bounds.width - @_platform.endingPoint.x

    _setupPlayerToPlatform: ->

      # - Move until we don't overlap.
      while @_platform.overlaps(@_player)
        if @_player.x <= 0 then @_player.x = @game.width
        @_player.x -= @_platform.tileWidth

  # Alias class.
  C = PlayState
```

```coffee
  Collision = Phaser.Collision
  GameObject = Phaser.GameObject
  Point = Phaser.Point
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

  # Alias class.
  C = Player
```
