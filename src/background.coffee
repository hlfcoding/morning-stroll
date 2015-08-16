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

  class Background extends Phaser.Group

  Background
