# PlayState
# =========

define [
  'dat.gui'
  'phaser'
  'underscore'
  'app/background'
  'app/defines'
  'app/helpers'
  'app/platforms'
  'app/player'
], (dat, Phaser, _, Background, defines, Helpers, Platforms, Player) ->

  'use strict'

  class PlayState extends Phaser.State

    init: ->
      @debugging = on # Turn off here to disable entirely (@release).
      @developing = on
      @detachedCamera = off

      @debug = @gui = null
      @cursors = null
      @background = @mate = @platforms = @player = null

      @_initDebugDisplayMixin @game if @debugging

    create: ->
      @physics.startSystem Phaser.Physics.ARCADE
      @physics.arcade.gravity.y = 500

      @cursors = @input.keyboard.createCursorKeys()

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

    update: ->
      @physics.arcade.collide @player.sprite, @platforms.layer

      @background.update()
      @player.update()

      Helpers.moveDetachedCamera @camera, @cursors if @detachedCamera

    render: ->
      @_renderDebugDisplay() if @debugging
      @_renderDebugOverlays() if @debugging

    _addBackground: ->
      parallaxTolerance = defines.mapH - defines.artH
      @background = new Background { parallaxTolerance }, @game
      @background.addImages _.template('bg<%= zIndex %>'), 16
      @background.layout()

    _addMate: ->
      {x, y} = @_createEndingPoint()
      x -= 20
      y -= 46
      @mate = @add.sprite x, y, 'mate', 1
      manager = @mate.animations
      manager.add 'end', [1..14], 12
      manager.play 'end' # @test

    _addPlatforms: ->
      @platforms = new Platforms 
        mapH: defines.mapH
        tileImageKey: 'balcony'
      , @game, @gui?.addOpenFolder 'platforms'

    _addPlayer: ->
      origin = @_createStartingPoint()
      @player = new Player { origin }, @game, @cursors, @gui?.addOpenFolder 'player'
      @player.debugging = @debugging

    _createEndingPoint: ->
      _.last(@platforms.ledges).createMidpoint @platforms

    _createStartingPoint: ->
      new Phaser.Point defines.playerW, @world.height - defines.playerH

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
        @camera.follow @player.sprite
        @player.cursors ?= @cursors
      else
        @camera.unfollow()
        @player.cursors = null

  _.extend PlayState::, Helpers.DebugDisplayMixin

  PlayState
