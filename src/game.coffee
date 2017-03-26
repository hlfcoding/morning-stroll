# Game
# ====
# Highest-level application script. There (rightfully) isn't much here. See
# `PlayState` for the main game logic.

# Dependencies
# ------------
# Configure RequireJS. We're using CoffeeScript, so our `app` package code is in
# the compiled js directory `release`.
requirejs.config({ baseUrl: './release' })

define [
  'defines', 'helpers', 'site', 'state-boot', 'state-menu', 'state-preload',
  'state-play'
], (defines, Helpers, Site, BootState, MenuState, PreloadState, PlayState) ->

  {Point} = Phaser

  {debugging, gameH, gameW} = defines

  {PointMixin, StateManagerMixin} = Helpers

  # Framework Extensions
  # --------------------

  _.extend(Point::, PointMixin)

  # Main
  # ----

  game = new Phaser.Game(
    gameW, gameH, Phaser.AUTO, document.getElementById('morning-stroll')
  )

  _.extend(game.state, StateManagerMixin)

  game.state.add('boot', BootState)
  game.state.add('preload', PreloadState)
  game.state.add('menu', MenuState)
  game.state.add('play', PlayState)

  game.state.start('boot')

  # Site
  # ----

  # Add a class for use in styling.
  document.body.className = 'ready'

  Site.initFiddle(game)
  Site.initAbout()

  # Debug
  # -----
  # Block of additions for debugging the app. Exposes classes and instances as
  # globals.
  window.game = game if debugging is on
