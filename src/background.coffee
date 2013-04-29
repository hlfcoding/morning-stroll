define [
  'phaser'
], (Phaser) ->

  Group = Phaser.Group
  Rectangle = Phaser.Rectangle

  class Background extends Phaser.Group

    #
    # Main knobs.
    #
    parallaxFactor: 0.9
    parallaxBuffer: 2.0
    parallaxTolerance: 0
    #
    # To work with our foreground.
    #
    bounds: null
    #
    # Modes:
    #
    # - Clip backgrounds: Images are only partial, and clip the transparent leftovers.
    # - Full backgrounds: Each image is the full original.
    mode: 0
    @CLIP_BGS: 1
    @FULL_BGS: 2
    #
    # Phaser Methods
    # --------------
    constructor: (@game, @maxSize=0) ->
      @bounds = new Rectangle()
      @mode = C.FULL_BGS
      super @game, @maxSize
    destroy: ->
      super()
      @bounds = null
    #
    # Own Methods
    # -----------
    layout: ->


  C = Background
