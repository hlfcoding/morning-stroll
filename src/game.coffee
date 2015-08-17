# Game
# ====
# Configures and controls our Phaser.Game through composition.

define [
  'dat.gui',
  'phaser'
  'underscore'
  'app/play-state'
  'app/platforms'
  'app/player'
], (dat, Phaser, _, PlayState, Platforms, Player) ->

  'use strict'

  kPhaserLayoutX = -8
  kPhaserLineRatio = 1.8

  class MorningStroll

    @playerH: 72
    @playerW: 72
    @groundH: 20

    constructor: ->
      _.bindAll @, 'onPreload', 'onCreate', 'onUpdate', 'onRender'

      @debugFontSize = 9

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
      @debug.font = "#{@debugFontSize}px Menlo"
      @gui = new dat.GUI()

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
      @_updateDebugDisplay()
      @_updateDebugOverlays()

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

    _updateDebugDisplay: ->
      gutter = 2 * @debugFontSize
      line = kPhaserLineRatio * @debugFontSize

      layoutX = gutter + kPhaserLayoutX
      layoutY = gutter

      if @player.debugging
        @debug.bodyInfo @player.sprite, layoutX, layoutY
        layoutY += 6 * line

        for own label, text of @player.debugTextItems
          @debug.text text, layoutX, layoutY, null, @debug.font
          layoutY += line

    _updateDebugOverlays: ->
      @debug.body @platforms.ground
      @debug.body @player.sprite if @player.debugging

  MorningStroll
