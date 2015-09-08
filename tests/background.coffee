define [
  'phaser'
  'underscore'
  'app/background'
  'test/fakes'
], (Phaser, _, Background, fakes) ->

  describe 'Background', ->
    game = null
    bg = null

    beforeEach ->
      spyOn Background::, '_initialize'
      bg = new Background { height: 1000 }
      _.extend bg, fakes.createBackgroundProps(bg)

    describe 'when constructed', ->
      it 'should have set dimensions', ->
        expect(bg.height).toBeDefined()
        expect(bg.width).toBeDefined()

      it 'should be using "full" layout mode', ->
        expect(bg.layoutMode).toBe 'full'

    describe '#layout', ->
      oldSprites = null
      sprites = null

      beforeEach ->
        sprites = _.pluck bg.layers, 'sprite'
        oldSprites = _.chain(sprites).map(_.clone).value()
        bg.layout()

      it 'updates scroll-factors on each layer', ->
        oldFactors = _.pluck oldSprites, 'scrollFactorY'
        newFactors = _.pluck sprites, 'scrollFactorY'
        expect(newFactors).not.toEqual oldFactors

      it 'decreases scroll-factor with z-index', ->
        expect(sprites[0].scrollFactorY).toBeLessThan _.last(sprites).scrollFactorY

      it 'updates y offset for all but nearest layer', ->
        oldOffsets = _.pluck oldSprites, 'y'
        newOffsets = _.pluck sprites, 'y'
        expect(_.difference(newOffsets, oldOffsets).length).toBe (sprites.length - 1)
        expect(newOffsets[0]).toBe oldOffsets[0]
