# Platform
# ========
# Platform that can dynamically generate a map, and track the dynamically
# generated ledges. Only supports the `SIDE_TO_SIDE` generation scheme for now.

define [
  'phaser'
], (Phaser) ->

  'use strict'

  class Platforms

    constructor: (@config, game) ->
      @group = game.add.group()

      @group.enableBody = on
      @_initPhysics game.world

    _initPhysics: (world) ->
      @ground = @group.create 0, world.height - @config.groundH # @test
      @ground.width = world.width
      @ground.height = @config.groundH
      @ground.body.collideWorldBounds = on
      @ground.body.immovable = on

  Platforms
