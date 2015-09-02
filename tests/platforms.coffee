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

      beforeEach ->
        helpers.configurePlatformsWithDefaults platforms
        state = platforms._createTileGeneratorState()

      it 'returns expected number of columns and rows', ->
        expect(state.numCols).toBe 13
        expect(state.numRows).toBe 91

      it 'returns expected ledge size and row spacing ranges', ->
        expect(state.rangeLedgeSize).toBe 2
        expect(state.rangeRowSpacing).toBe 2

      it 'returns expected base number of ledges', ->
        expect(state.numLedgeRows).toBe 23
