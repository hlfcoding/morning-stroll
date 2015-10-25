define ['helpers'], (Helpers) ->

  {Point} = Phaser

  {PointMixin} = Helpers

  _.extend Point::, PointMixin

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

  configurePlatformsWithDefaults: (platforms) ->
    platforms.minLedgeSize = 3
    platforms.maxLedgeSize = 5
    platforms.minLedgeSpacing = new Point 4, 2
    platforms.maxLedgeSpacing = new Point 8, 4
    platforms.ledgeThickness = 2
    platforms.tileWidth = platforms.tileHeight = 32

  createBackgroundProps: (background) ->
    layers: [
      { zIndex: 1, image: { y: 0, height: 1000 }, scrollFactor: 1 }
      { zIndex: 2, image: { y: 0, height: 1000 }, scrollFactor: 1 }
      { zIndex: 3, image: { y: 0, height: 1000 }, scrollFactor: 1 }
    ]

  createPlatformsProps: (platform) ->
    config: { mapH: 3152 }
    game:
      world:
        getBounds: -> { width: 416, height: 2912 } # FIXME: Link to source.

  createPlayerProps: (player) ->
    sprite:
      body: 
        drag: new Point(), setSize: jasmine.createSpy 'setSize'
        velocity: new Point(), acceleration: new Point()
        position: new Point(), offset: new Point(), onFloor: -> no
      game:
        time: { create: -> new FakeTimer() }
      scale: new Point()

    animations:
      play: jasmine.createSpy('play').and.callFake (name) ->
        { isFinished: no, isPlaying: yes, loop: name is 'run', name: name }
      frame: 17 # Initial.

    cameraFocus:
      position: new Point()

    cursors:
      _.mapObject { left: {}, right: {}, up: {}, down: {} }, (key) ->
        key.isUp = key.isDown = no; key

    gravity: new Point()
