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
      it 'updates scroll-factors on each layer', ->
        oldFactors = _.pluck bg.layers, 'scrollFactor'
        bg.layout()
        newFactors = _.pluck bg.layers, 'scrollFactor'
        expect(newFactors).not.toEqual oldFactors

      it 'decreases scroll-factor with z-index', ->
        bg.layout()
        expect(bg.layers[0].scrollFactor).toBeLessThan _.last(bg.layers).scrollFactor

      it 'updates y offset for all but nearest layer', ->
        oldOffsets = _.chain(bg.layers).pluck('image').pluck('y')
        bg.layout()
        newOffsets = _.chain(bg.layers).pluck('image').pluck('y')
        expect(_.difference(newOffsets, oldOffsets).length).toBe (bg.layers.length - 1)
        expect(newOffsets[0]).toBe oldOffsets[0]
