# PlayState
# =========
# The main coordinator: part config list, part asset list, part delegate.
# Handles all of the character animations, and custom platform generation.
# The stage is set up based on the bg group's bounds; the platform and
# camera are set up around it.

# Dependencies
# ------------
define [
  'phaser'
  'underscore'
  'app/platform'
  'app/player'
  'app/background'
], (Phaser, _, Platform, Player, Background) ->
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
        add @_bg
        @_setupPlatform()
        console.log 'Did setup background.'
      , @
      @didSetupPlatform.add ->
        add @_platform
        @_setupPlayer @_platform.startingPoint
        @_setupPlayerToPlatform()
        @_setupMate @_platform.endingPoint
        console.log 'Did setup platform.'
      , @
      @didSetupCharacters.add ->
        add @_mate
        add @_player
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

      # - Find start position for player.
      #   TODO: Image.
      @_player = new Player @game, point.x, point.y
      @_player.state = Player.FALLING
      ###

      # - Bounding box tweaks.
      @_player.height = @_player.frameHeight / 2
      @_player.offset.y = @_player.frameHeight - @_player.height - 2
      @_player.tailOffset.x = 35
      @_player.headOffset.x = 10
      @_player.width = @_player.frameWidth - @_player.tailOffset.x
      @_player.face Collision.RIGHT

      # - These are just set as a base to derive player physics
      @_player.naturalForces.x = 1000   # Friction.
      @_player.naturalForces.y = 600    # Gravity.

      # - Basic player physics.
      @_player.maxVelocity.x = 220      # This gets achieved rather quickly.
      @_player.maxVelocity.y = 1500     # Freefall.

      # - Player jump physics.
      #   The bare minimum to clear the biggest possible jump.
      @_player.jumpMaxVelocity.y = -320 # This gets achieved rather quickly.
      @_player.jumpAccel.y = -2800      # Starting jump force.

      # - Animations.
      #   Make sure to add end transitions, otherwise the last frame is skipped if framerate is low.
      #   Note that ranges do not include the terminator.
      @_player.addAnimation('still',[17], 12)
      @_player.addAnimation('idle', [], 12, false)
      @_player.addAnimation('run',  [0...12], 24)
      @_player.addAnimation('stop', [12...18], 24, false)
      @_player.addAnimation('start',[17...11], 24, false)
      @_player.addAnimation('jump', [18...32], 24, false)
      @_player.addAnimation('fall', [31])
      @_player.addAnimation('land', [32,33,18,17], 12, false)
      endFrames = [34...54]
      endFramerate = 12
      endAnimDuration = endFrames.length / endFramerate
      @_player.addAnimation('end', endFrames, endFramerate, false)
      ###
      @_player.animDelegate =

      # - Process settings.
      @_player.init()

      # - Hook.
      #   TODO: Use `_.after`.
      @didSetupCharacters.dispatch()

    _setupPlayerToPlatform: ->

      # - Move until we don't overlap.
      while @_platform.overlaps(@_player)
        if @_player.x <= 0 then @_player.x = @game.width
        @_player.x -= @_platform.tileWidth

    _setupMate: (point) ->

    # `_setupBg`
    _setupBg: ->

      # - Load our scenery.
      @_bg = new Background @game
      @_bg.bounds.x = @_bg.bounds.y = 0
      @_bg.parallaxFactor = 0.95
      @_bg.parallaxBuffer = 1.7
      @_bg.parallaxTolerance = -64
      # - TODO: Image loading.
      @_bg.layout()

      # - Hook.
      @didSetupBg.dispatch()

    _setupCamera: ->
    _setupAudio: ->

    # Own Methods
    # -----------

    playerIsStill: (player) ->
      console.log 'I am still.', player

    playerIsFalling: (player) ->

  # Alias class.
  C = PlayState
