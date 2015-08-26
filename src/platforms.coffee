# Platform
# ========
# Platform that can dynamically generate a map, and track the dynamically
# generated ledges. Only supports the `SIDE_TO_SIDE` generation scheme for now.

define [
  'phaser'
], (Phaser) ->

  'use strict'

  Tile =
    Empty: 0
    Solid: 1
    Meta: 2

  class Platforms

    constructor: (@config, game, gui) ->
      @_initialize game, gui

    _initialize: (game, gui) ->
      @minLedgeSize = 3
      @maxLedgeSize = 5
      @minLedgeSpacing = new Phaser.Point 4, 2
      @maxLedgeSpacing = new Phaser.Point 8, 4
      @ledgeThickness = 2
      @tileWidth = @tileHeight = 32

      @group = game.add.group()
      @group.enableBody = on
      @_initPhysics game.world

      @tilemap = game.add.tilemap null, @tileWidth, @tileHeight
      console.log @tilemap.width
      @ledges = []

    _initPhysics: (world) ->
      @ground = @group.create 0, world.height - @config.groundH # @test
      @ground.width = world.width
      @ground.height = @config.groundH
      @ground.body.collideWorldBounds = on
      @ground.body.immovable = on

    makeMap: ->
      @_generateTiles() unless @tiles?
      @tilemap.createFromTiles @tiles, null, @config.tileImageKey, 0, @group

    _generateTiles: ->
      @_generator = {}
      @tiles = []

    _addRow: ->
    _setupEmptyRow: ->
    _setupFloorRow: ->
    _setupLedgeRow: ->
    _setupEachRow: ->

  class Ledge

    constructor: (@index, @rowIndex, @size, @spacing, @start, @end, @facing) ->


  Platforms
