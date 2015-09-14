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
      @height = @config.height

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
      # Offset group by its original (map) height while it's not resized from
      # the layer shifting below.
      # @group.y = -(@group.height - @group.game.height)

      # Set vertical scroll factor and offset.
      nearest = @_nearestLayer()
      farthest = @_farthestLayer()
      for layer in @layers
        {image, zIndex} = layer
        # Factor in z-index exponentially and constrain.
        factor = (zIndex / @layers.length) ** 2 * @parallaxFactor
        # Add buffer to further constrain.
        factor = (factor + @parallaxBuffer / 2) / @parallaxBuffer
        # TODO: Shift based on scroll factor for full bg visibility.
        # unless zIndex is nearest.zIndex
          # image.y -= @group.game.height * (1 - factor) - @parallaxTolerance
        # Set scroll factor.
        layer.scrollFactor = factor
        # TODO: Set shift.
        shift = if zIndex is farthest.zIndex then -farthest.image.y else 0
        # image.y += shift

      # TODO: Remove the need for this magical-number hack.
      # nearest.sprite.y += 12
      # @group.height = shift + nearest.sprite.height / (@parallaxFactor ** 0.32)

      @debug 'layers', @layers

    # Helpers
    # -------

    _farthestLayer: -> _.findWhere @layers, { zIndex: 1 }
    _nearestLayer: -> _.findWhere @layers, { zIndex: @topZIndex }

  _.extend Background::, Helpers.DebugMixin

  Background
