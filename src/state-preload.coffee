define [
  'phaser'
  'app/defines'
], (Phaser, defines) ->

  'use strict'

  class PreloadState extends Phaser.State

    preload: ->
      @load.spritesheet 'button', 'assets/button.png', defines.buttonW, defines.buttonH

      @load.image 'balcony', 'assets/tiles-auto-balcony.png'
      for zIndex in [16..1]
        id = (16 - zIndex + 10000).toString().substr(1)
        @load.image "bg#{zIndex}", "assets/bg-_#{id}_#{zIndex}.png"
      @load.spritesheet 'mate', 'assets/mate.png', defines.playerW, defines.playerH
      @load.spritesheet 'player', 'assets/player.png', defines.playerW, defines.playerH

    create: ->

    update: ->
      @state.start 'menu'

  PreloadState
