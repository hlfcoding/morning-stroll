# Game
# ====
# Singleton for handling our game. Similar to `FlxGame`.

# Dependencies
# ------------
define [
  'phaser'
  'underscore'
  'app/play-state'
], (Phaser, _, PlayState) ->

  Tilemap = Phaser.Tilemap

  class MorningStroll extends Phaser.Game

    # Properties
    # ----------

    @WIDTH:   416
    @HEIGHT:  600
    @ID:      'morning-stroll'

    @BGS:  [1..16]

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
      @load.tilemap 'balcony', @assetURL('tiles-auto-balcony.png'), null, '', Tilemap.CSV
      @load.image 'mate', @assetURL('mate')
      @load.spritesheet 'player', @assetURL('player.png'),
        PlayState.PLAYER_WIDTH, PlayState.PLAYER_HEIGHT
      @load.audio 'bgm', ['morning-stroll.mp3'], yes
      pad = '0000'
      for i in [1...C.BGS]
        @load.image "bg#{i}", @bgAssetURL(i)

    onCreate: ->
      @switchState new PlayState @
    onUpdate: ->

    start: ->

    assetURL: (file) -> "assets/#{file}"

    bgAssetURL: (n) ->
      file = ("#{pad}#{i}").slice -pad.length
      file = "bg-_#{file}_i.png"
      @assetURL file

  # Alias class.
  C = MorningStroll
