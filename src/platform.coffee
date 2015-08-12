# Platform
# ========
# Platform that can dynamically generate a map, and track the dynamically
# generated ledges. This makes up for `FlxTilemap`'s lack of an API to get
# tile groups (ledges) that have meta-data. Only supports the `SIDE_TO_SIDE`
# generation scheme for now.

# Dependencies
# ------------
define [
  'phaser'
], (Phaser) ->

  class Platform extends Phaser.Tilemap

  Platform
