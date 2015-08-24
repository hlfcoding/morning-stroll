# Background
# ==========
# A gradient of bg and scroll factors based on coefficients.
# We're extending `FlxGroup` b/c there's nothing else. ArrayList would
# be better.

# Dependencies
# ------------
define [
  'phaser'
  'underscore'
], (Phaser, _) ->

  'use strict'

  class Background

    constructor: (game) ->
      @group = game.add.group()
      @layers = []
      @topZIndex = 1

      # Main knobs.
      @parallaxFactor = 0.95
      @parallaxBuffer = 1.7
      @parallaxTolerance = -64

      # - full - Each image is a layer of the full original.
      # - clip - Images are only partial, and clip the transparent leftovers.
      @layoutMode = 'full' # TODO: Support 'clip'.

    addImages: (nameTemplate, topZIndex, bottomZIndex = 1) ->
      for zIndex in [bottomZIndex..topZIndex]
        name = nameTemplate { zIndex }
        sprite = @group.game.add.sprite 0, 0, name
        @group.addChild sprite
        @layers.push { sprite, zIndex }
      console.log @group.getBounds()

  Background
