# BootState
# =========
# This is the first state. It just preloads the assets required for the
# following `PreloadState`. Some system settings are also done here. Potentially
# more when the game becomes responsive.

define [
  'phaser'
], (Phaser) ->

  'use strict'

  class BootState extends Phaser.State

    init: ->
      @input.maxPointers = 1
      @stage.disableVisibilityChange = on

    preload: ->
      @load.image 'progress-bar-bg', 'assets/progress-bar-bg.png'
      @load.image 'progress-bar-fg', 'assets/progress-bar-fg.png'

    create: ->
      @state.start 'preload'

  BootState
