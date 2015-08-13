# Player
# ======
# Player configures and controls a sprite, tracks and updates state given user
# interaction.

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
      @_initPhysics()

      @cursors = game.input.keyboard.createCursorKeys()

      @debugging = on

      # Readonly.
      @animation = null
      @state = 'still' # still, running
      @nextAction = 'none' # none, start, stop
      @nextState = null

    debug: (label, value) -> console.log "player:#{label}", value if @debugging

    isInMidAir: -> no
    isRunning: (direction) -> direction is @direction and @velocity.x isnt 0

    update: ->
      # Reset any state.
      @nextAction = 'none'
      @nextState = 'running'

      # Horizontal

      # - Revert to still. (Our acceleration updates funny.)
      @acceleration.x = 0 unless @isInMidAir()

      ###
      - Basically handle switching direction, and running or being still
        when not in the air. Note the player still runs in midair, but run
        will behave differently.
      ###

      if @cursors.left.isDown
        @_turn Direction.Left
        @_run Direction.Left

      else if @cursors.right.isDown
        @_turn Direction.Right
        @_run Direction.Right

      else unless @isInMidAir()
        if @velocity.x isnt 0 then @nextAction = 'stop'
        else @nextState = 'still'

      @_updateAnimations()
      @_changeState @nextState

    _initAnimations: ->
      @animations.add 'run', [0..11], 24, on
      @animations.add 'stop', [12..17], 24
      @animations.add 'start', [17..12], 24
      @animations.add 'jump', [18..31], 24
      @animations.add 'fall', [31], 24, on
      @animations.add 'land', [32,33,18,17], 12
      @animations.add 'end', [34...53], 12

    _initPhysics: ->
      @physics.collideWorldBounds = on
      @physics.drag.x = 200
      h = @sprite.height
      w = @sprite.width
      @_yOffset = h / 4
      @physics.setSize (w / 2), (h / 2), @_xOffset(), @_yOffset
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

    _xOffset: (direction = @direction) -> direction * 10

  Player
