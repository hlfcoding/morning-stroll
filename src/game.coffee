# Game
# ====
# Highest-level application script.

# Dependencies
# ------------
# Configure RequireJS. Dependency references default to the `lib` directory.
# We're using CoffeeScript, so our `app` package code is in the compiled js
# directory `release`.

requirejs.config
  baseUrl: 'lib'
  paths: { app: '../release' }
  shim:
    'dat.gui': { exports: 'dat' }
    phaser: { exports: 'Phaser' }

requirejs [
  'phaser'
  'app/defines'
  'app/helpers'
  'app/state-boot'
  'app/state-menu'
  'app/state-preload'
  'app/state-play'
], (Phaser, defines, Helpers, BootState, MenuState, PreloadState, PlayState) ->

  'use strict'

  {Point} = Phaser

  {debugging, gameH, gameW} = defines

  {PointMixin, StateManagerMixin} = Helpers

  # Framework Extensions
  # --------------------

  _.extend Point::, PointMixin

  # Main
  # ----

  game = new Phaser.Game gameW, gameH, Phaser.AUTO, 'morning-stroll' # Renderer, parent element id.

  _.extend game.state, StateManagerMixin

  game.state.add 'boot', BootState
  game.state.add 'preload', PreloadState
  game.state.add 'menu', MenuState
  game.state.add 'play', PlayState

  game.state.start 'boot'

  # Debug
  # -----
  # Block of additions for debugging the app. Exposes classes and instances as
  # globals.
  window.game = game if debugging is on
