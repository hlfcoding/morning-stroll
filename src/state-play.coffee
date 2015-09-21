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
      @debugging = defines.debugging
      @developing = defines.developing
      @detachedCamera = off

      @debug = @gui = null
      @cursors = null
      @background = @mate = @platforms = @player = null

      @_initDebugDisplayMixin @game if @debugging or @developing
      _.extend @camera, Helpers.CameraMixin

      @game.onBlur.add @onBlur, @
      @game.onFocus.add @onFocus, @

    create: ->
      @physics.startSystem Phaser.Physics.ARCADE
      @physics.arcade.gravity.y = 500

      @cursors = @input.keyboard.createCursorKeys()

      if @developing
        @gui = new dat.GUI()
        @gui.add(@, 'debugging').listen().onFinishChange =>
          @background.debugging = @platforms.debugging = @player.debugging = @debugging
          @debug.reset() unless @debugging
        @gui.add(@, 'detachedCamera').onFinishChange => @_toggleCameraAttachment()
        @gui.addOpenFolder('gravity').addRange @physics.arcade.gravity, 'y'

      # First:
      @_addMusic()
      @_addBackground()
      @_addPlatforms()
      # Then:
      @_addPlayer()
      @_addMate()

      @_toggleCameraAttachment on

    update: ->
      @physics.arcade.collide @player.sprite, @platforms.layer

      @background.update()
      @player.update()

      @_updateMusic()

      @camera.updateShake()
      if @_shakeOnPlayerFall()
        @camera.unfollow()
      else unless (@camera.target? or @camera.isShaking())
        @camera.follow @player.cameraFocus

      @camera.updatePositionWithCursors @cursors if @detachedCamera

    render: ->
      @_renderDebugDisplay() if @debugging
      @_renderDebugOverlays() if @debugging

    onBlur: ->
      @music?.pause()

    onFocus: ->
      @music?.resume()

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

    _addMusic: ->
      @music = @add.audio 'bgm', 0, yes
      @music.mute = @developing or @debugging
      @music.play()
      @gui.add @music, 'mute'

    _addPlatforms: ->
      @platforms = new Platforms 
        mapH: defines.mapH
        tileImageKey: 'balcony'
      , @game, @gui?.addOpenFolder 'platforms'

    _addPlayer: ->
      origin = @_createStartingPoint()
      @player = new Player { origin }, @game, @cursors, @gui?.addOpenFolder 'player'

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

    _shakeOnPlayerFall: ->
      if @player.nextState is 'landing' and @player.distanceFallen() > defines.shakeFallH
        @camera.shake()
      else no

    _toggleCameraAttachment: (attached) ->
      attached ?= not @detachedCamera
      if attached
        @camera.follow @player.cameraFocus
        @player.cursors ?= @cursors

        @camera.deadzone ?= new Phaser.Rectangle(
          0, (@game.height - defines.deadzoneH) / 2,
          @game.width, defines.deadzoneH
        )
      else
        @camera.unfollow()
        @player.cursors = null

    _updateMusic: _.throttle ->
      # The music gets louder the higher the player gets. Uses easing so the
      # volume smoothly updates on each landing.
      targetVolume = ((@platforms.tilemap.heightInPixels - @player.sprite.y) /
                       @platforms.tilemap.heightInPixels) ** 1.3
      volume = @music.volume + ((targetVolume - @music.volume) / 24) # Ease into target, with fps
      @music.volume = @math.clamp volume, 0.2, 0.8
    , 42, { leading: on } # ms/f at 24fps

  _.extend PlayState::, Helpers.DebugDisplayMixin

  PlayState
