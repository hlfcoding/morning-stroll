```coffee
  Collision = Phaser.Collision
  Point = Phaser.Point
  Rectangle = Phaser.Rectangle
  # Requires inherited properties:
  State = Phaser.State

  class PlayState extends State

    # Properties
    # ----------

    # Some game switches.
    _shouldCheckFalling: undefined

    # Game state helpers.
    _didEnding: undefined

    # Phaser Methods
    # --------------

    # `create`
    create: ->

      # - Set globals.
      @_shouldCheckFalling = off

      # - Internals.
      #   Don't do expensive operations too often, if possible.
      _didEnding = no

  # Alias class.
  C = PlayState
```
