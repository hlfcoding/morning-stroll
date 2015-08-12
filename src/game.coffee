# Game
# ====
# Configures and controls our Phaser.Game through composition.

# Dependencies
# ------------
define [
  'phaser'
  'underscore'
  'app/play-state'
  'app/player'
], (Phaser, _, PlayState, Player) ->

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
      origin = new Phaser.Point(0, 500)
      @player = new Player origin, @game
      @player.animations.play 'run' # @test

  MorningStroll
