define [
  'phaser'
  'underscore'
  'app/defines'
], (Phaser, _, defines) ->

  'use strict'

  class PreloadState extends Phaser.State

    init: ->
      _.bindAll @, 'menu', 'update'

      window.WebFontConfig =
        active: => @time.events.add Phaser.Timer.SECOND, @menu
        google: { families: [ 'Enriqueta:400:latin' ] }

    preload: ->
      x = @world.centerX - (defines.progressW / 2)
      y = @world.centerY - (defines.progressH / 2)
      @progressTrack = @add.sprite x, y, 'progress-bar-bg'
      @progressThumb = @add.sprite x, y, 'progress-bar-fg'
      @load.setPreloadSprite @progressThumb

      @load.script 'webfont', '//ajax.googleapis.com/ajax/libs/webfont/1/webfont.js'
      @load.audio 'bgm', ['assets/morning-stroll.mp3'], yes

      @load.spritesheet 'button', 'assets/button.png', defines.buttonW, defines.buttonH
      @load.image 'bg-start', 'assets/bg-start.jpg'

      @load.image 'balcony', 'assets/tiles-auto-balcony.png'
      for zIndex in [16..1]
        id = (16 - zIndex + 10000).toString().substr(1)
        @load.image "bg#{zIndex}", "assets/bg-_#{id}_#{zIndex}.png"
      @load.spritesheet 'mate', 'assets/mate.png', defines.playerW, defines.playerH
      @load.spritesheet 'player', 'assets/player.png', defines.playerW, defines.playerH

    create: ->
      @progressThumb.cropEnabled = off

    update: ->
      @_onceMenu ?= _.once @menu

      if @cache.isSoundDecoded('bgm') then @_onceMenu()
      else @time.events.add Phaser.Timer.HALF, @update

    menu: _.after 2, ->
      state = if defines.developing then 'play' else 'menu'
      @state.start state

  PreloadState
