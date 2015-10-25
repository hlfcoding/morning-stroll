define ['player', 'test/fakes'], (Player, fakes) ->

  {Direction} = Player

  describe 'Player', ->
    cursors = null
    game = null
    player = null

    beforeEach ->
      spyOn Player::, '_initialize'
      player = new Player()
      spyOn(player, method).and.callThrough() for method in [
        '_beginJump', '_buildJump', '_endJump'
        '_beginRun', '_buildRun', '_endRun'
        '_beginTurn', '_endTurn'
        'playAnimation'
      ]
      _.extend player, fakes.createPlayerProps(player)

      player._initPhysics()
      player._initState()

      {cursors} = player

    endAnimation = ->
      player.animation.isPlaying = no
      player.animation.isFinished = yes

    initialYAcceleration = null
    runJumpUpdatesUntil = (stopAt) ->
      cursors.up.isDown = yes
      initialYAcceleration = player.acceleration.y
      player.update()
      return if stopAt is 'rising'

      player.update()
      return if stopAt is 'building'

      cursors.up.isDown = no
      cursors.up.isUp = yes
      player.velocity.y = 1
      player.update() # End jump.
      player.update() # Fall.
      return if stopAt is 'falling'

      spyOn(player.physics, 'onFloor').and.returnValue yes
      player.update()
      return if stopAt is 'landing'

    runRunUpdatesUntil = (stopAt, options) ->
      if options?.backwards and not (stopAt in ['turn', 'restart'])
        cursors.left.isDown = yes
      else cursors.right.isDown = yes

      player.update()
      return if stopAt is 'start'

      endAnimation()
      player.update()
      return if stopAt is 'running'

      unless options?.backwards
        player.velocity.x = 1
        cursors.right.isDown = no
        cursors.right.isUp = yes
        player.update()
        return if stopAt is 'stop'

        player.velocity.x = 0
        player.update()
        return if stopAt is 'still'

      cursors.right.isDown = no
      cursors.left.isDown = yes
      player.update()
      return if stopAt is 'turn'

      endAnimation()
      player.update()
      return if stopAt is 'restart'

    testStartAnimation = ->
      expect(player.nextAction).toBe 'start'
      expect(player.playAnimation).toHaveBeenCalledWith 'start', undefined
      expect(player._isAnimationInterruptible()).toBe no

    testStopAnimation = ->
      expect(player.nextAction).toBe 'stop'
      expect(player.playAnimation).toHaveBeenCalledWith 'stop', yes
      expect(player._isAnimationInterruptible()).toBe no

    describe 'when initialized', ->
      it 'is set to still and facing right', ->
        expect(player.state).toBe 'still'
        expect(player._isFullyStill()).toBe yes
        expect(player.direction).toBe Direction.Right
        expect(player.animation).toBeNull()

      it 'has no next state info', ->
        expect(player.nextAction).toBe 'none'
        expect(player.nextDirection).toBeNull()
        expect(player.nextState).toBeNull()

    describe 'when x cursor key is down in same direction', ->
      it 'can get and set the right direction from #_xDirectionInput', ->
        runRunUpdatesUntil 'start'

        expect(player._xDirectionInput()).toBe Direction.Right
        expect(player.nextDirection).toBe Direction.Right

      describe 'when still', ->
        beforeEach -> runRunUpdatesUntil 'start'

        it 'will begin to run', ->
          expect(player.state).toBe 'running'
          expect(player._beginRun).toHaveBeenCalled()

        it 'will play start animation', testStartAnimation

      describe 'when start animation finishes', ->
        beforeEach -> runRunUpdatesUntil 'running'

        it 'will be fully running', ->
          expect(player._isFullyRunning()).toBe yes
          expect(player._buildRun).toHaveBeenCalled()

        it 'will play interruptible run animation in loop', ->
          expect(player.playAnimation).toHaveBeenCalledWith 'run', no
          expect(player.animation.loop).toBe on
          expect(player._isAnimationInterruptible()).toBe yes

        it 'will not run but fall over thin air', ->
          player.velocity.y = 1
          expect(player._canFall()).toBe yes
          player.update()

          expect(player._canKeepRunning()).toBe no
          expect(player.playAnimation).toHaveBeenCalledWith 31, yes

    describe 'when x cursor key was down but is up in same direction', ->

      it 'will stop running and cancel turns', ->
        runRunUpdatesUntil 'stop'

        expect(player._endRun).toHaveBeenCalled()

      it 'will play interrupting stop animation', ->
        runRunUpdatesUntil 'stop'

        testStopAnimation()

      it 'will become still', ->
        runRunUpdatesUntil 'still'

        expect(player.state).toBe 'still'
        expect(player._turnDirection).toBeNull()
        expect(player._endRun).toHaveBeenCalled()

    describe 'when x cursor key is down in opposite direction', ->
      it 'can get and set the right direction from #_xDirectionInput', ->
        runRunUpdatesUntil 'start', backwards: yes

        expect(player._xDirectionInput()).toBe Direction.Left
        expect(player.nextDirection).toBe Direction.Left

      describe 'when still', ->
        beforeEach -> runRunUpdatesUntil 'start', backwards: yes

        it 'will immediately (end) turn and begin to run', ->
          expect(player._beginTurn).toHaveBeenCalled()
          expect(player._endTurn).toHaveBeenCalled()
          expect(player.direction).toBe Direction.Left
          expect(player._beginRun).toHaveBeenCalled()

        it 'will play start animation', testStartAnimation

      describe 'when running in original direction', ->
        beforeEach -> runRunUpdatesUntil 'turn', backwards: yes

        it 'will begin turn', ->
          expect(player._turnDirection).toBe Direction.Left
          expect(player._beginTurn).toHaveBeenCalled()

        it 'will play interrupting stop animation', testStopAnimation

      describe 'when turning to opposite direction', ->
        beforeEach -> runRunUpdatesUntil 'restart', backwards: yes

        it 'will end turn', ->
          expect(player._turnDirection).toBeNull()
          expect(player._endTurn).toHaveBeenCalled()

        it 'will play start animation', testStartAnimation

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
          expect(player.playAnimation).toHaveBeenCalledWith 'jump', undefined
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
          expect(player.playAnimation).toHaveBeenCalledWith 31, no
          expect(player._isAnimationInterruptible()).toBe no

      describe 'when on floor', ->
        beforeEach -> runJumpUpdatesUntil 'landing'

        it 'will begin to land', ->
          expect(player.state).toBe 'landing'
          expect(player._isInMidAir()).toBe no

        it 'will play land animation', ->
          expect(player.playAnimation).toHaveBeenCalledWith 'land'
          expect(player._isAnimationInterruptible()).toBe no

        it 'will be landed when animation finishes', ->
          endAnimation()

          expect(player._isLanded()).toBe yes

    # Supplemental Manual Tests 
    # -------------------------
    # 
    # - Mash left and right cursor keys in alternating fashion for a bit.
    #   Stop, then attempt to turn in other direction. Player should visualize
    #   turn properly, and should not appear to run backwards.
