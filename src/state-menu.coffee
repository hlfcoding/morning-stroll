define [
  'phaser'
  'app/defines'
], (Phaser, defines) ->

  'use strict'

  class MenuState extends Phaser.State

    init: ->
      @layoutY = 0
      @baseline = 40

    create: ->
      @add.image 0, 0, 'bg-start'

      @layoutY = @world.centerY / 2
      @_addText 'Morning Stroll', { fontSize: 32 }
      @_addText 'Climb and see!', { fontSize: 16 }

      @layoutY += 2 * @baseline
      buttonX = @world.centerX - (defines.buttonW / 2)
      buttonY = @layoutY - (defines.buttonH / 2)
      @add.button buttonX, buttonY, 'button', @play, @, 1, 0, 2
      @_addText 'start', { fontSize: 16 }

    update: ->

    play: ->
      @state.start 'play'

    _addText: (text, style) ->
      _.defaults style,
        boundsAlignH: 'center', boundsAlignV: 'middle'
        fill: '#fff', font: 'Enriqueta'

      text = @add.text @world.centerX, @layoutY, text, style
      text.anchor.setTo 0.5
      @layoutY += text.height + @baseline
      text

  MenuState
