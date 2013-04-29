requirejs.config
  baseUrl: 'lib'
  paths:
    app: '../release'

requirejs [
  'phaser'
  'app/game'
],
(Phaser, MorningStroll) ->

  'use strict'

  window.DEBUG = on

  game = new MorningStroll()

  game.start()

  console.info game
