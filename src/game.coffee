define [
  'app/play-state'
  # Only non-exports after this point.
  'phaser'
], (PlayState) ->

  class MorningStroll extends Phaser.Game

    @WIDTH:   416
    @HEIGHT:  600
    @ID:      'morning-stroll'

    constructor: ->
      super @, 'morning-stroll', MorningStroll.WIDTH, MorningStroll.HEIGHT,
            @init, @create, @update

    # Inherited

    # Delegated

    init: ->
    create: ->
    update: ->

    # Public

    start: ->
      @switchState new PlayState @
