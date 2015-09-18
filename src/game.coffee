# Game
# ====
# Configures and controls our Phaser.Game through composition.

define [
  'dat.gui'
  'phaser'
  'underscore'
  'app/background'
  'app/helpers'
  'app/play-state'
  'app/platforms'
  'app/player'
], (dat, Phaser, _, Background, Helpers, PlayState, Platforms, Player) ->

  'use strict'

  class MorningStroll

    @playerH: 72
    @playerW: 72
    @artH: 2912
    @mapH: 3152 # +240

    constructor: ->
      _.bindAll @, 'onPreload', 'onCreate', 'onUpdate', 'onRender'

      @debugging = on # Turn off here to disable entirely (@release).
      @developing = on
      @detachedCamera = off

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

      @debug = @gui = null
      @cursors = @physics = null
      @background = @mate = @platforms = @player = null

    onPreload: ->
      @_initDebugDisplayMixin @game if @debugging

      loader = @game.load
      loader.image 'balcony', 'assets/tiles-auto-balcony.png'
      for zIndex in [16..1]
        id = (16 - zIndex + 10000).toString().substr(1)
        loader.image "bg#{zIndex}", "assets/bg-_#{id}_#{zIndex}.png"
      loader.spritesheet 'mate', 'assets/mate.png', MorningStroll.playerW, MorningStroll.playerH
      loader.spritesheet 'player', 'assets/player.png', MorningStroll.playerW, MorningStroll.playerH

    onCreate: ->
      @physics = @game.physics
      @physics.startSystem Phaser.Physics.ARCADE
      @physics.arcade.gravity.y = 500

      @cursors = @game.input.keyboard.createCursorKeys()

      if @developing
        @gui = new dat.GUI()
        @gui.add(@, 'debugging').listen().onFinishChange => @debug.reset() unless @debugging
        @gui.add(@, 'detachedCamera').onFinishChange => @_toggleCameraAttachment()
        @gui.addOpenFolder('gravity').addRange @physics.arcade.gravity, 'y'

      # First:
      @_addBackground()
      @_addPlatforms()
      # Then:
      @_addPlayer()
      @_addMate()

      @_toggleCameraAttachment on

      @debugging = off # Off by default for performance. Doing this after setup.

    onUpdate: ->
      @physics.arcade.collide @player.sprite, @platforms.layer

      @background.update()
      @player.update()

      Helpers.moveDetachedCamera @game.camera, @cursors if @detachedCamera

    onRender: ->
      @_renderDebugDisplay() if @debugging
      @_renderDebugOverlays() if @debugging

    _addBackground: ->
      parallaxTolerance = MorningStroll.mapH - MorningStroll.artH
      @background = new Background { parallaxTolerance }, @game
      @background.addImages _.template('bg<%= zIndex %>'), 16
      @background.layout()

    _addMate: ->
      {x, y} = @_createEndingPoint()
      x -= 20
      y -= 46
      @mate = @game.add.sprite x, y, 'mate', 1
      manager = @mate.animations
      manager.add 'end', [1..14], 12
      manager.play 'end' # @test

    _addPlatforms: ->
      @platforms = new Platforms 
        mapH: MorningStroll.mapH
        tileImageKey: 'balcony'
      , @game, @gui?.addOpenFolder 'platforms'

    _addPlayer: ->
      origin = @_createStartingPoint()
      @player = new Player { origin }, @game, @cursors, @gui?.addOpenFolder 'player'
      @player.debugging = @debugging

    _createEndingPoint: ->
      _.last(@platforms.ledges).createMidpoint @platforms

    _createStartingPoint: ->
      new Phaser.Point MorningStroll.playerW, @game.world.height - MorningStroll.playerH

    _renderDebugDisplay: ->
      @resetDebugDisplayLayout()

      if @player.debugging
        @renderDebugDisplayItems (layoutX, layoutY) =>
          @debug.bodyInfo @player.sprite, layoutX, layoutY
        , 6
        @renderDebugDisplayItems @player.debugTextItems

    _renderDebugOverlays: ->
      @debug.body @player.sprite if @player.debugging

    _toggleCameraAttachment: (attached) ->
      attached ?= not @detachedCamera
      if attached
        @game.camera.follow @player.sprite
        @player.cursors ?= @cursors
      else
        @game.camera.unfollow()
        @player.cursors = null

  _.extend MorningStroll::, Helpers.DebugDisplayMixin

  MorningStroll
