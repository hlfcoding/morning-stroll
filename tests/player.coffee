define [
  'phaser'
  'underscore'
  'app/player'
  'test/helpers'
], (Phaser, _, Player, helpers) ->

  describe 'Player', ->
    game = null
    player = null

    beforeEach ->
      spyOn Player::, '_initialize'
      player = new Player()
      spyOn(player, method).and.callThrough() for method in [
        '_beginJump', '_buildJump', '_endJump'
        '_beginRun'
        '_beginTurn', '_endTurn'
        '_playAnimation'
      ]
      _.extend player, helpers.createFakePlayerProps(player)

      player._initPhysics()
      player._initState()

    endAnimation = ->
      player.animation.isPlaying = no
      player.animation.isFinished = yes

    initialYAcceleration = null
    runJumpUpdatesUntil = (stopAt) ->
      player.cursors.up.isDown = yes
      initialYAcceleration = player.acceleration.y
      player.update()
      return if stopAt is 'rising'

      player.update()
      return if stopAt is 'building'

      player.cursors.up.isDown = no
      player.cursors.up.isUp = yes
      player.velocity.y = 1
      player.update() # End jump.
      player.update() # Fall.
      return if stopAt is 'falling'

      player.physics.touching.down = yes
      player.update()
      return if stopAt is 'landing'

    testStartAnimation = ->
      it 'will play start animation', ->
        expect(player.nextAction).toBe 'start'
        expect(player._playAnimation).toHaveBeenCalledWith 'start', undefined
        expect(player._isAnimationInterruptible()).toBe no

    describe 'when initialized', ->
      it 'is set to still and facing right', ->
        expect(player.state).toBe 'still'
        expect(player._isFullyStill()).toBe yes
        expect(player.direction).toBe Player.Direction.Right
        expect(player.animation).toBeNull()

      it 'has no next state info', ->
        expect(player.nextAction).toBe 'none'
        expect(player.nextDirection).toBeNull()
        expect(player.nextState).toBeNull()

    describe 'when x cursor key is down in same direction', ->
      beforeEach ->
        player.cursors.right.isDown = yes
        player.update()

      it 'can get and set the right direction from #_xDirectionInput', ->
        expect(player._xDirectionInput()).toBe Player.Direction.Right
        expect(player.nextDirection).toBe Player.Direction.Right

      describe 'when still', ->
        it 'will begin to run', ->
          expect(player.state).toBe 'running'
          expect(player._beginRun).toHaveBeenCalled()

        testStartAnimation()

      describe 'when start animation finishes', ->
        beforeEach ->
          endAnimation()
          player.update()

        it 'will be fully running', ->
          expect(player._isFullyRunning()).toBe yes

        it 'will play interruptible run animation in loop', ->
          expect(player._playAnimation).toHaveBeenCalledWith 'run', no
          expect(player.animation.loop).toBe on
          expect(player._isAnimationInterruptible()).toBe yes

    describe 'when x cursor key is down in opposite direction', ->
      beforeEach ->
        player.cursors.left.isDown = yes
        player.update()

      it 'can get and set the right direction from #_xDirectionInput', ->
        expect(player._xDirectionInput()).toBe Player.Direction.Left
        expect(player.nextDirection).toBe Player.Direction.Left

      describe 'when still', ->
        it 'will immediately (end) turn and begin to run', ->
          expect(player._isTurning).toBe yes
          expect(player.direction).toBe Player.Direction.Left
          expect(player._beginRun).toHaveBeenCalled()

        testStartAnimation()

    # TODO: Test turning.

    describe 'when up key is down', ->
      describe 'when still', ->
        beforeEach -> runJumpUpdatesUntil 'rising'

        it 'will only begin to jump', ->
          expect(player.state).toBe 'rising'
          expect(player._beginJump).toHaveBeenCalled()

          expect(player._buildJump).not.toHaveBeenCalled()
          expect(player._endJump).not.toHaveBeenCalled()

        it 'will play jump animation', ->
          expect(player.nextAction).toBe 'jump'
          expect(player._playAnimation).toHaveBeenCalledWith 'jump', undefined
          expect(player._isAnimationInterruptible()).toBe no

        it 'will not run on jump', ->
          expect(player._beginRun).not.toHaveBeenCalled()

        it 'will decrease y acceleration', ->
          expect(player.acceleration.y).toBeLessThan initialYAcceleration

      describe 'when rising', ->
        beforeEach -> runJumpUpdatesUntil 'building'

        it 'will only continue and build jump', ->
          expect(player.state).toBe 'rising'
          expect(player._isInMidAir()).toBe yes
          expect(player._buildJump).toHaveBeenCalled()

          expect(player._beginJump.calls.count()).toBe 1
          expect(player._endJump).not.toHaveBeenCalled()

    describe 'when up key is up', ->
      describe 'when done building', ->
        beforeEach -> runJumpUpdatesUntil 'falling'

        it 'will only end the jump and start falling', ->
          expect(player.acceleration.y).toBe initialYAcceleration

          expect(player._beginJump.calls.count()).toBe 1
          expect(player._buildJump.calls.count()).toBe 1

          expect(player.state).toBe 'falling'
          expect(player._isInMidAir()).toBe yes

        it 'will play fall animation', ->
          expect(player._playAnimation).toHaveBeenCalledWith 31, no
          expect(player._isAnimationInterruptible()).toBe yes

      describe 'when touching another object below', ->
        beforeEach -> runJumpUpdatesUntil 'landing'

        it 'will begin to land', ->
          expect(player.state).toBe 'landing'
          expect(player._isInMidAir()).toBe no

        it 'will play land animation', ->
          expect(player._playAnimation).toHaveBeenCalledWith 'land'
          expect(player._isAnimationInterruptible()).toBe no

        it 'will be landed when animation finishes', ->
          endAnimation()

          expect(player._isLanded()).toBe yes
