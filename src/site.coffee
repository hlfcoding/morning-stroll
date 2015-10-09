define [
  'app/defines'
], (defines) ->

  'use strict'

  _game = null

  # Fiddle:

  if window.history
    history.pushState { fiddle: off }, document.title

    fiddle = document.querySelector '#fiddle'
    fiddle.addEventListener 'click', ->
      defines.developing = on
      history.pushState { fiddle: on }, "#{document.title} (fiddling)", 'fiddle'
      fiddle.classList.add 'invisible'
      fiddle.setAttribute 'disabled', ''

    window.addEventListener 'popstate', (e) ->
      if _game.state.current is 'play'
        location.reload()
      else if e.state.fiddle is off
        defines.developing = off
        fiddle.classList.remove 'invisible'
        fiddle.removeAttribute 'disabled'

  # Dependencies:

  site =
    setGame: (game) -> _game = game
