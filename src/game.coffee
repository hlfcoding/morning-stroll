# Game
# ====
# Configures and controls our Phaser.Game through composition.

define [
  'phaser'
  'underscore'
  'app/play-state'
  'app/platforms'
  'app/player'
], (Phaser, _, PlayState, Platforms, Player) ->

  'use strict'

  class MorningStroll

    @playerH: 72
    @playerW: 72
    @groundH: 20

    constructor: ->
      _.bindAll @, 'onPreload', 'onCreate', 'onUpdate', 'onRender'

      width = 416
      height = 600
      renderer = Phaser.AUTO
      parentElementId = 'morning-stroll'
      states =
        preload: @onPreload
        create: @onCreate
        update: @onUpdate
        render: @onRender

      @game = new Phaser.Game width, height, renderer, parentElementId, states

    onPreload: ->
      @debug = @game.debug
      @physics = @game.physics

      loader = @game.load
      loader.spritesheet 'mate', 'assets/mate.png', MorningStroll.playerW, MorningStroll.playerH
      loader.spritesheet 'player', 'assets/player.png', MorningStroll.playerW, MorningStroll.playerH

    onCreate: ->
      @physics.startSystem Phaser.Physics.ARCADE
      @physics.arcade.gravity.y = 600

      @_addMate()
      @_addPlatforms()
      @_addPlayer()

    onUpdate: ->
      @_updateCollisions()
      @player.update()

    onRender: ->
      @debug.body @platforms.ground
      @debug.body @player.sprite

    _addMate: ->
      @mate = @game.add.sprite 0, 0, 'mate', 1
      manager = @mate.animations
      manager.add 'end', [1..14], 12
      manager.play 'end' # @test

    _addPlatforms: ->
      @platforms = new Platforms { groundH: MorningStroll.groundH }, @game

    _addPlayer: ->
      y = @game.world.height - MorningStroll.playerH - MorningStroll.groundH
      origin = new Phaser.Point 0, y
      @player = new Player origin, @game

    _updateCollisions: ->
      @physics.arcade.collide @player.sprite, @platforms.group

  MorningStroll
