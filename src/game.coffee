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
  'app/state-boot'
  'app/state-menu'
  'app/state-preload'
  'app/state-play'
], (Phaser, BootState, MenuState, PreloadState, PlayState) ->

  'use strict'

  # Global flags
  # ------------

  window.debugging = on

  # Main
  # ----

  width = 416
  height = 600
  renderer = Phaser.AUTO
  parentElementId = 'morning-stroll'

  game = new Phaser.Game width, height, renderer, parentElementId

  game.state.add 'boot', BootState
  game.state.add 'preload', PreloadState
  game.state.add 'menu', MenuState
  game.state.add 'play', PlayState

  game.state.start 'boot'

  # Debug
  # -----
  # Block of additions for debugging the app. Exposes classes and instances as
  # globals.
  window.game = game if window.debugging is on
