# Player
# ======
# Player that has more complex running and jumping abilities. It makes use of an animation
# delegate and has a simple state tracking system. It also takes into account custom offsets. It
# also allows for custom camera tracking. This class is meant to be very configurable and has many
# hooks.

# Dependencies
# ------------
define [
  'phaser'
], (Phaser) ->
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
