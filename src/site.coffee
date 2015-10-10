define [
  'app/defines'
], (defines) ->

  'use strict'

  _game = null

  document.body.className = 'ready'
  {classlist, csstransitions, history, prefixedCSS} = Modernizr

  # Fiddle:

  if history
    window.history.replaceState { fiddle: off }, document.title

    fiddle = document.querySelector '#fiddle'
    fiddle.addEventListener 'click', ->
      defines.developing = on
      window.history.pushState { fiddle: on }, "#{document.title} (fiddling)", 'fiddle'
      fiddle.setAttribute 'disabled', ''

    window.addEventListener 'popstate', (e) ->
      if _game.state.current is 'play'
        window.location.reload()
      else if e.state.fiddle is off
        defines.developing = off
        fiddle.removeAttribute 'disabled'

    gameParent = document.querySelector '#morning-stroll'
    gameParent.addEventListener 'state:play', ->
      fiddle.setAttribute 'disabled', ''

    gameParent.addEventListener 'state:menu', ->
      fiddle.removeAttribute 'disabled'
      window.history.back() if window.history.state.fiddle is on

  # About:

  if classlist and csstransitions
    style = window.getComputedStyle document.querySelector('#framed') 
    flipDuration = (
      parseFloat(style[prefixedCSS('transition-duration')]) +
      parseFloat(style[prefixedCSS('transition-delay')])
    ) * 1000
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
