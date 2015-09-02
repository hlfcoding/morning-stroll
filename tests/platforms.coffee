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
