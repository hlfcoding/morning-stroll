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
  'app/helpers'
], (Phaser, _, Helpers) ->

  'use strict'

  class Background

    constructor: (@config, game) ->
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

      @camera = game.camera

      @_initDebugging()

    _initDebugging: () ->
      @debugNamespace = 'background'

      @_initDebugMixin()

    # Public
    # ------

    addImages: (nameTemplate, topZIndex, bottomZIndex = 1) ->
      @topZIndex = topZIndex
      for zIndex in [bottomZIndex..topZIndex]
        name = nameTemplate { zIndex }
        image = @group.game.add.image 0, 0, name, @group
        @layers.push { image, zIndex }

    layout: ->
      # Set vertical scroll factor and offset.
      for layer in @layers
        {image, zIndex} = layer
        # Factor in z-index exponentially and constrain.
        factor = (zIndex / @layers.length) ** 2 * @parallaxFactor
        # Add buffer to further constrain.
        factor = (factor + @parallaxBuffer / 2) / @parallaxBuffer
        factor = Math.min 1, factor
        # Set scroll factor.
        layer.scrollFactor = factor


      @debug 'layers', @layers

    update: ->
      for {image, scrollFactor} in @layers
        # y-offset decreases with closer layers
        image.y = @camera.y * (1 - scrollFactor)


  _.extend Background::, Helpers.DebugMixin

  Background
