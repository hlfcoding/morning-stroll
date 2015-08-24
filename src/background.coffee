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


    addImages: (nameTemplate, topZIndex, bottomZIndex = 1) ->
      for zIndex in [bottomZIndex..topZIndex]
        name = nameTemplate { zIndex }
        sprite = @group.game.add.sprite 0, 0, name
        @group.addChild sprite
        @layers.push { sprite, zIndex }
      console.log @group.getBounds()

  Background
