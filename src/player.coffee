# Player
# ======
# Player configures and controls a sprite, tracks and updates state given user
# interaction.

define [
  'phaser'
], (Phaser) ->

  Action =
    None: 0
    Stop: 1
    Start: 2

  Direction =
    Left: -1
    Right: 1

  State =
    Still: 0
    Running: 1

  class Player

    @Action: Action
    @Direction: Direction
    @State: State

    constructor: (origin, game) ->
      @sprite = game.add.sprite origin.x, origin.y, 'player', 17
      @sprite.anchor = new Phaser.Point 0.5, 0.5

      @animations = @sprite.animations
      @_initAnimations()

      game.physics.arcade.enable @sprite
      @physics = @sprite.body
      @velocity = @physics.velocity
      @acceleration = @physics.acceleration
      @_initPhysics()

      @cursors = game.input.keyboard.createCursorKeys()

      @animation = null
      @state = State.Still
      @direction = Direction.Right
      @nextAction = Action.None

    inMidAir: -> no

    update: ->
      # Horizontal

      @nextAction = Action.None
      @acceleration.x = 0

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

      else if not @inMidAir()
        @nextAction = if @velocity.x is 0 then Action.Start else Action.Stop
        if @velocity.x is 0
          @state = State.Still
          @animations.frame = 17

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

    _run: (direction) ->
      factor = 200
      if @inMidAir()
        # TODO
      else if @state isnt State.Running
        @state = State.Running
      @animations.play 'run' unless @animation?.isPlaying
      @acceleration.x = factor * direction

    _turn: (direction) -> # TODO: Replace with animation.
      return if direction is @direction
      shouldStop = @velocity.x isnt 0 and @nextAction isnt Action.Stop and @direction isnt direction
      if shouldStop
        @nextAction = Action.Stop
        @animation = @animations.play 'stop' unless @inMidAir()
      else if not @animation?.isPlaying
        @nextAction = Action.Start
        @animation = @animations.play 'start' unless @inMidAir()
      @direction = direction
      @sprite.scale.x = direction


  Player
