# Game
# ====
# Configures our Phaser.Game through composition.

# Dependencies
# ------------
define [
  'phaser'
  'underscore'
  'app/play-state'
], (Phaser, _, PlayState) ->

  class MorningStroll

    @playerH: 72
    @playerW: 72

    constructor: ->
      _.bindAll @, 'onPreload', 'onCreate', 'onUpdate'

      width = 416
      height = 600
      renderer = Phaser.AUTO
      parentElementId = 'morning-stroll'
      states =
        preload: @onPreload
        create: @onCreate
        update: @onUpdate

      @game = new Phaser.Game width, height, renderer, parentElementId, states

    onPreload: ->
      loader = @game.load
      loader.spritesheet 'mate', 'assets/mate.png', MorningStroll.playerW, MorningStroll.playerH
      loader.spritesheet 'player', 'assets/player.png', MorningStroll.playerW, MorningStroll.playerH

    onCreate: ->
      @_addMate()
      @_addPlayer()

    onUpdate: ->

    _addMate: ->
      @mate = @game.add.sprite 0, 0, 'mate', 1
      manager = @mate.animations
      manager.add 'end', [1..14], 12
      manager.play 'end' # @test

    _addPlayer: ->
      @player = @game.add.sprite 0, 500, 'player', 17
      manager = @player.animations
      manager.add 'run', [0..11], 24, on
      manager.add 'stop', [12..17], 24
      manager.add 'start', [17..12], 24
      manager.add 'jump', [18..31], 24
      manager.add 'fall', [31], 24, on
      manager.add 'land', [32,33,18,17], 12
      manager.add 'end', [34...53], 12
      manager.play 'run' # @test

  MorningStroll
