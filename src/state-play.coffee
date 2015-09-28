# PlayState
# =========

define [
  'dat.gui'
  'phaser'
  'underscore'
  'app/background'
  'app/defines'
  'app/helpers'
  'app/in-state-menu'
  'app/platforms'
  'app/player'
], (dat, Phaser, _, Background, defines, Helpers, InStateMenu, Platforms, Player) ->

  'use strict'

  {Key, Keyboard, Physics, Point, Rectangle, State, Timer} = Phaser

  {artH, mapH, fontLarge, fontSmall, playerH, playerW, shakeFallH, deadzoneH} = defines

  {AnimationMixin, CameraMixin, DebugMixin, DebugDisplayMixin, TextMixin} = Helpers

  MateLastFrame = 14

  class PlayState extends State

    init: ->
      {@debugging, @developing} = defines
      @detachedCamera = off
      @ended = no

      @debugDisplay = @gui = null
      @cursors = null
      @background = @mate = @platforms = @player = null
      @textLayout = null

      @_initDebugDisplayMixin @game if @debugging or @developing
      _.extend @camera, CameraMixin

      @game.onBlur.add @onBlur, @
      @game.onFocus.add @onFocus, @

      @_initDebugMixin

    create: ->
      @physics.startSystem Physics.ARCADE
      @physics.arcade.gravity.y = 500

      @cursors = @input.keyboard.createCursorKeys()
      # Quit on Q
      @quitKey = @_addKey Keyboard.Q, @quit
      # Quit on click at end.
      @onHit = @input[if @game.device.touch then 'onTap' else 'onUp']
      @onHit.add @quit, @

      if @developing
        @gui = new dat.GUI()
        @gui.add(@, 'debugging').listen().onFinishChange =>
          @background.debugging = @platforms.debugging = @player.debugging = @debugging
          @debugDisplay.reset() unless @debugging
        @gui.add(@, 'detachedCamera').onFinishChange => @_toggleCameraAttachment()
        @gui.add(@, 'ended')
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

      @_toggleCameraAttachment on

    update: ->
      @physics.arcade.collide @player.sprite, @platforms.layer

      @background.update()
      @player.update()

      @_updateVolumeOnPlayerLand()

      @camera.updateShake()
      if @_shakeOnPlayerFall()
        @camera.unfollow()
      else unless @camera.target? or @camera.isShaking()
        @camera.follow @player.cameraFocus

      @camera.updatePositionWithCursors @cursors if @detachedCamera

      @end() if @_isPlayerReadyToEnd()

    render: ->
      @_renderDebugDisplay() if @debugging
      @_renderDebugOverlays() if @debugging

    shutdown: ->
      # Null references to disposable objects we don't own.
      gameObject.destroy() for gameObject in [@background, @inStateMenu, @music, @platforms, @player]

      @game.onBlur.remove @onBlur, @
      @game.onFocus.remove @onFocus, @
      @onHit.remove @quit, @

      key.onDown.removeAll @ for key in [@loudKey, @muteKey, @quietKey, @quitKey]

      @gui?.destroy()

    onBlur: ->
      @music?.pause()

    onFocus: ->
      @music?.resume()

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
      , 5 * Timer.SECOND

    quit: (trigger) ->
      return no unless @ended or trigger instanceof Key
      _quit = => @state.start 'menu', yes
      if @music.volume is 0
        _quit()
      else
        # Fade the music.
        @music.fadeOut 3 * Timer.SECOND
        # Then go back to menu while clearing world.
        @music.onFadeComplete.addOnce _quit

    _addBackground: ->
      parallaxTolerance = mapH - artH
      @background = new Background { parallaxTolerance }, @game
      @background.addImages _.template('bg<%= zIndex %>'), 16
      @background.layout()

    _addInStateMenu: ->
      @inStateMenu = new InStateMenu [
        ['Paused', { fontSize: fontLarge }]
        ['Arrow keys to move', { fontSize: fontSmall }]
        ['Press 0, -, + for volume', { fontSize: fontSmall }]
        ['Press Q to quit', { fontSize: fontSmall }]
      ], @game,
        pauseHandler: (paused) => @player.control = not paused

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

    _addMusic: ->
      @userVolume = 1
      @music = @add.audio 'bgm', 0.2, yes
      @music.mute = @developing or @debugging
      @music.play()
      @gui?.add(@music, 'mute').listen()
      increment = 0.1
      @loudKey = @_addKey Keyboard.EQUALS, => @userVolume += increment
      @muteKey = @_addKey Keyboard.ZERO, => @music.mute = not @music.mute
      @quietKey = @_addKey Keyboard.UNDERSCORE, => @userVolume -= increment

    _addPlatforms: ->
      @platforms = new Platforms 
        mapH: mapH
        tileImageKey: 'balcony'
      , @game, @gui?.addOpenFolder 'platforms'

      @endingPoint = @platforms.ledges[-1...][0].createMidpoint @platforms
      @startingPoint = new Point playerW, @world.height - playerH
      # Use for debugging ending.
      # @startingPoint = @platforms.ledges[-2...-1][0].createMidpoint @platforms

    _addPlayer: ->
      origin = @startingPoint
      @player = new Player { origin }, @game, @cursors, @gui?.addOpenFolder 'player'

    _addText: (text, style) ->
      _.defaults style, { fill: '#fff', font: 'Enriqueta' }
      text = @addCenteredText text, @textLayout, style
      tween = @fadeIn text, Timer.SECOND

    _isPlayerReadyToEnd: ->
      (@player.state is 'still' and @player.control is on and
       @player.sprite.y <= @endingPoint.y)

    _renderDebugDisplay: ->
      @resetDebugDisplayLayout()

      if @player.debugging
        @renderDebugDisplayItems (layoutX, layoutY) =>
          @debugDisplay.bodyInfo @player.sprite, layoutX, layoutY
        , 6
        @renderDebugDisplayItems @player.debugTextItems

    _renderDebugOverlays: ->
      @debugDisplay.body @player.sprite if @player.debugging

    _renderEndingDisplay: ->
      @textLayout = { y: 120, baseline: 40 }

      @_addText 'The End', { fontSize: fontLarge }
        .onComplete.addOnce =>
          @_addText 'Click to play again', { fontSize: fontSmall }
          @ended = yes

    _shakeOnPlayerFall: ->
      return no unless @player.nextState is 'landing' and @player.distanceFallen() > shakeFallH
      @camera.shake()

    _toggleCameraAttachment: (attached) ->
      attached ?= not @detachedCamera
      if attached
        @camera.follow @player.cameraFocus
        @player.cursors ?= @cursors

        @camera.deadzone ?= new Rectangle(
          0, (@game.height - deadzoneH) / 2,
          @game.width, deadzoneH
        )
      else
        @camera.unfollow()
        @player.cursors = null

    _updateVolumeOnPlayerLand: ->
      return no unless @player.nextState is 'landing'
      # The music gets louder the higher the player gets.
      volume = ((@platforms.tilemap.heightInPixels - @player.sprite.y) /
                 @platforms.tilemap.heightInPixels) ** 1.3
      volume *= @math.clamp @userVolume, 0, 2 # Factor in user controls.
      volume = @math.clamp volume, 0.2, 0.8
      @music.fadeTo Timer.SECOND, volume

  _.extend PlayState::, AnimationMixin, DebugMixin, DebugDisplayMixin, TextMixin

  PlayState
