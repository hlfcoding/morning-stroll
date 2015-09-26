define [
  'phaser'
  'underscore'
  'app/helpers'
], (Phaser, _, Helpers) ->

  'use strict'

  {Keyboard} = Phaser

  class InStateMenu

    constructor: (@textItems, @game, @options) ->
      @_initialize()

    _initialize: ->
      @group = @game.add.group()

      @overlay = @game.add.graphics 0, 0, @group
      @overlay.beginFill 0x000000, 0.2
      @overlay.drawRect 0, 0, @game.width, @game.height
      @overlay.endFill()

      @add = @game.add # For TextMixin.
      @world = @game.world # For TextMixin.
      @layout = @options?.layout or { y: 120, baseline: 40 }
      for [text, style] in @textItems
        _.defaults style, { fill: '#fff', font: 'Enriqueta' }
        @addCenteredText text, @layout, style, @group 

      @toggleKey = @game.input.keyboard.addKey @options?.hotkey or Keyboard.P
      @toggleKey.onDown.add @toggle, @

      @toggle off

    destroy: ->
      @toggleKey.onDown.removeAll()

    toggle: (visible) ->
      visible ?= not @group.visible
      @group.visible = visible

  _.extend InStateMenu::, Helpers.TextMixin

  InStateMenu
