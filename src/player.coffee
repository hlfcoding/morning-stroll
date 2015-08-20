# Player
# ======
# Player configures and controls a sprite, tracks and updates state given user
# interaction. This builds off the stock Flixel / Phaser player, but tries to
# make the movement more natural, which requires more animations, logic, and
# physics.

define [
  'phaser'
  'underscore'
], (Phaser, _) ->

  'use strict'

  Direction =
    Left: -1
    Right: 1

  RegExps =
    PrettyHashRemove: /[{}"]/g
    PrettyHashPad: /[:,]/g

  class Player

    # Statics
    # -------

    @Direction: Direction

    # Dependencies + Properties
    # -------------------------

    constructor: (origin, game, gui) ->
      @_initialize.apply @, arguments

    _initialize: (origin, game, gui) ->
      @sprite = game.add.sprite origin.x, origin.y, 'player', 17
      @sprite.anchor = new Phaser.Point 0.5, 0.5

      @animations = @sprite.animations
      @_initAnimations()

      @cursors = game.input.keyboard.createCursorKeys()

      game.physics.arcade.enable @sprite
      @gravity = game.physics.arcade.gravity
      @_initPhysics()

      @_initState()

      @_initDebugging gui

    # Public
    # ------

    debug: (label, value, details) ->
      return unless @debugging

      value = parseFloat value.toFixed(2) if _.isNumber(value)
      value = @_prettyHash @_prettyPoint(value) if value instanceof Phaser.Point

      if details?.position and details.position instanceof Phaser.Point
        details.position = @_prettyPoint details.position

      if @tracing
        label = "player:#{label}"
        if details? then console.trace label, value, details
        else console.trace label, value
      else
        details = if details? then @_prettyHash(details) else ''
        @debugTextItems[label] = "#{label}: #{value} #{details}"

    update: ->
      # First.
      @nextAction = 'none'
      @nextDirection = @_xDirectionInput()

      # Second.
      @nextState = 'running' if @_canKeepRunning()
      @nextState = 'falling' if @_canFall()
      @nextState = 'landing' if @_canLand()

      # Third.
      @_beginTurn() if @_canBeginTurn()
      @_endTurn() if @_canEndTurn()
      @_beginRun() if @_canBeginRun()
      @_endRun() if @_canEndRun()
      @_beginJump() if @_canBeginJump()
      @_endJump() if @_canEndJump()

      # Fourth.
      @acceleration.x = 0 unless @_isInMidAir() # Reset.
      @_buildRun() if @_canBuildRun()
      @_buildJump() if @_canBuildJump()

      # Last, if needed.
      @_changeAnimation()
      @_changeState()

    # Initialization
    # --------------

    _initAnimations: ->
      @animations.add 'run', [0..11], 30, on
      @animations.add 'stop', [12..17], 24
      @animations.add 'start', [17..12], 24
      @animations.add 'jump', [18..31], 24
      @animations.add 'land', [32,33,18,17], 24
      @animations.add 'end', [34...53], 12

    _initDebugging: (gui) ->
      @debugging = on
      @debugTextItems = {}
      @tracing = off
      return unless gui?

      @gui = gui
      @gui.add(@, 'debugging').onFinishChange => @debugTextItems = {}
      @gui.add @, 'tracing'

      @gui.addFolder 'drag'
          .addRange @physics.drag, 'x'

      @gui.addFolder 'maxVelocity'
          .addRange @maxVelocity, 'x'
          .addRange @maxVelocity, 'y'

      @gui.addRange @, prop for prop in [
        'jumpAcceleration'
        'jumpMaxDuration'
        'jumpVelocityFactor'
        'airFrictionRatio'
        'runAcceleration'
      ]

    _initPhysics: ->
      @physics = @sprite.body
      @velocity = @physics.velocity
      @acceleration = @physics.acceleration

      @physics.collideWorldBounds = on

      @physics.drag.x = 1500

      h = @sprite.height
      w = @sprite.width
      @_yOffset = h / 4
      @physics.setSize (w / 2), (h / 2), @_xOffset(), @_yOffset

      @jumpAcceleration = -4000 # A burst of energy on launch.
      @jumpMaxDuration = 500
      @jumpVelocityFactor = 1 / 4

      @airFrictionRatio = 1 / 20
      @runAcceleration = 300

      @maxVelocity =
        x: 200 # Run velocity.
        y: 1500 # Escape velocity.

      @_jumpTimer = @sprite.game.time.create() # This also acts like a flag.
      @_isTurning = no # Because velocity won't be 0 when turning while running.

    _initState: ->
      # Readonly.
      # Actions link states. Both correspond to animations.
      @animation = null
      @direction = Direction.Right
      @state = 'still' # still, running, rising, falling
      @nextAction = 'none' # none, start, stop, jump
      @nextDirection = null
      @nextState = null

    # Change
    # ------

    _changeAnimation: ->
      unless @_isInMidAir() or @nextAction is 'none'
        @_playAnimation @nextAction, @animation?.loop
        return

      switch @nextState
        when 'running' then @_playAnimation 'run', no
        when 'still' then @_playAnimation 17, @animation?.loop
        when 'falling' then @_playAnimation 31, no
        when 'landing' then @_playAnimation 'land'

    _changeState: ->
      return if @nextState is @state

      @debug 'jump:peak', @physics.y if @state is 'rising'

      @debug 'state', @nextState
      @debug 'jump:start', @physics.position if @nextState is 'rising'

      @state = @nextState

    # Computed
    # --------

    _isFullyRunning: -> @state is 'running' and @animation?.name is 'run'
    _isInMidAir: -> @state in ['rising', 'falling']
    _isLanded: -> @animation?.name is 'land' and @animation.isFinished
    _isFullyStill: -> @state is 'still' and (@animations.frame is 17 and not @animation?)

    _xDirectionInput: ->
      if @cursors.left.isDown then Direction.Left
      else if @cursors.right.isDown then Direction.Right

    _xOffset: (direction = @direction) -> direction * 10

    # Jump
    # ----

    _canBeginJump: ->
      @cursors.up.isDown and (@_isFullyRunning() or @_isFullyStill())
    _canBuildJump: ->
      @cursors.up.isDown and @_jumpTimer.running
    _canEndJump: ->
      @nextAction isnt 'jump' and @_jumpTimer.running and
      (@cursors.up.isUp or @_jumpTimer.ms >= @jumpMaxDuration) # Release to cancel early.

    _canFall: ->
      not @_jumpTimer.running and @state is 'rising' and @velocity.y > 0
    _canLand: ->
      @state is 'falling' and @physics.touching.down

    _beginJump: ->
      @_jumpTimer.start()

      @nextAction = 'jump'
      @nextState = 'rising'
      # Faster the run, higher the base jump, up to 25% improvement.
      ratio = Math.abs(@velocity.x / @maxVelocity.x)
      kVelocity = (1 - @jumpVelocityFactor) + @jumpVelocityFactor * ratio
      @acceleration.y = @jumpAcceleration * kVelocity

    _buildJump: ->
      # Speed up by persisting the jump acceleration but with quadratic decay.
      # The longer the hold, the higher the final jump, but power decays quickly.
      # Also note that negative is up, positive is down.
      kEasing = (1000 - @jumpMaxDuration) + (@jumpMaxDuration - @_jumpTimer.ms)
      kEasing = Math.pow kEasing / 1000, 2
      @acceleration.y *= kEasing
      @debug 'jump:build', kEasing

    _endJump: ->
      @debug 'jump:end', @_jumpTimer.ms, { position: @physics.position }
      @acceleration.y = @gravity.y # Reset.
      @_jumpTimer.stop()

    # Run
    # ---

    _canBeginRun: ->
      @nextDirection? and @nextDirection is @direction and
      not @_isInMidAir() and (@_isFullyStill() or @_isLanded())
    _canBuildRun: ->
      @nextDirection?
    _canEndRun: ->
      not (@nextDirection? or @_isInMidAir())
    _canKeepRunning: ->
      not (@_canLand() or @_isInMidAir())

    _beginRun: ->
      @nextAction = 'start' 
      @nextState = 'running'

    _buildRun: ->
      @velocity.clampX -@maxVelocity.x, @maxVelocity.x
      @acceleration.x =
        # No force, just air friction.
        if @_isInMidAir() then @runAcceleration * @airFrictionRatio * -@nextDirection
        # Otherwise, just step on the pedal.
        else @runAcceleration * @nextDirection

    _endRun: ->
      # Without user input, there's no force, so stop, then stay still.
      if @velocity.x isnt 0
        @nextAction = 'stop'
        return
      @nextState = 'still'
      @_isTurning = no # In case of being blocked.

    # Turn
    # ----

    _canBeginTurn: ->
      @nextDirection? and @nextAction isnt 'start' and
      not (@_isTurning or @nextDirection is @direction)
    _canEndTurn: ->
      @nextDirection? and @animation?.isFinished and
      @_isTurning and @nextDirection is @direction

    _beginTurn: ->
      @nextAction = 'stop'
      @_isTurning = yes
      @direction = @nextDirection
      @debug 'turn:start', @velocity.x

    _endTurn: ->
      # Visualize the turn here, for now.
      @sprite.scale.x = @nextDirection
      @physics.offset = new Phaser.Point @_xOffset(@nextDirection), @_yOffset

      @nextAction = 'start'
      @_isTurning = no
      @debug 'turn:end', @velocity.x

    # Helpers
    # -------

    _playAnimation: (nameOrFrame, interrupt = yes) ->
      return if interrupt is no and @animation?.isPlaying

      if _.isNumber(nameOrFrame)
        frame = nameOrFrame
        @animations.frame = frame
        @animation = null

      else
        name = nameOrFrame
        return if @animation?.name is name
        @animation = @animations.play name

      @debug 'animation', nameOrFrame

    _prettyPoint: (point) ->
      _.chain point
        .pick 'x', 'y'
        .mapObject (n) -> parseFloat n.toFixed(2)
        .value()

    _prettyHash: (hash) ->
      JSON.stringify hash
        .replace RegExps.PrettyHashRemove,''
        .replace RegExps.PrettyHashPad, '$& '

  Player
