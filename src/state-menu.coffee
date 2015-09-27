define [
  'phaser'
  'app/defines'
  'app/helpers'
], (Phaser, defines, Helpers) ->

  'use strict'

  {State} = Phaser

  {fontLarge, fontSmall} = defines

  {TextMixin} = Helpers

  class MenuState extends State

    init: ->

    create: ->
      @add.image 0, 0, 'bg-start'

      @layout = { y: (@game.height / 4), baseline: 40 }
      @_addText 'Morning Stroll', { fontSize: fontLarge }
      @_addText 'Climb and see!', { fontSize: fontSmall }

      @layout.y += 2 * @layout.baseline
      buttonX = (@game.width - defines.buttonW) / 2
      buttonY = @layout.y - (defines.buttonH / 2)
      @add.button buttonX, buttonY, 'button', @play, @, 1, 0, 2
      @_addText 'start', { fontSize: fontSmall }

    update: ->

    play: ->
      @state.start 'play'

    _addText: (text, style) ->
      _.defaults style, { fill: '#fff', font: 'Enriqueta' }
      text = @addCenteredText text, @layout, style

  _.extend MenuState::, TextMixin

  MenuState
