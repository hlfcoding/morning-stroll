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

  class MorningStroll extends Phaser.Game

  MorningStroll
