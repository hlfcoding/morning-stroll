# BootState
# =========
# This is the first state. It just preloads the assets required for the
# following `PreloadState`. Some system settings are also done here. Potentially
# more when the game becomes responsive.

define [], ->

  class BootState extends Phaser.State

    init: ->
      @input.maxPointers = 1
      @stage.disableVisibilityChange = on
      return

    preload: ->
      @load.image 'progress-bar-bg', 'assets/progress-bar-bg.png'
      @load.image 'progress-bar-fg', 'assets/progress-bar-fg.png'
      return

    create: ->
      @state.start 'preload'
      return

  BootState
