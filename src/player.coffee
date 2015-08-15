# Player
# ======
# Player configures and controls a sprite, tracks and updates state given user
# interaction. This builds off the stock Flixel / Phaser player, but tries to
# make the movement more natural, which requires more animations, logic, and
# physics.

define [
  'phaser'
], (Phaser) ->

  Direction =
    Left: -1
    Right: 1

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

      # Readonly.
      @animation = null
      @state = 'still' # still, running, rising, falling
      @nextAction = 'none' # none, start, stop, jump
      @nextState = null

    debug: (label, value, details) ->
      return unless @debugging
      label = "player:#{label}"
      if details? then console.trace label, value, details
      else console.trace label, value

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
      @animations.add 'run', [0..11], 24, on
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

      @jumpMaxVelocity = -320
      @jumpTimeRange = { min: 200, max: 500 }
      @maxVelocity = { x: 200, y: 1500 }

      @_jumpDeacceleration = 60 * @jumpTimeRange.min # Fixes 'being dragged into the air' feeling.
      @_justTurned = no # Because velocity won't be 0 when just turning.

    _changeAnimation: (nameOrFrame, interrupt = yes) ->
      return if interrupt is no and @animation?.isPlaying

      if _.isNumber(nameOrFrame)
        frame = nameOrFrame
        return if @animations.frame is frame
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
        return unless @_jumpTimer?
        @acceleration.y = @gravity.y
        @physics.drag.x = @_originalDrag.x
        clearTimeout @_jumpTimer
        @_jumpTimer = null
        @debug 'jump:end'

        @nextState = 'falling'
        return

      # Faster the run, higher the jump.
      kVelocity = 4 * (1 + Math.abs @velocity.x / @maxVelocity.x)
      kDuration = kVelocity * (@jumpTimeRange.max - @jumpTimeRange.min)
      duration = parseInt (@jumpTimeRange.min / 1000) * kDuration
      @_jumpTimer = setTimeout @_jump.bind(@, yes), duration
      @debug 'jump:start', duration

      @nextAction = 'jump'
      @nextState = 'rising'
      @acceleration.set 0, -3000
      @physics.drag.x = 2 * @_originalDrag.x

    _run: (direction) ->
      @nextAction = 'start' if @velocity.x is 0

      factor = 200
      if @isInMidAir()
        # TODO
      else @nextState = 'running'
      @acceleration.x = factor * direction

    _turn: (direction) ->
      return if @isRunning(direction)

      if @_justTurned
        @nextAction = 'start'
        @_justTurned = no
      else if @velocity.x isnt 0 and @nextAction isnt 'stop'
        @nextAction = 'stop'
        @_justTurned = yes

      @direction = direction
      @sprite.scale.x = direction
      @physics.offset = new Phaser.Point @_xOffset(direction), @_yOffset

    _updateAnimations: ->
      unless @isInMidAir() or @nextAction is 'none'
        @_changeAnimation @nextAction
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
      if @cursors.up.isDown and not @isInMidAir() and not @_jumpTimer?
        @_jump()

      else if @cursors.up.isUp and @_jumpTimer? # Cancel early.
        @_jump yes

      # Constrain jump and decay the jump force. Negative is up, positive is down.
      if @cursors.up.isDown and @_jumpTimer?
        @velocity.y = Math.max @velocity.y, -320
        @acceleration.y += (@gravity.y - @acceleration.y) / @_jumpDeacceleration
        @debug 'jump', 'build'

    _xOffset: (direction = @direction) -> direction * 10

  Player
