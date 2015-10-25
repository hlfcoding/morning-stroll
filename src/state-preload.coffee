# PreloadState
# ============
# This is the main state before `PlayState`. It loads all assets used by
# subsequent states and renders a progress-bar. Not all assets are easy to load,
# so there's additional complexity to handle. Read on.

define ['defines'], (defines) ->

  'use strict'

  {State, Timer} = Phaser

  {buttonH, buttonW, developing, playerH, playerW, progressH, progressW} = defines

  class PreloadState extends State

    init: ->
      _.bindAll @, 'menu', 'update'

      # One area of additional complexity is Google webfont loading, given that
      # the font needs to be loaded before any Phaser text using it renders.
      window.WebFontConfig =
        active: => @time.events.add Timer.SECOND, @menu
        google: { families: [ 'Enriqueta:400:latin' ] }

    preload: ->
      x = @world.centerX - (progressW / 2)
      y = @world.centerY - (progressH / 2)
      @progressTrack = @add.sprite x, y, 'progress-bar-bg'
      @progressThumb = @add.sprite x, y, 'progress-bar-fg'
      @load.setPreloadSprite @progressThumb

      @load.script 'webfont', '//ajax.googleapis.com/ajax/libs/webfont/1/webfont.js'
      @load.audio 'bgm', ['assets/morning-stroll.mp3'], yes

      @load.spritesheet 'button', 'assets/button.png', buttonW, buttonH
      @load.image 'bg-start', 'assets/bg-start.jpg'

      @load.image 'balcony', 'assets/tiles-auto-balcony.png'
      for zIndex in [16..1]
        id = (16 - zIndex + 10000).toString().substr(1)
        @load.image "bg#{zIndex}", "assets/bg-_#{id}_#{zIndex}.png"
      @load.spritesheet 'mate', 'assets/mate.png', playerW, playerH
      @load.spritesheet 'player', 'assets/player.png', playerW, playerH

    create: ->
      @progressThumb.cropEnabled = off

    # Another is waiting (polling) for audio to decode before proceeding to next
    # state in `update`. Note the use of `_.once` due to the update loop.
    update: ->
      @_onceMenu ?= _.once @menu

      if @cache.isSoundDecoded('bgm') then @_onceMenu()
      else @time.events.add Timer.HALF, @update

    # Given the above two cases of deferred state change, we need to guard the
    # state change to wait until both conditions are satisfied.
    menu: _.after 2, ->
      # Also, if `developing` is on, this state goes to `PlayState` directly for
      # convenience.
      state = if developing then 'play' else 'menu'
      @state.start state

  PreloadState
