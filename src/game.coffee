# Game
# ====
# Singleton for handling our game. Similar to `FlxGame`.

# Dependencies
# ------------
define [
  'phaser'
  'app/play-state'
], (Phaser, PlayState) ->

  class MorningStroll extends Phaser.Game

    # Properties
    # ----------

    @WIDTH:   416
    @HEIGHT:  600
    @ID:      'morning-stroll'

    # Phaser Methods
    # --------------

    constructor: ->
      super @, 'morning-stroll', C.WIDTH, C.HEIGHT,
            @onInit, @onCreate, @onUpdate

    # Own Methods
    # -----------

    onInit: ->
    onCreate: ->
      @switchState new PlayState @
    onUpdate: ->

    start: ->

  # Alias class.
  C = MorningStroll
