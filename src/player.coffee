# Player
# ======
# Player that has more complex running and jumping abilities. It makes use of an animation
# delegate and has a simple state tracking system. It also takes into account custom offsets. It
# also allows for custom camera tracking. This class is meant to be very configurable and has many
# hooks.

# Dependencies
# ------------
define [
  'phaser'
], (Phaser) ->

  class Player extends Phaser.Sprite

  Player
