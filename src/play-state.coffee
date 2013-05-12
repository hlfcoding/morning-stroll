define [
  'phaser'
  'underscore'
  'app/platform'
  'app/player'
  'app/background'
], (Phaser, _, Platform, Player, Background) ->
  #
  # Dependencies.
  #
  Collision = Phaser.Collision
  MicroPoint = Phaser.MicroPoint
  Rectangle = Phaser.Rectangle
  Signal = Phaser.Signal
  #
  # Requires inherited properties:
  State = Phaser.State

  class PlayState extends State
    #
    # The dynamically generated and extended Tilemap.
    #
    _platform: null
    @FLOOR_HEIGHT: 32
    didSetupPlatform: null
    #
    # The extend Sprite.
    #
    _player: null
    _mate: null
    @PLAYER_WIDTH: 72
    @PLAYER_HEIGHT: 72
    didSetupCharacters: null
    #
    # The background with parallax.
    #
    _bg: null
    didSetupBg: null
    #
    # Some game switches.
    #
    _shouldCheckFalling: undefined
    #
    # Game state helpers.
    #
    _statePollInterval: null
    _didEnding: undefined
    _endingDuration: 0
    @ENDING_FPS: 12
    #
    # Music.
    #
    _targetMusicVolume: 0
    _shouldPlayMusic: undefined
    @MUSIC_VOLUME_FACTOR: 1.3
    @MUSIC_VOLUME_MIN: 0.2
    @MUSIC_VOLUME_MAX: 0.8
    #
    # Phaser Methods
    # --------------
    create: ->
      #
      # Set globals.
      @_shouldCheckFalling = off
      @_shouldPlayMusic = not window.DEBUG
      #
      # Set dispatch queues for events.
      @didSetupPlatform = new Signal()
      @didSetupCharacters = new Signal()
      @didSetupBg = new Signal()
      # Setup our setup chain.
      # For now, we add things in order to get correct layering.
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
      # Start our setup chain.
      @_setupBg()
      #
      # Internals.
      # Don't do expensive operations too often, if possible.
      _didEnding = no
    _setupPlatform: ->
      #
      # Creates a new tilemap with no arguments.
      @_platform = new Platform @game
      #
      # Customize our tile generation.
      # Vertical ledge spacing and horizontal ledge size affect difficulty.
      @_platform.tileWidth = 32
      @_platform.tileHeight = 32
      @_platform.minLedgeSize = 3
      @_platform.maxLedgeSize = 5
      @_platform.minLedgeSpacing = new MicroPoint 4, 2
      @_platform.maxLedgeSpacing = new MicroPoint 8, 4
      @_platform.ledgeThickness = 2
      #
      # Set the bounds based on the background.
      # FIXME: Parallax bug.
      @_platform.bounds = new Rectangle(
        @_bg.bounds.x, @_bg.bounds.y,
        @_bg.bounds.width, @_bg.bounds.height + C.FLOOR_HEIGHT
      )
      #
      # Make our platform.
      # TODO: Image.
      @_platform.makeMap()
      #
      # Set points.
      @_platform.startingPoint.x = C.PLAYER_WIDTH
      @_platform.startingPoint.y = @_platform.height - C.PLAYER_HEIGHT
      ledge = @_platform.ledges[@_platform.ledges.length-1]
      # TODO: Ledge.
      ###
      @_platform.endingPoint.y = (@_platform.numRows-1 - ledge.rowIndex) * @_platform.tileHeight
      @_platform.endingPoint.x = (ledge.size * @_platform.tileWidth) / 2
      if ledge.facing is Collision.RIGHT
        @_platform.endingPoint.x = @_platform.bounds.width - @_platform.endingPoint.x
      ###
      #
      # Hook.
      @didSetupPlatform.dispatch()
    _setupPlayer: (point) ->
      #
      # Find start position for player.
      @_player = new Player @game, point.x, point.y
      #
      # Hook.
      # TODO: Use _.after.
      @didSetupCharacters.dispatch()
    _setupPlayerToPlatform: ->
      #
      # Move until we don't overlap.
      while @_platform.overlaps(@_player)
        if @_player.x <= 0 then @_player.x = @game.width
        @_player.x -= @_platform.tileWidth

    _setupMate: (point) ->
    _setupBg: ->
      #
      # Load our scenery.
      @_bg = new Background @game
      @_bg.bounds.x = @_bg.bounds.y = 0
      @_bg.parallaxFactor = 0.95
      @_bg.parallaxBuffer = 1.7
      @_bg.parallaxTolerance = -64
      # TODO: Image loading.
      @_bg.layout()
      #
      # Hook.
      @didSetupBg.dispatch()
    _setupCamera: ->
    _setupAudio: ->


  C = PlayState
