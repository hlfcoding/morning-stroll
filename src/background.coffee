# Background
# ==========
# A gradient of bg and scroll factors based on coefficients.
# We're extending `FlxGroup` b/c there's nothing else. ArrayList would
# be better.

define [
  'underscore'
  'app/defines'
  'app/helpers'
], (_, defines, Helpers) ->

  'use strict'

  {DebugMixin} = Helpers

  class Background

    constructor: (config = {}, game) ->
      @layers = []

      # Main knobs.
      _.defaults config,
        parallaxFactor: 0.95
        parallaxBuffer: 1.7
        # - full - Each image is a layer of the full original.
        # - clip - Images are only partial, and clip the transparent leftovers.
        layoutMode: 'full' # TODO: Support 'clip'.

      {@layoutMode, @parallaxBuffer, @parallaxFactor, @parallaxTolerance} = config

      @_topZIndex = 1

      @_initialize game

    _initialize: (game) ->
      {@add, @camera} = game

      @group = @add.group()
      @group.visible = no

      @_initDebugging()

    _initDebugging: () ->
      @debugNamespace = 'background'

      @_initDebugMixin()
      {@debugging} = defines

    destroy: ->
      # Null references to disposable objects we don't own.

    # Public
    # ------

    addImages: (nameTemplate, topZIndex, bottomZIndex = 1) ->
      @_topZIndex = topZIndex
      for zIndex in [bottomZIndex..topZIndex]
        name = nameTemplate { zIndex }
        image = @add.image 0, 0, name, @group
        image.autoCull = on
        @layers.push { image, zIndex }

    layout: ->
      # Set vertical scroll factor and offset.
      for layer in @layers
        {image, zIndex} = layer
        # Factor in z-index exponentially and constrain.
        factor = (zIndex / @layers.length) ** 2 * @parallaxFactor
        # Add buffer to further constrain.
        factor = (factor + @parallaxBuffer / 2) / @parallaxBuffer
        # Set scroll factor and inverse.
        layer.scrollFactor = Math.min 1, factor
        layer.scrollResistance = Math.max 0, (1 - factor)

      @debug 'layers', @layers

    update: ->
      for {image, zIndex, scrollFactor, scrollResistance} in @layers
        # Closer images change more with camera.
        image.y = @camera.y * scrollResistance

        # Shift based on scroll factor for full visibility of current bg images.
        unless zIndex is 1 # Not farthest.
          image.y += @parallaxTolerance
          unless zIndex is @_topZIndex # Or nearest.
            image.y -= @parallaxTolerance * scrollFactor ** (1 / 3)

  _.extend Background::, DebugMixin

  Background
