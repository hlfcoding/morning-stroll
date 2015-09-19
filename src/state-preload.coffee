define [
  'phaser'
  'underscore'
  'app/defines'
], (Phaser, _, defines) ->

  'use strict'

  class PreloadState extends Phaser.State

    init: ->
      window.WebFontConfig =
        active: => @time.events.add Phaser.Timer.SECOND, @menu, @
        google: { families: [ 'Enriqueta:400:latin' ] }

    preload: ->
      @load.script 'webfont', '//ajax.googleapis.com/ajax/libs/webfont/1/webfont.js'

      @load.spritesheet 'button', 'assets/button.png', defines.buttonW, defines.buttonH
      @load.image 'bg-start', 'assets/bg-start.jpg'

      @load.image 'balcony', 'assets/tiles-auto-balcony.png'
      for zIndex in [16..1]
        id = (16 - zIndex + 10000).toString().substr(1)
        @load.image "bg#{zIndex}", "assets/bg-_#{id}_#{zIndex}.png"
      @load.spritesheet 'mate', 'assets/mate.png', defines.playerW, defines.playerH
      @load.spritesheet 'player', 'assets/player.png', defines.playerW, defines.playerH

    create: ->

    update: -> @menu()

    menu: _.after 2, ->
      @state.start 'menu'

  PreloadState
