define [
  'phaser'
  'underscore'
  'app/defines'
], (Phaser, _, defines) ->

  'use strict'

  {State, Timer} = Phaser

  {buttonH, buttonW, developing, playerH, playerW, progressH, progressW} = defines

  class PreloadState extends State

    init: ->
      _.bindAll @, 'menu', 'update'

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

    update: ->
      @_onceMenu ?= _.once @menu

      if @cache.isSoundDecoded('bgm') then @_onceMenu()
      else @time.events.add Timer.HALF, @update

    menu: _.after 2, ->
      state = if developing then 'play' else 'menu'
      @state.start state

  PreloadState
