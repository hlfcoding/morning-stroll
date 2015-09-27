define [
  'phaser'
  'underscore'
  'app/helpers'
], (Phaser, _, Helpers) ->

  'use strict'

  {Keyboard} = Phaser

  class InStateMenu

    constructor: (@textItems, game, options = {}) ->
      {@baseTextStyle, @pauseHandler, @layout, @toggleKeyCode} = _.defaults options,
        baseTextStyle: { fill: '#fff', font: 'Enriqueta' }
        layout: { y: 120, baseline: 40 }
        pauseHandler: (paused) -> game.paused = paused
        toggleKeyCode: Keyboard.P

      {@add, @height, @input, @width, @world} = game

      @_initialize()

    _initialize: ->
      @group = @add.group null, 'in-state-menu', yes

      @overlay = @add.graphics 0, 0, @group
      @overlay.beginFill 0x000000, 0.2
      @overlay.drawRect 0, 0, @width, @height
      @overlay.endFill()

      @_addText text, style for [text, style] in @textItems
      @_addText 'Press P again to continue', { fontSize: 16 }

      @toggleKey = @input.keyboard.addKey @toggleKeyCode
      @toggleKey.onDown.add => @toggle()
      @input.keyboard.removeKeyCapture @toggleKeyCode

      @toggle off

      @_initDebugging()

    _initDebugging: ->
      @debugNamespace = 'in-state-menu'
      completedInit = @_initDebugMixin()
      @tracing = on

    destroy: ->
      @toggleKey.onDown.removeAll()

    toggle: (toggled) ->
      toggled ?= not @group.visible
      @group.visible = toggled
      @pauseHandler toggled

    _addText: (text, style) ->
      _.defaults style, @baseTextStyle
      @addCenteredText text, @layout, style, @group

  _.extend InStateMenu::, Helpers.DebugMixin, Helpers.TextMixin

  InStateMenu
