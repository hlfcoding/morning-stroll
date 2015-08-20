define [
  'phaser'
  'underscore'
  'app/player'
  'test/helpers'
], (Phaser, _, Player, helpers) ->

  describe 'player state', ->
    game = null
    player = null

    beforeEach ->
      spyOn Player::, '_initialize'
      player = new Player()
      spyOn(player, method).and.callThrough() for method in [
        '_beginRun'
        '_playAnimation'
      ]
      _.extend player, helpers.createFakePlayerProps(player)

      player._initPhysics()
      player._initState()

    describe 'when initialized', ->
      it 'is set to still and facing right', ->
        expect(player.state).toBe 'still'
        expect(player.direction).toBe Player.Direction.Right
        expect(player.animation).toBeNull()

      it 'has no next state info', ->
        expect(player.nextAction).toBe 'none'
        expect(player.nextDirection).toBeNull()
        expect(player.nextState).toBeNull()

    describe 'when right cursor is down', ->
      beforeEach ->
        player.cursors.right.isDown = yes
        player.update()

      it 'can get the right direction from #_xDirectionInput', ->
        expect(player._xDirectionInput()).toBe Player.Direction.Right

      describe 'when still', ->

        it 'will begin run', ->
          expect(player.state).toBe 'running'
          expect(player._beginRun).toHaveBeenCalled()

        it 'will play start animation', ->
          expect(player.nextAction).toBe 'start'
          expect(player._playAnimation).toHaveBeenCalledWith 'start', undefined
