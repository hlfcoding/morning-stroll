```coffee
  Group = Phaser.Group
  Rectangle = Phaser.Rectangle

  class Background extends Phaser.Group

    # Properties
    # ----------

    # Main knobs.
    parallaxFactor: 0.9
    parallaxBuffer: 2.0
    parallaxTolerance: 0

    # To work with our foreground.
    bounds: null

    # Modes enum:
    #
    # - Clip backgrounds: Images are only partial, and clip the transparent leftovers.
    # - Full backgrounds: Each image is the full original.
    mode: 0
    @CLIP_BGS: 1
    @FULL_BGS: 2

    # Phaser Methods
    # --------------

    constructor: (@game, @maxSize=0) ->
      @bounds = new Rectangle()
      @mode = C.FULL_BGS
      super @game, @maxSize
    destroy: ->
      super()
      @bounds = null

    # Own Methods
    # -----------

    layout: ->

  # Alias class.
  C = Background
```

```coffee
  Tilemap = Phaser.Tilemap

  class MorningStroll extends Phaser.Game

    # Properties
    # ----------

    @WIDTH:   416
    @HEIGHT:  600
    @ID:      'morning-stroll'

    @BGS:  [1..16]

    # Phaser Methods
    # --------------

    constructor: (width, height, renderer, parent, state, transparent, antialias) ->
      width = C.WIDTH
      height = C.HEIGHT
      renderer = Phaser.AUTO
      parent = C.ID
      state =
        preload: @onPreload
        create: @onCreate
        update: @onUpdate
      super arguments...

    # Own Methods
    # -----------

    onPreload: ->
      @load.tilemap 'balcony', @assetURL('tiles-auto-balcony.png'), null, '', Tilemap.CSV
      @load.image 'mate', @assetURL('mate')
      @load.spritesheet 'player', @assetURL('player.png'),
        PlayState.PLAYER_WIDTH, PlayState.PLAYER_HEIGHT
      @load.audio 'bgm', ['morning-stroll.mp3'], yes
      pad = '0000'
      for i in [1...C.BGS]
        @load.image "bg#{i}", @bgAssetURL(i)

    onCreate: ->
      @switchState new PlayState @
    onUpdate: ->

    start: ->

    assetURL: (file) -> "assets/#{file}"

    bgAssetURL: (n) ->
      file = ("#{pad}#{i}").slice -pad.length
      file = "bg-_#{file}_i.png"
      @assetURL file

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

    # Action state bitmask and options.
    @STILL:     0
    @RUNNING:   1
    @LANDING:   2
    @RISING:    101
    @FALLING:   102
    state: @STILL

    # Unfulfilled action command bitmask and options.
    @NO_ACTION: 0
    @JUMP:      1
    @STOP:      2
    @START:     3
    nextAction: @NO_ACTION

    # Flags and bitmask.
    @NO_FLAGS:             0
    @IS_CONTROLLED:        1 << 0
    @NEEDS_CAMERA_REFOCUS: 1 << 10
    flags: @NO_FLAGS

    # Physics.
    jumpMaxVelocity: null
    jumpAccel: null
    jumpAccelDecay: null
    _pVelocity: null
    _oDrag: null
    _jumpTimer: null
    naturalForces: new Point 1000, 500
    accelFactor: 0.5
    jumpAccelDecayFactor: -0.001
    jumpMinDuration: 0.2
    jumpMaxDuration: 0.5

    # Rendering.
    tailOffset: null
    headOffset: null
    facing: Collision.NONE
    offset: null

    # Camera.
    cameraFocus: null
    cameraSpeed: 30 # Basically, 1/n traveled per tween.

    # Events (Signals).
    animDelegate: null
    _eAction:
      # States.
      playerIsStill:    { signal: null, state: @STILL }
      playerIsRunning:  { signal: null, state: @RUNNING }
      playerIsLanding:  { signal: null, state: @LANDING }
      playerIsRising:   { signal: null, state: @RISING }
      playerIsFalling:  { signal: null, state: @FALLING }
      # Commands.
      playerWillJump:   { signal: null, command: @JUMP }
      playerWillStop:   { signal: null, command: @STOP }
      playerWillStart:  { signal: null, command: @START }

    # Convenience.
    _kb: null

    # Phaser Methods
    # --------------

    constructor: ->
      super

      # Declare physics.
      @pVelocity = @velocity
      @jumpMaxVelocity = new Point()
      @jumpAccel = new Point()
      @jumpAccelDecay = new Point()
      @_oDrag = new Point()

      # Declare rendering.
      @tailOffset = new Point()
      @headOffset = new Point()
      @facing = Collision.RIGHT
      @offset = new Point()

      # Declare camera.
      @cameraFocus = new GameObject @_game, @x, @y, @width, @height
      @flags |= C.NEEDS_CAMERA_REFOCUS

      # Declare state events.
      evt.signal = new Signal() for name, evt of @_eAction

      # Bind handlers.
      _.bindAll @, ['jumpEnd']

      # Setup aliases.
      @_kb = @_game.input.keyboard

      # TODO: Watch vars: `state`, `nextAction`, `velocity`, `acceleration`.

    destroy: ->
      super

    render: ->
      super
      # TODO: Apply offset.

    update: ->
      super

      # Guards.
      if not (@flags & C.IS_CONTROLLED)
        # TODO: Move to setter.
        @velocity = new Point()
        @acceleration = new Point()
        return

      # Horizontal.
      # - Revert to still. (Our acceleration updates funny.)
      if not @isInMidAir() then @acceleration.x = 0
      # - Basically handle switching direction, and running or being still when not in the air. Note
      #   the player still runs in midair, but run will behave differently.
      if @_kb.isDown Keyboard.LEFT
        if @facing is Collision.RIGHT then @face Collision.LEFT
        @run -1
      else if @_kb.isDown Keyboard.RIGHT
        if @facing is Collision.LEFT then @face Collision.RIGHT
        @run()
      else if not @isInMidAir()
        if @acceleration.x is 0
          @nextAction = if @velocity.x is 0 then C.START else C.STOP
        if @velocity.x is 0 then @state = C.STILL

      # Vertical.
      # - Constrain jump and decay the jump force.
      if @jumpTimer? # Still jumping.
        @velocity.y = Math.max(@velocity.y, @jumpMaxVelocity.y)
        @acceleration.y += (@naturalForces.y - @acceleration.y) / @jumpAccelDecay.y
      # - Basically handle starting and ending of jump, and starting of falling. The tracking of
      #   pVelocity is an extra complexity. The possibility of hitting the ceiling during jump is
      #   another one.
      if @_kb.justPressed(Keyboard.UP) and
         not @jumpTimer? and
         @touching is Collision.FLOOR
        @jumpStart()
      else if @_kb.justReleased Keyboard.UP
        @jumpEnd()
      else if @velocity.y > 0
        if @state is C.FALLING
          @_pVelocity = @velocity
        else
          @state = C.FALLING
      # - Handle ending of falling.
      if @isJustFallen() then @state = C.LANDING
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

      # - Setup physics.
      @_oDrag.x = @drag.x = @naturalForces.x
      @acceleration.y = @naturalForces.y
      @jumpAccelDecay.setTo @_oDrag.x * 2,
        # - This prevents the "being dragged into the air" feeling.
        @jumpAccelDecay.y = @_game.framerate * @jumpMinDuration

      # - Setup animation delegation.
      if @animDelegate?
        for name, evt of @_eAction
          handler = @animDelegate[name]
          if handler?
            handler = _.partial handler, @
            evt.signal.add handler, @animDelegate, 9999

      # - Start state.
      @dispatchActionStateEvent()

    # TODO: May not work.
    currentAnimation: -> @animations.currentAnim

    dispatchActionStateEvent: ->
      evt = _.findWhere @_eAction, { state: @state }
      evt.signal.dispatch()

    dispatchActionCommandEvent: (name) -> @_eAction[name].signal.dispatch()

    face: (dir) ->
      if @velocity.x isnt 0 and
         @nextAction isnt C.STOP and
         @facing isnt dir
        @nextAction = C.STOP
        if not @isInMidAir() then dispatchActionCommandEvent 'playerWillStop'
      else if @isFinished()
        @nextAction = C.START
        if not @isInMidAir() then dispatchActionCommandEvent 'playerWillStart'
        if dir is Collision.RIGHT
          @offset.x = @tailOffset.x
          @facing = Collision.RIGHT
        else if dir is Collision.LEFT
          @offset.x = 0
          @facing = Collision.LEFT

    isInMidAir: -> @state >= C.RISING

    # TODO: Figure out how to map this to `animations`.
    isFinished: -> yes

    isJustFallen: ->
      @wasTouching is Collision.FLOOR and
      @state is C.FALLING and
      @_pVelocity?

    jumpStart: ->
      velocityFactor = Math.abs(@velocity.x / @maxVelocity.x)
      durationFactor = velocityFactor * (@jumpMaxDuration - @jumpMinDuration)
      duration = @jumpMinDuration + durationFactor
      dispatchActionCommandEvent 'playerWillJump'
      @y-- # Is this a tweak?
      @state = C.RISING
      @acceleration.setTo 0, @jumpAccel.y
      @drag.x = @jumpAccelDecay.x
      @jumpTimer = setTimeout @jumpEnd, duration

    jumpEnd: ->
      @acceleration.y = @naturalForces.y
      @drag.x = @_oDrag.x
      if @jumpTimer? then clearTimeout @jumpTimer

    run: (dir=1) ->
      factor = @accelFactor
      if @isInMidAir()
        factor = @jumpAccelDecayFactor
      else if @state isnt C.RUNNING
        @state = C.RUNNING
      @acceleration.x = @drag.x * factor * dir

  # Alias class.
  C = Player
```
