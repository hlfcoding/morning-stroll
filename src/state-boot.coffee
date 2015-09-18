define [
  'phaser'
], (Phaser) ->

  'use strict'

  class BootState extends Phaser.State

    init: ->
      @input.maxPointers = 1
      @stage.disableVisibilityChange = on

    preload: ->

    create: ->
      @state.start 'preload'

  BootState
