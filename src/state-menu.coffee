# MenuState
# =========
# This state is mostly static presentation, so I'm going to be lazy with docs
# and tests. It has a start button that goes to `PlayState`.

define ['defines', 'helpers'], (defines, Helpers) ->

  'use strict'

  {State} = Phaser

  {domStateEvents, fontLarge, fontSmall} = defines

  {TextMixin} = Helpers

  class MenuState extends State

    init: ->
      if domStateEvents
        e = document.createEvent 'CustomEvent'
        e.initCustomEvent 'state:menu', no, no, undefined
        @game.parent.dispatchEvent e

    create: ->
      @add.image 0, 0, 'bg-start'

      @layout = { y: (@game.height / 4), baseline: 40 }
      @_addText 'Morning Stroll', { fontSize: fontLarge }
      @_addText 'Climb and see!', { fontSize: fontSmall }

      @layout.y += 2 * @layout.baseline
      buttonX = (@game.width - defines.buttonW) / 2
      buttonY = @layout.y - (defines.buttonH / 2)
      @add.button buttonX, buttonY, 'button', @play, @, 1, 0, 2
      # Note the text isn't actually 'in' the button.
      @_addText 'start', { fontSize: fontSmall }

    update: ->

    play: ->
      @state.startWithTransition null, 'play'

    _addText: (text, style) ->
      _.defaults style, { fill: '#fff', font: 'Enriqueta' }
      text = @addCenteredText text, @layout, style

  _.extend MenuState::, TextMixin

  MenuState
