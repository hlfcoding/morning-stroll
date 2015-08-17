# Player
# ======
# Player configures and controls a sprite, tracks and updates state given user
# interaction. This builds off the stock Flixel / Phaser player, but tries to
# make the movement more natural, which requires more animations, logic, and
# physics.

define [
  'phaser'
], (Phaser) ->

  'use strict'

  Direction =
    Left: -1
    Right: 1

  RegExps =
    PrettyHashRemove: /[{}"]/g
    PrettyHashPad: /[:,]/g

  class Player

    constructor: (origin, game) ->
      @sprite = game.add.sprite origin.x, origin.y, 'player', 17
      @sprite.anchor = new Phaser.Point 0.5, 0.5

      @animations = @sprite.animations
      @_initAnimations()

      game.physics.arcade.enable @sprite
      @physics = @sprite.body
      @velocity = @physics.velocity
      @acceleration = @physics.acceleration
      @direction = Direction.Right
      @gravity = game.physics.arcade.gravity
      @_initPhysics()

      @cursors = game.input.keyboard.createCursorKeys()

      @debugging = on
      @debugTextItems = {}
      @tracing = off

      # Readonly.
      @animation = null
      @state = 'still' # still, running, rising, falling
      @nextAction = 'none' # none, start, stop, jump
      @nextState = null

    debug: (label, value, details) ->
      return unless @debugging

      value = parseFloat value.toFixed(2) if _.isNumber(value)

      prettyPoint = (point) ->
        _.chain point
          .pick 'x', 'y'
          .mapObject (n) -> parseFloat n.toFixed(2)
          .value()

      prettyHash = (hash) ->
        JSON.stringify hash
          .replace RegExps.PrettyHashRemove,''
          .replace RegExps.PrettyHashPad, '$& '

      value = prettyHash prettyPoint(value) if value instanceof Phaser.Point

      if details?.position and details.position instanceof Phaser.Point
        details.position = prettyPoint details.position

      if @tracing
        label = "player:#{label}"
        if details? then console.trace label, value, details
        else console.trace label, value
      else
        details = if details? then prettyHash(details) else ''
        @debugTextItems[label] = "#{label}: #{value} #{details}"

    isInMidAir: -> @state is 'rising' or @state is 'falling'
    isRunning: (direction) -> direction is @direction and @velocity.x isnt 0

    update: ->
      # Reset any state.
      @nextAction = 'none'

      if @state is 'falling' and @physics.touching.down
        @nextState = 'landing'
      else unless @isInMidAir()
        @nextState = 'running'

      @_updateXMovement()
      @_updateYMovement()

      @_updateAnimations()
      @_changeState @nextState

    _initAnimations: ->
      @animations.add 'run', [0..11], 30, on
      @animations.add 'stop', [12..17], 24
      @animations.add 'start', [17..12], 24
      @animations.add 'jump', [18..31], 24
      @animations.add 'land', [32,33,18,17], 12
      @animations.add 'end', [34...53], 12

    _initPhysics: ->
      @physics.collideWorldBounds = on

      @physics.drag.x = 1500
      @_originalDrag = @physics.drag.clone()

      h = @sprite.height
      w = @sprite.width
      @_yOffset = h / 4
      @physics.setSize (w / 2), (h / 2), @_xOffset(), @_yOffset

      @jumpAcceleration = -4000 # A burst of energy on launch.
      @jumpMaxDuration = 500
      @maxVelocity =
        x: 200 # Run velocity.
        y: 1500 # Escape velocity.

      @_jumpTimer = @sprite.game.time.create() # This also acts like a flag.
      @_isTurning = no # Because velocity won't be 0 when turning while running.

    _changeAnimation: (nameOrFrame, interrupt = yes) ->
      return if interrupt is no and @animation?.isPlaying

      if _.isNumber(nameOrFrame)
        frame = nameOrFrame
        return if @animations.frame is frame and !@animation?
        @animations.frame = frame
        @animation = null

      else
        name = nameOrFrame
        return if @animation?.name is name
        animation = @animations.play name
        @animation = animation

      @debug 'animation', nameOrFrame

    _changeState: (state) ->
      return if state is @state

      @state = state
      @debug 'state', state

    _jump: (ending = no) ->
      if ending
        return unless @_jumpTimer.running
        @acceleration.y = @gravity.y
        @physics.drag.x = @_originalDrag.x
        @debug 'jump:end', @_jumpTimer.ms, { position: @physics.position }
        @_jumpTimer.stop()
        return

      @_jumpTimer.start()
      @debug 'jump:start', @physics.position

      @nextAction = 'jump'
      @nextState = 'rising'
      # Faster the run, higher the base jump, up to 33% improvement.
      kVelocity = (3 + Math.abs @velocity.x / @maxVelocity.x) / 4
      @acceleration.set 0, @jumpAcceleration * kVelocity
      @physics.drag.x = 2 * @_originalDrag.x

    _run: (direction) ->
      @nextAction = 'start' if @velocity.x is 0

      factor = 1
      if @isInMidAir()
        factor = -0.00001 # No force, just air friction.
      else @nextState = 'running'

      # Always try to push for max velocity.
      isNegative = @velocity.x < 0
      @velocity.x = Math.min @maxVelocity.x, Math.abs(@velocity.x)
      @velocity.x *= -1 if isNegative
      @acceleration.x = @maxVelocity.x * factor * direction

    _turn: (direction) ->
      return if !@_isTurning and @isRunning(direction)

      if @_isTurning and @animation?.isFinished
        @nextAction = 'start'
        @_isTurning = no
        # Visualize the turn.
        @sprite.scale.x = direction
        @physics.offset = new Phaser.Point @_xOffset(direction), @_yOffset

      else unless (@_isTurning or @nextAction is 'stop' or @velocity.x is 0)
        @nextAction = 'stop'
        @_isTurning = yes  
        @direction = direction
        @debug 'turn', @velocity.x

    _updateAnimations: ->
      unless @isInMidAir() or @nextAction is 'none'
        @_changeAnimation @nextAction, @animation?.loop
        return

      switch @nextState
        when 'running' then @_changeAnimation 'run', no
        when 'still' then @_changeAnimation 17, no        
        when 'falling' then @_changeAnimation 31, no
        when 'landing' then @_changeAnimation 'land'

    _updateXMovement: ->
      ###
      Basically handle switching direction, and running or being still
      when not in the air. Note the player still runs in midair, but run
      will behave differently.
      ###
      # Revert to still. (Our acceleration updates funny.)
      @acceleration.x = 0 unless @isInMidAir()

      if @cursors.left.isDown
        @_turn Direction.Left
        @_run Direction.Left

      else if @cursors.right.isDown
        @_turn Direction.Right
        @_run Direction.Right

      else unless @isInMidAir()
        if @velocity.x isnt 0 then @nextAction = 'stop'
        else @nextState = 'still'

    _updateYMovement: ->
      ###
      Basically handle starting and ending of jump, and starting of falling. The
      tracking of previous velocity is an extra complexity. The possibility of
      hitting the ceiling during jump is another one.
      ###

      if @cursors.up.isDown and not @isInMidAir() and not @_jumpTimer.running
        @_jump()

      else if @_jumpTimer.running and (@cursors.up.isUp or @_jumpTimer.ms >= @jumpMaxDuration) # Release to cancel early.
        @_jump yes

      else if @state is 'rising' and @velocity.y > 0
        @nextState = 'falling'
        @debug 'jump:peak', @physics.y

      # Speed up by persisting the jump acceleration but with quadratic decay.
      # The longer the hold, the higher the final jump, but power decays quickly.
      # Also note that negative is up, positive is down.
      if @cursors.up.isDown and @_jumpTimer.running
        kEasing = (1000 - @jumpMaxDuration) + (@jumpMaxDuration - @_jumpTimer.ms)
        kEasing = Math.pow kEasing / 1000, 2
        @acceleration.y *= kEasing
        @debug 'jump:build', kEasing

    _xOffset: (direction = @direction) -> direction * 10

  Player
