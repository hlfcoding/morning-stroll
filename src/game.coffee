# Game
# ====
# Configures our Phaser.Game through composition.

# Dependencies
# ------------
define [
  'phaser'
  'underscore'
  'app/play-state'
], (Phaser, _, PlayState) ->

  class MorningStroll

    constructor: ->
      _.bindAll @, 'onPreload', 'onCreate', 'onUpdate'

      width = 416
      height = 600
      renderer = Phaser.AUTO
      parentElementId = 'morning-stroll'
      states =
        preload: @onPreload
        create: @onCreate
        update: @onUpdate

      @game = new Phaser.Game width, height, renderer, parentElementId, states

    onPreload: ->

    onCreate: ->

    onUpdate: ->

  MorningStroll
