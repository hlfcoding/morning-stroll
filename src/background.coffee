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

    constructor: (@height, game) ->
      @layers = []
      @topZIndex = 1

      # Main knobs.
      @parallaxFactor = 0.95
      @parallaxBuffer = 1.7
      @parallaxTolerance = -64

      # - full - Each image is a layer of the full original.
      # - clip - Images are only partial, and clip the transparent leftovers.
      @layoutMode = 'full' # TODO: Support 'clip'.

      @_initialize game

    _initialize: (game) ->
      @group = game.add.group()
      @width = @group.game.width

    addImages: (nameTemplate, topZIndex, bottomZIndex = 1) ->
      @topZIndex = topZIndex
      for zIndex in [bottomZIndex..topZIndex]
        name = nameTemplate { zIndex }
        sprite = @group.game.add.tileSprite 0, 0, @width, @height, name
        @group.addChild sprite
        @layers.push { sprite, zIndex }

    # Apply the scroll factors using a simple algorithm:
    # - Exponential distance (and scroll factor).
    # - Apply a factor to that to increase, as well as a buffer to decrease.
    # Also set the bounds on the entire group, based on the nearest (last) layer.
    layout: ->
      nearest = @nearestLayer()
      farthest = @farthestLayer()

      for {sprite, zIndex} in @layers
        # Factor in exponentially and constrain.
        factor = (zIndex / @layers.length) ** 2 * @parallaxFactor
        # Add buffer to further constrain.
        factor = (factor + @parallaxBuffer / 2) / @parallaxBuffer
        # Shift based on scroll factor for full bg visibility.
        unless zIndex is nearest.zIndex
          sprite.y -= @group.game.height * (1 - factor) - @parallaxTolerance
        # Set scroll factor.
        sprite.scrollFactorY = factor
        # Set shift.
        shift = if zIndex is farthest.zIndex then -farthest.sprite.y else 0
        sprite.y += shift

      # TODO: Remove the need for this magical-number hack.
      # nearest.sprite.y += 12
      # @group.height = shift + nearest.sprite.height / (@parallaxFactor ** 0.32)

      @group.y = -(@group.height - @group.game.height)

    farthestLayer: -> _.findWhere @layers, { zIndex: 1 }
    nearestLayer: -> _.findWhere @layers, { zIndex: @topZIndex }

  Background
