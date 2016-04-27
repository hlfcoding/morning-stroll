# PlayState
# =========
# This is the main game class. It coordinates between the main game objects
# (including camera and music) and handles their interactions. It also handles
# ending the game, and any shortkeys. The exact list is long, but start tracing
# from `create` and `update` like any other Phaser state, and you should get
# far. Also note any logic that can be easily factored out is factored out of
# this file.

define [
  'background', 'defines', 'helpers', 'in-state-menu', 'platforms', 'player'
], (Background, defines, Helpers, InStateMenu, Platforms, Player) ->

  'use strict'

  {Camera, Key, Keyboard, Physics, Point, Rectangle, State, Timer} = Phaser

  {domStateEvents, fontLarge, fontSmall} = defines
  {artH, mapH, deadzoneH, shakeFallH} = defines
  {playerH, playerW, playerYOffset} = defines

  {AnimationMixin, CameraMixin, TextMixin} = Helpers
  {DebugMixin, DebugDisplayMixin} = Helpers

  MateLastFrame = 14

  class PlayState extends State

    init: ->
      if domStateEvents
        e = document.createEvent 'CustomEvent'
        e.initCustomEvent 'state:play', no, no, undefined
        @game.parent.dispatchEvent e

      {@debugging, @developing} = defines
      @detachedCamera = off
      @ended = no

      @debugDisplay = @gui = null
      @cursors = null
      @background = @mate = @platforms = @player = null
      @textLayout = null

      _.extend @camera, CameraMixin
      @_fixCamera()

      @game.onBlur.add @onBlur
      @game.onFocus.add @onFocus

      @_initDebugMixin
      @_initDebugDisplayMixin @game
      return

    create: ->
      @physics.startSystem Physics.ARCADE
      @physics.arcade.gravity.y = 500

      @cursors = @input.keyboard.createCursorKeys()
      # Quit on Q
      @quitKey = @_addKey Keyboard.Q, @quit
      # Quit on click at end.
      @input.onTap.add (trigger) =>
        unless @quit trigger
          @inStateMenu.toggle()
        return
      , @

      if @developing
        @gui = new dat.GUI()
        @gui.add(@, 'debugging').listen().onFinishChange =>
          @background.debugging = @platforms.debugging = @player.debugging =
            @debugging
          @debugDisplay.reset() unless @debugging
          return
        @gui.add(@, 'detachedCamera').onFinishChange =>
          @_toggleCameraAttachment()
          return
        @gui.addOpenFolder('gravity').addRange @physics.arcade.gravity, 'y'

      # First:
      @_addMusic()
      @_addBackground()
      @_addPlatforms()
      # Then:
      @_addPlayer()
      @_addMate()
      # Last:
      @_addInStateMenu()

      @camera.deadzone = new Rectangle(
        0, (@game.height - deadzoneH) / 2,
        @game.width, deadzoneH
      )
      @_toggleCameraAttachment on
      # Set after initial follow.
      _.defer => @camera.lerp.set(0.1); return

      return

    update: ->
      @physics.arcade.collide @player.sprite, @platforms.layer

      @background.update()
      @player.update()

      @_updateVolumeOnPlayerLand()
      @_shakeOnPlayerFall()

      @camera.updatePositionWithCursors @cursors if @detachedCamera

      @end() if @_isPlayerReadyToEnd()
      return

    render: ->
      @_renderDebugDisplay() if @debugging
      @_renderDebugOverlays() if @debugging
      return

    shutdown: ->
      # Null references to disposable objects we don't own.
      gameObject.destroy() for gameObject in [
        @background, @inStateMenu, @music, @platforms, @player
      ]

      @game.onBlur.remove @onBlur
      @game.onFocus.remove @onFocus
      @input.onTap.removeAll @

      key.onDown.removeAll @ for key in [
        @loudKey, @muteKey, @quietKey, @quitKey
      ]

      @gui?.destroy()
      return

    onBlur: =>
      @music?.pause()
      return

    onFocus: =>
      @music?.resume()
      return

    # Main own methods
    # ----------------

    end: ->
      # First animate player.
      animation = @player.startEnding @mate
      animation.onComplete.addOnce =>
        # Then animate mate.
        animation = @mate.play 'end'
        animation.onComplete.addOnce =>
          # Then lock them onto their final frames.
          @player.animations.frame = Player.LastFrame
          @mate.animations.frame = MateLastFrame
      # Then render ending display.
      _.delay =>
        @_renderEndingDisplay()
        return
      , 5 * Timer.SECOND
      return

    quit: (trigger) ->
      return no unless @ended or trigger instanceof Key
      @inStateMenu.toggle off
      _quit = =>
        @state.startWithTransition null, 'menu', yes
        return
      if @music.volume is 0
        _quit()
      else
        # Fade the music.
        @music.fadeOut 3 * Timer.SECOND
        # Then go back to menu while clearing world.
        @music.onFadeComplete.addOnce _quit
      return

    # Subroutines
    # -----------

    _addBackground: ->
      parallaxTolerance = mapH - artH
      @background = new Background { parallaxTolerance }, @game
      @background.addImages _.template('bg<%= zIndex %>'), 16
      @background.layout()
      return

    _addInStateMenu: ->
      @inStateMenu = new InStateMenu [
        ['Paused', { fontSize: fontLarge }]
        ['Hold arrow keys to accelerate', { fontSize: fontSmall }]
        ['Press 0, -, + for volume', { fontSize: fontSmall }]
        ['Press Q to quit', { fontSize: fontSmall }]
      ], @game,
        pauseHandler: (paused) =>
          @player.control = not paused
          return
      return

    _addKey: (keyCode, callback) ->
      key = @input.keyboard.addKey keyCode
      key.onDown.add callback, @
      @input.keyboard.removeKeyCapture keyCode
      key

    _addMate: ->
      {x, y} = @endingPoint
      x += 20
      y -= 10
      @mate = @add.sprite x, y, 'mate', 1
      @mate.anchor = new Point 0.5, 0.5
      @mate.animations.add 'end', [4..MateLastFrame], 12
      return

    _addMusic: ->
      @userVolume = 1
      @music = @add.audio 'bgm', 0.2, yes
      @music.mute = @developing or @debugging
      @music.play()
      @gui?.add(@music, 'mute').listen()
      increment = 0.1
      @loudKey = @_addKey Keyboard.EQUALS, => @userVolume += increment; return
      @muteKey = @_addKey Keyboard.ZERO, => @music.mute = not @music.mute; return
      @quietKey = @_addKey Keyboard.UNDERSCORE, => @userVolume -= increment; return
      return

    _addPlatforms: ->
      @platforms = new Platforms
        mapH: mapH
        tileImageKey: 'balcony'
      , @game, @gui?.addOpenFolder 'platforms'

      @endingPoint = @platforms.ledges[-1...][0].createMidpoint @platforms
      @startingPoint = new Point(
        playerW, (@world.height - playerH + playerYOffset)
      )
      # Use for debugging ending.
      #@startingPoint = @platforms.ledges[-2...-1][0].createMidpoint @platforms
      return

    _addPlayer: ->
      origin = @startingPoint
      @player = new Player(
        { origin }, @game, @cursors, @gui?.addOpenFolder 'player'
      )
      return

    _addText: (text, style) ->
      _.defaults style, { fill: '#fff', font: 'Enriqueta' }
      text = @addCenteredText text, @textLayout, style
      tween = @fadeTo text, Timer.SECOND, 1
      return

    # photonstorm/phaser@aee0212
    _fixCamera: _.once ->
      @camera.flawedUpdateTarget = @camera.updateTarget
      @camera.updateTarget = =>
        @camera.target.world.copyFrom @camera.target.position
        @camera.flawedUpdateTarget()
        return
      return

    _isPlayerReadyToEnd: ->
      (@player.state is 'still' and @player.control is on and
       @player.sprite.y <= @endingPoint.y)

    _renderDebugDisplay: ->
      @resetDebugDisplayLayout()

      if @player.debugging
        @renderDebugDisplayItems (layoutX, layoutY) =>
          @debugDisplay.bodyInfo @player.sprite, layoutX, layoutY
          return
        , 6
        @renderDebugDisplayItems @player.debugTextItems

    _renderDebugOverlays: ->
      if @player.debugging
        @debugDisplay.body @player.sprite
        @debugDisplay.spriteBounds @player.sprite
      return

    _renderEndingDisplay: ->
      @textLayout = { y: 120, baseline: 40 }

      @_addText 'The End', { fontSize: fontLarge }
        .onComplete.addOnce =>
          @_addText 'Click to play again', { fontSize: fontSmall }
          @ended = yes
          return
      return

    _shakeOnPlayerFall: ->
      return no unless (
        @player.nextState is 'landing' and
        @player.distanceFallen() > shakeFallH
      )
      force = no
      @camera.shake 0.02, 0.1 * Timer.SECOND, force, Camera.SHAKE_VERTICAL
      return

    _toggleCameraAttachment: (attached) ->
      attached ?= not @detachedCamera
      if attached
        @camera.follow @player.sprite
        @player.cursors ?= @cursors
      else
        @camera.unfollow()
        @player.cursors = null
      return

    _updateVolumeOnPlayerLand: ->
      return no unless @player.nextState is 'landing'
      # The music gets louder the higher the player gets.
      volume = ((@platforms.tilemap.heightInPixels - @player.sprite.y) /
                 @platforms.tilemap.heightInPixels) ** 1.3
      volume *= @math.clamp @userVolume, 0, 2 # Factor in user controls.
      volume = @math.clamp volume, 0.2, 0.8
      @music.fadeTo Timer.SECOND, volume
      return

  _.extend( PlayState::,
    AnimationMixin, DebugMixin, DebugDisplayMixin, TextMixin
  )

  PlayState
