define [
  'phaser'
  'underscore'
  'app/background'
  'test/helpers'
], (Phaser, _, Background, helpers) ->

  describe 'Background', ->
    game = null
    bg = null

    beforeEach ->
      spyOn Background::, '_initialize'
      bg = new Background { height: 1000 }
      _.extend bg, helpers.createFakeBackgroundProps(bg)

    describe 'when initialized', ->
      it 'should have set dimensions', ->
        expect(bg.height).toBeDefined()
        expect(bg.width).toBeDefined()

      it 'should have added group to game', ->
        expect(bg.group).toBeDefined()

      it 'should be using "full" layout mode', ->
        expect(bg.layoutMode).toBe 'full'

    describe '#layout', ->
      oldSprites = null
      sprites = null

      beforeEach ->
        sprites = _.pluck bg.layers, 'sprite'
        oldSprites = _.chain(sprites).map(_.clone).value()
        bg.layout()

      it 'should update scroll-factors on each layer', ->
        oldFactors = _.pluck oldSprites, 'scrollFactorY'
        newFactors = _.pluck sprites, 'scrollFactorY'
        expect(newFactors).not.toEqual oldFactors

      it 'should decrease scroll-factor with z-index', ->
        expect(sprites[0].scrollFactorY).toBeLessThan _.last(sprites).scrollFactorY

      it 'should update y offset for all but nearest layer', ->
        oldOffsets = _.pluck oldSprites, 'y'
        newOffsets = _.pluck sprites, 'y'
        expect(_.difference(newOffsets, oldOffsets).length).toBe (sprites.length - 1)
        expect(newOffsets[0]).toBe oldOffsets[0]
