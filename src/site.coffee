# Site 
# ====
# This module is actually just a DOM-ready script for various bits of site
# functionality supporting the actual game.

define ['defines'], (defines) ->

  'use strict'

  # Use Modernizr to do browser feature detection. Except if a browser feature
  # does not exist, the related feature just gets disabled. Not worth it to
  # write fallback behavior mostly just for IE9.
  {classlist, csstransitions, history, prefixedCSS} = Modernizr

  Site = {}

  # Fiddle
  # ------
  # This feature allows the player to configure game variables to experiment and
  # do more complex play-testing.
  Site.initFiddle = (game) ->

    # The History API will be required. Start off with fiddle flag off.
    return unless history
    window.history.replaceState { fiddle: off }, document.title

    # The fiddle button just allows access to global developing flag, which gets
    # used throughout the game code. State is visually represented by the url
    # updating and the button disabling (it's styled to become invisible).
    # Note that because there's no server code, going directly to the `/fiddle`-
    # appended url won't work.
    fiddle = document.querySelector '#fiddle'
    fiddle.addEventListener 'click', ->
      defines.developing = on
      window.history.pushState { fiddle: on }, "#{document.title} (fiddling)", 'fiddle'
      fiddle.setAttribute 'disabled', ''

    # With url integration, hitting the back button will turn off fiddling,
    # since the button gets disabled. But if the game is already being played, a
    # reload will be needed to reset game state so re-initialization can occur
    # with the updated developing flag.
    window.addEventListener 'popstate', (e) ->
      if _game.state.current is 'play'
        window.location.reload()
      else if e.state.fiddle is off
        defines.developing = off
        fiddle.removeAttribute 'disabled'

    # When the game's play state starts, the button becomes pointless (given
    # this necessary reload) and should hide even if fiddling is off.
    gameParent = document.querySelector '#morning-stroll'
    gameParent.addEventListener 'state:play', ->
      fiddle.setAttribute 'disabled', ''

    # Lastly, whenever going (returning) to the menu state, history and button
    # states should return to initial values: button visible, fiddling off.
    gameParent.addEventListener 'state:menu', ->
      fiddle.removeAttribute 'disabled'
      window.history.back() if window.history.state.fiddle is on

  # About
  # -----
  # This feature is just the other half of fancily presenting the about-content
  # via some set flipping-card styling. `classList` and css transitions are required.
  Site.initAbout = ->
    return unless (classlist and csstransitions)

    # There are two classes that need to be added to the main `frame` element:
    # `flipping`, `flipped`. The latter is what drives the main flipping
    # transition. The former is needed for some ancillary transition for when
    # the flipping stops.

    # Being able to toggle `flipping` means knowing the transition durations,
    # which requires using `getComputedStyle` and a Modernizr vendor-prefix
    # helper.
    style = window.getComputedStyle document.querySelector('#framed') 
    flipDuration = (
      parseFloat(style[prefixedCSS('transition-duration')]) +
      parseFloat(style[prefixedCSS('transition-delay')])
    ) * 1000
    frame = document.querySelector '#frame'

    # The about button simply (optimistically) toggles `flipped`. When flipping,
    # the button disables itself.
    toggleAbout = document.querySelector '#toggle-about'
    toggleAbout.addEventListener 'click', ->
      frame.classList.toggle 'flipped'

      frame.classList.add 'flipping'
      toggleAbout.setAttribute 'disabled', ''
      setTimeout ->
        frame.classList.remove 'flipping'
        toggleAbout.removeAttribute 'disabled'
      , flipDuration

  Site
