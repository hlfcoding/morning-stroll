# Player
# ======
# Player configures and controls a sprite, tracks and updates state given user
# interaction.

define [
  'phaser'
], (Phaser) ->

  class Player

    constructor: (origin, game) ->
      @sprite = game.add.sprite origin.x, origin.y, 'player', 17

      @animations = @sprite.animations
      @_initAnimations()

      game.physics.arcade.enable @sprite
      @physics = @sprite.body
      @_initPhysics()

    update: ->
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

  Player
