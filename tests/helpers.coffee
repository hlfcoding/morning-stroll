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

