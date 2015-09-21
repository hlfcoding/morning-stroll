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
    _shouldPlayMusic: undefined

    # Phaser Methods
    # --------------

    # `create`
    create: ->

      # - Set globals.
      @_shouldCheckFalling = off

      # - Internals.
      #   Don't do expensive operations too often, if possible.
      _didEnding = no

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
    flags: @NO_FLAGS

    # Physics.
    _pVelocity: null
    accelFactor: 0.5

    # Rendering.
    facing: Collision.NONE
    offset: null

    # Phaser Methods
    # --------------

    constructor: ->
      super

    update: ->
      super

      # Guards.
      if not (@flags & C.IS_CONTROLLED)
        # TODO: Move to setter.
        @velocity = new Point()
        @acceleration = new Point()
        return

  # Alias class.
  C = Player
```
