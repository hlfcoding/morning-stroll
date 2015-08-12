# PlayState
# =========
# The main coordinator: part config list, part asset list, part delegate.
# Handles all of the character animations, and custom platform generation.
# The stage is set up based on the bg group's bounds; the platform and
# camera are set up around it.

# Dependencies
# ------------
define [
  'phaser'
  'underscore'
  'app/platforms'
  'app/player'
  'app/background'
], (Phaser, _, Platforms, Player, Background) ->

  class PlayState extends Phaser.State

  PlayState
