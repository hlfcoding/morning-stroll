# Game
# ====
# Configures and controls our Phaser.Game through composition.

define [
  'dat.gui',
  'phaser'
  'underscore'
  'app/background'
  'app/play-state'
  'app/platforms'
  'app/player'
], (dat, Phaser, _, Background, PlayState, Platforms, Player) ->

  'use strict'

  # Extend.
  dat.GUI::addRange = (obj, prop, chain = yes) ->
    value = obj[prop]
    [min, max] = [value / 2, 2 * value]

    if value < 0 then gui = @.add obj, prop, max, min
    else if value > 0 then gui = @.add obj, prop, min, max
    else gui = @.add obj, prop

    if chain then @ else gui

  kPhaserLayoutX = -8
  kPhaserLineRatio = 1.8

  class MorningStroll

    @playerH: 72
    @playerW: 72
    @groundH: 20
    @mapH = 2912

    constructor: ->
      _.bindAll @, 'onPreload', 'onCreate', 'onUpdate', 'onRender'

      @debugging = on # Turn off here to disable entirely (@release).
      @developing = on
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
      if @debugging
        @debug = @game.debug
        @debug.font = "#{@debugFontSize}px Menlo"

      if @developing
        @gui = new dat.GUI()
        @gui.add @, 'debugging'
          .onFinishChange => @debug.reset() unless @debugging

      @physics = @game.physics

      loader = @game.load
      loader.image 'balcony', 'assets/tiles-auto-balcony.png'
      for zIndex in [16..1]
        id = (16 - zIndex + 10000).toString().substr(1)
        loader.image "bg#{zIndex}", "assets/bg-_#{id}_#{zIndex}.png"
      loader.spritesheet 'mate', 'assets/mate.png', MorningStroll.playerW, MorningStroll.playerH
      loader.spritesheet 'player', 'assets/player.png', MorningStroll.playerW, MorningStroll.playerH

    onCreate: ->
      @physics.startSystem Phaser.Physics.ARCADE

      @physics.arcade.gravity.y = 500
      if @developing
        gui = @gui?.addFolder 'gravity'
        gui.add @physics.arcade.gravity, 'y', 0, 2 * @physics.arcade.gravity.y

      @_addBackground()
      @_addMate()
      @_addPlatforms()
      @_addPlayer()

      @game.camera.follow @player.sprite

      @debugging = off # Off by default for performance. Doing this after setup.

    onUpdate: ->
      @_updateCollisions()
      @player.update()

    onRender: ->
      @_renderDebugDisplay()
      @_renderDebugOverlays()

    _addBackground: ->
      @background = new Background { height: MorningStroll.mapH }, @game
      @background.addImages _.template('bg<%= zIndex %>'), 16
      @background.layout()

    _addMate: ->
      @mate = @game.add.sprite 0, 0, 'mate', 1
      manager = @mate.animations
      manager.add 'end', [1..14], 12
      manager.play 'end' # @test

    _addPlatforms: ->
      @platforms = new Platforms 
        groundH: MorningStroll.groundH
        tileImageKey: 'balcony'
      , @game, @gui?.addFolder 'platforms'

    _addPlayer: ->
      y = @game.world.height - MorningStroll.playerH - MorningStroll.groundH
      origin = new Phaser.Point 0, y
      @player = new Player { origin }, @game, @gui?.addFolder 'player'
      @player.debugging = @debugging

    _renderDebugDisplay: ->
      return unless @debugging

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

    _renderDebugOverlays: ->
      return unless @debugging

      @debug.body @player.sprite if @player.debugging

    _updateCollisions: ->
      @physics.arcade.collide @player.sprite, @platforms.layer

  MorningStroll
