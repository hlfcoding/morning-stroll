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

    constructor: (width, height, renderer, parent, state, transparent, antialias) ->
      width = C.WIDTH
      height = C.HEIGHT
      renderer = Phaser.AUTO
      parent = C.ID
      state =
        preload: @onPreload
        create: @onCreate
        update: @onUpdate
      super arguments...

    # Own Methods
    # -----------

    onPreload: ->
      @load.image 'mate', @asset_url('mate')
      @load.spritesheet 'player', @asset_url('player.png'),
        PlayState.PLAYER_WIDTH, PlayState.PLAYER_HEIGHT
    onCreate: ->
      @switchState new PlayState @
    onUpdate: ->

    start: ->

    asset: (url) -> "assets/#{url}"

  # Alias class.
  C = MorningStroll
