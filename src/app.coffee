requirejs.config
  baseUrl: 'lib'
  paths:
    app: '../release'
  shim:
    'phaser': { deps: [] }

requirejs [
  'app/game'
  # Only non-exports after this point.
  'phaser'
],
(MorningStroll) ->

  'use strict'

  window.DEBUG = on

  game = new MorningStroll()

  game.start()

  console.info game
