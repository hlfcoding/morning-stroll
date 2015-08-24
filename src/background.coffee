# Background
# ==========
# A gradient of bg and scroll factors based on coefficients.
# We're extending `FlxGroup` b/c there's nothing else. ArrayList would
# be better.

# Dependencies
# ------------
define [
  'phaser'
], (Phaser) ->

  'use strict'

  class Background

    constructor: (game) ->
      @group = game.add.group()

    addImage: (name) ->
      @group.game.add.sprite 0, 0, name

  Background
