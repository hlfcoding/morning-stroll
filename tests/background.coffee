define ['background', 'test/fakes'], (Background, fakes) ->

  describe 'Background', ->
    game = null
    bg = null

    beforeEach ->
      spyOn Background::, '_initialize'
      bg = new Background { parallaxTolerance: 240 }
      _.extend bg, fakes.createBackgroundProps(bg)

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
