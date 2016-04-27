define ['helpers'], (Helpers) ->

  {AnimationMixin, CameraMixin, DebugMixin} = Helpers

  obj = null
  beforeEach -> obj = {}; return

  describe 'Helpers.AnimationMixin', ->
    beforeEach ->
      _.extend obj, AnimationMixin
      return

    describe '#playAnimation', ->
      beforeEach ->
        obj.animations = { play: (name) -> { name } } # Fake.
        obj.animation = { isPlaying: no } # Fake.
        return

      it 'plays if allowed to interrupt or current animation isn\'t playing',
      ->
        expect(obj.playAnimation('foo')).not.toBe no

        obj.animation = { isPlaying: yes }
        expect(obj.playAnimation('foo', no)).toBe no
        return

      it 'sets frame if given a number', ->
        obj.playAnimation 1
        expect(obj.animation).toBeNull()
        expect(obj.animations.frame).toBe 1
        return

      it 'plays animation if given a string, but only if it\'s different', ->
        expect(obj.playAnimation('foo')).toBeDefined()
        expect(obj.animation).toBeDefined()
        expect(obj.playAnimation('foo')).toBe no
        return
      return
    return

  describe 'Helpers.DebugMixin', ->
    beforeEach ->
      _.extend obj, DebugMixin
      return

    describe '#_initDebugMixin', ->
      it 'initializes debug-related flags', ->
        completedInit = obj._initDebugMixin()
        expect(obj.debugging).toBeDefined()
        expect(obj.tracing).toBeDefined()
        expect(completedInit).toBe no
        return

      it 'creates #debugTextItems key-value store for info for
      Phaser.Utils.Debug', ->
        obj._initDebugMixin()
        expect(obj.debugTextItems).toEqual {}
        return

      it 'sets up gui (folder) if provided one', ->
        gui = { add: -> }
        spyOn(gui, 'add').and.returnValue(
          jasmine.createSpyObj 'control', ['listen', 'onFinishChange']
        )

        completedInit = obj._initDebugMixin gui
        expect(obj.gui).toBe gui
        expect(gui.add).toHaveBeenCalledWith obj, 'debugging'
        expect(gui.add).toHaveBeenCalledWith obj, 'tracing'
        expect(completedInit).toBe yes
        return
      return

    describe '#debug', ->
      beforeEach ->
        spyOn console, 'trace'
        obj._initDebugMixin()
        return

      it 'only works if debugging flag is on', ->
        obj.debugging = off

        obj.debug 'someItem', 'value'
        expect(console.trace).not.toHaveBeenCalled()
        expect(obj.debugTextItems).toEqual {}
        return

      it 'calls console.trace with namespaced label instead if tracing flag is
      on', ->
        obj.tracing = on
        obj.debugNamespace = 'obj'

        obj.debug 'someItem', 'value'
        expect(console.trace).toHaveBeenCalledWith 'obj:someItem', 'value'
        expect(obj.debugTextItems).toEqual {}
        return

      it 'calls console.table instead for values that are 2D arrays', ->
        # Since they are too big to render on game screen.
        if console.table? then spyOn(console, 'table')
        else console.table = jasmine.createSpy('table')
        spyOn console, 'groupCollapsed'
        spyOn console, 'groupEnd'
        obj.debugNamespace = 'obj'

        obj.debug 'someTable', [[0],[1]]
        expect(console.groupCollapsed).toHaveBeenCalledWith 'obj:someTable'
        expect(console.table).toHaveBeenCalledWith [[0],[1]]
        expect(console.groupEnd).toHaveBeenCalled()
        expect(obj.debugTextItems).toEqual {}
        return

      it 'truncates float values to 2 fixed decimal places', ->
        obj.debug 'someFloat', 1.2345
        expect(obj.debugTextItems.someFloat).toBe 'someFloat: 1.23'
        return

      it 'serializes Phaser.Point values to simple text', ->
        obj.debug 'somePoint', new Phaser.Point(1, 1)
        expect(obj.debugTextItems.somePoint).toBe 'somePoint: x: 1, y: 1'
        return

      it 'allows including details hash to complement value', ->
        obj.debug 'someItem', 'value', { someDetail: 'detailValue' }
        expect obj.debugTextItems.someItem
          .toBe 'someItem: value someDetail: detailValue'
        return
      return

    describe '#_prettyPoint', ->
      it 'converts a Phaser.Point to hash form', ->
        point = new Phaser.Point 1, 1
        expect(obj._prettyPoint(point)).toEqual { x: 1, y: 1 }
        return
      return

    describe '#_prettyHash', ->
      it 'stringifies and simplifies a hash into readable text', ->
        hash = { a: 1, b: { c: 2 } }
        expect(obj._prettyHash(hash)).toBe 'a: 1, b: c: 2'
        return
      return
    return

  describe 'Helpers.autoSetTiles', ->
    it 'sets solid tiles to correct variants based on adjacent tiles', ->
      results = Helpers.autoSetTiles [
        [0,0,0,0,0]
        [1,1,0,1,1]
        [1,1,0,1,1]
        [0,0,0,0,0]
      ]
      expect(results).toEqual [
        [0,0,0,0,0]
        [15,13,0,7,15]
        [12,10,0,4,12]
        [0,0,0,0,0]
      ]
      return
    return
  return
