define [
  'phaser'
  'underscore'
  'app/helpers'
], (Phaser, _, Helpers) ->

  DebugMixin = Helpers.DebugMixin

  describe 'Helpers.DebugMixin', ->
    obj = null

    beforeEach ->
      class SomeObject
      _.extend SomeObject::, DebugMixin
      obj = new SomeObject()

    describe '#_initDebugMixin', ->
      it 'initializes debug-related flags', ->
        completedInit = obj._initDebugMixin()
        expect(obj.debugging).toBeDefined()
        expect(obj.tracing).toBeDefined()
        expect(completedInit).toBe no

      it 'creates #debugTextItems key-value store for info for Phaser.Utils.Debug', ->
        obj._initDebugMixin()
        expect(obj.debugTextItems).toEqual {}

      it 'sets up gui (folder) if provided one', ->
        gui = { add: -> }
        spyOn(gui, 'add').and.returnValue jasmine.createSpyObj('control', ['onFinishChange'])

        completedInit = obj._initDebugMixin gui
        expect(obj.gui).toBe gui
        expect(gui.add).toHaveBeenCalledWith obj, 'debugging'
        expect(gui.add).toHaveBeenCalledWith obj, 'tracing'
        expect(completedInit).toBe yes

    describe '#debug', ->
      beforeEach ->
        spyOn console, 'trace'
        obj._initDebugMixin()

      it 'only works if debugging flag is on', ->
        obj.debugging = off

        obj.debug 'someItem', 'value'
        expect(console.trace).not.toHaveBeenCalled()
        expect(obj.debugTextItems).toEqual {}

      it 'calls console.trace with namespaced label instead if tracing flag is on', ->
        obj.tracing = on
        obj.debugNamespace = 'obj'

        obj.debug 'someItem', 'value'
        expect(console.trace).toHaveBeenCalledWith 'obj:someItem', 'value'
        expect(obj.debugTextItems).toEqual {}

      it 'truncates float values to 2 fixed decimal places', ->
        obj.debug 'someFloat', 1.2345
        expect(obj.debugTextItems.someFloat).toBe 'someFloat: 1.23'

      it 'serializes Phaser.Point values to simple text', ->
        obj.debug 'somePoint', new Phaser.Point(1, 1)
        expect(obj.debugTextItems.somePoint).toBe 'somePoint: x: 1, y: 1'

      it 'allows including details hash to complement value', ->
        obj.debug 'someItem', 'value', { someDetail: 'detailValue' }
        expect(obj.debugTextItems.someItem).toBe 'someItem: value someDetail: detailValue'

    describe '#_prettyPoint', ->
      it 'converts a Phaser.Point to hash form', ->
        point = new Phaser.Point 1, 1
        expect(obj._prettyPoint(point)).toEqual { x: 1, y: 1 }

    describe '#_prettyHash', ->
      it 'stringifies and simplifies a hash into readable text', ->
        hash = { a: 1, b: { c: 2 } }
        expect(obj._prettyHash(hash)).toBe 'a: 1, b: c: 2'
