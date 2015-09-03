define [
  'phaser'
  'underscore'
  'app/platforms'
  'test/helpers'
], (Phaser, _, Platforms, helpers) ->

  fdescribe 'Platforms', ->
    game = null
    platforms = null

    beforeEach ->
      spyOn Platforms::, '_initialize'
      platforms = new Platforms {}
      _.extend platforms, helpers.createFakePlatformsProps(platforms)
      helpers.configurePlatformsWithDefaults platforms

    describe 'when constructed', ->
      it 'should have set ledge constraints', ->
        expect(platforms.minLedgeSize).toBeDefined()
        expect(platforms.maxLedgeSize).toBeDefined()
        expect(platforms.minLedgeSpacing).toBeDefined()
        expect(platforms.maxLedgeSpacing).toBeDefined()

      it 'should have configured sizes', ->
        expect(platforms.tileWidth).toBeDefined()
        expect(platforms.tileHeight).toBeDefined()

      it 'should have empty ledges array', ->
        expect(platforms.ledges).toEqual []

    describe '_createTileGeneratorState', ->
      state = null

      beforeEach -> state = platforms._createTileGeneratorState()

      it 'returns expected number of columns and rows', ->
        expect(state.numCols).toBe 13
        expect(state.numRows).toBe 91

      it 'returns expected ledge size and row spacing ranges', ->
        expect(state.rangeLedgeSize).toBe 2
        expect(state.rangeRowSpacing).toBe 2

      it 'returns expected base number of ledges', ->
        expect(state.numLedgeRows).toBe 23

    describe '_addLedgeDifficulty', ->
      ledge = null
      vars = { numLedgeRows: 23 }

      beforeEach ->
        ledge = new Platforms.Ledge()
        ledge.index = 1
        ledge.rowIndex = 4
        ledge.size = 4
        ledge.spacing = 3
        ledge.start = 0
        ledge.end = 3
        ledge.facing = 'left'

      it 'makes initial ledges longer and closer together', ->
        platforms._addLedgeDifficulty ledge, vars

        expect(ledge.spacing).toBe 2
        expect(ledge.size).toBe 5
        expect(ledge.end).toBe 4

      it 'makes final ledges shorter and farther apart', ->
        ledge.index = vars.numLedgeRows - 1
        platforms._addLedgeDifficulty ledge, vars

        expect(ledge.spacing).toBe 3
        expect(ledge.size).toBe 4
        expect(ledge.end).toBe 3

      it 'correctly updates start and end values for ledges facing right', ->
        ledge.facing = 'right'
        ledge.start = 8
        ledge.end = 12
        platforms._addLedgeDifficulty ledge, vars

        expect(ledge.start).toBe 7
