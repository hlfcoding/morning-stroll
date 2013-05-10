define [
  'phaser'
  'app/play-state'
], (Phaser, PlayState) ->

  class MorningStroll extends Phaser.Game

    @WIDTH:   416
    @HEIGHT:  600
    @ID:      'morning-stroll'

    constructor: ->
      super @, 'morning-stroll', C.WIDTH, C.HEIGHT,
            @init, @create, @update

    # Inherited

    # Delegated

    init: ->
    create: ->
      @switchState new PlayState @
    update: ->

    # Public

    start: ->

  C = MorningStroll
