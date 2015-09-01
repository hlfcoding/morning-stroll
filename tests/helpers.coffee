define [
  'phaser'
  'underscore'
], (Phaser, _) ->

  # Phaser is written with interwoven dependencies, but does not provide test
  # helpers or fake classes. This custom faking isn't ideal, but a last resort.

  class FakeTimer
    constructor: ->
      @running = no
      @ms = 0
      @_interval = null

    start: ->
      @_start = Date.now()
      @_interval = setInterval =>
        @ms = Date.now() - @_start
      , 100
      @running = yes

    stop: ->
      clearInterval @_interval
      @running = no

  createFakeBackgroundProps: (background) ->
    group:
      game:
        height: 600
    layers: [
      { zIndex: 1, sprite: { y: 0, height: 1000, scrollFactorY: 1 } }
      { zIndex: 2, sprite: { y: 0, height: 1000, scrollFactorY: 1 } }
      { zIndex: 3, sprite: { y: 0, height: 1000, scrollFactorY: 1 } }
    ]
    width: 300

  createFakePlatformsProps: (platform) -> {}

  createFakePlayerProps: (player) ->
    sprite:
      body: 
        drag: new Phaser.Point(), setSize: jasmine.createSpy 'setSize'
        velocity: new Phaser.Point(), acceleration: new Phaser.Point()
        touching: {}
      game:
        time: { create: -> new FakeTimer() }
      scale: new Phaser.Point()

    animations:
      play: jasmine.createSpy('play').and.callFake (name) ->
        { isFinished: no, isPlaying: yes, loop: name is 'run', name: name }
      frame: 17 # Initial.

    cursors:
      _.mapObject { left: {}, right: {}, up: {}, down: {} }, (key) ->
        key.isUp = key.isDown = no; key

    gravity: new Phaser.Point()
