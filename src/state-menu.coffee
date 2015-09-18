define [
  'phaser'
  'app/defines'
], (Phaser, defines) ->

  'use strict'

  class MenuState extends Phaser.State

    create: ->
      @add.button 100, 100, 'button', @play, @, 1, 0, 2

    update: ->

    play: ->
      @state.start 'play'

  MenuState
