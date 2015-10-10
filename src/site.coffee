define [
  'app/defines'
], (defines) ->

  'use strict'

  _game = null

  document.body.className = 'ready'

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

  # About:

  style = window.getComputedStyle document.querySelector('#framed') 
  flipDuration = parseFloat(style['transition-duration']) + parseFloat(style['transition-delay'])
  flipDuration *= 1000
  frame = document.querySelector '#frame'
  toggleAbout = document.querySelector '#toggle-about'

  toggleAbout.addEventListener 'click', ->
    frame.classList.toggle 'flipped'

    frame.classList.add 'flipping'
    toggleAbout.setAttribute 'disabled', ''
    setTimeout ->
      frame.classList.remove 'flipping'
      toggleAbout.removeAttribute 'disabled'
    , flipDuration

  # Dependencies:

  site =
    setGame: (game) -> _game = game
