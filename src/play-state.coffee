define [
  'phaser'
], () ->

  class PlayState extends Phaser.State
    #
    # The dynamically generated and extended Tilemap.
    #
    _platform: null
    _fallChecking: undefined
    @FLOOR_HEIGHT: 32
    #
    # The extend Sprite.
    #
    @PLAYER_WIDTH: 72
    @PLAYER_HEIGHT: 72
    _player: null
    _mate: null

    create: ->

  C = PlayState
