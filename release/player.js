define(['phaser', 'underscore', 'app/defines', 'app/helpers'], function(Phaser, _, defines, Helpers) {
  'use strict';
  var AnimationMixin, DebugMixin, Direction, Player, Point, playerYOffset;
  Point = Phaser.Point;
  playerYOffset = defines.playerYOffset;
  AnimationMixin = Helpers.AnimationMixin, DebugMixin = Helpers.DebugMixin;
  Direction = {
    Left: -1,
    Right: 1
  };
  Player = (function() {
    Player.Direction = Direction;

    Player.LastFrame = 52;

    function Player(config, game, cursors, gui) {
      this.config = config;
      this.cursors = cursors;
      this._initialize(game, gui);
    }

    Player.prototype._initialize = function(game, gui) {
      var ref, x, y;
      ref = this.config.origin, x = ref.x, y = ref.y;
      this.sprite = game.add.sprite(x, y, 'player', 17);
      this.sprite.anchor = new Point(0.5, 0.5);
      this.cameraFocus = game.add.sprite(x, y);
      this.animations = this.sprite.animations;
      this._initAnimations();
      game.physics.arcade.enable(this.sprite);
      this.gravity = game.physics.arcade.gravity;
      this._initPhysics();
      this._initState();
      return this._initDebugging(gui);
    };

    Player.prototype.destroy = function() {
      this.animations = null;
      this.physics = null;
      this.velocity = null;
      return this.acceleration = null;
    };

    Player.prototype.distanceFallen = function() {
      if (this._fallingPoint == null) {
        return 0;
      }
      return this.sprite.y - this._fallingPoint.y;
    };

    Player.prototype.startEnding = function(mate) {
      var animation;
      this.control = false;
      this.sprite.position.setTo(mate.x - 43, mate.y);
      this.velocity.setTo(0);
      this.acceleration.setTo(0);
      this.physics.offset.setTo(0);
      this.physics.moves = false;
      this._visualizeTurn(Direction.Right);
      return animation = this.playAnimation('end');
    };

    Player.prototype.update = function() {
      if (this.control !== true) {
        return;
      }
      this.nextAction = 'none';
      this.nextDirection = this._xDirectionInput();
      this.velocity.clampY(-this.maxVelocity.y, this.maxVelocity.y);
      this.velocity.clampX(-this.maxVelocity.x, this.maxVelocity.x);
      if (this._canKeepRunning()) {
        this.nextState = 'running';
      }
      if (this._canFall()) {
        this.nextState = 'falling';
      }
      if (this._canLand()) {
        this.nextState = 'landing';
      }
      if (this._canBeginTurn()) {
        this._beginTurn();
      }
      if (this._canEndTurn()) {
        this._endTurn();
      }
      if (this._canBeginRun()) {
        this._beginRun();
      }
      if (this._canEndRun()) {
        this._endRun();
      }
      if (this._canBeginJump()) {
        this._beginJump();
      }
      if (this._canEndJump()) {
        this._endJump();
      }
      if (!this._isInMidAir()) {
        this.acceleration.x = 0;
      }
      if (this._canBuildRun()) {
        this._buildRun();
      }
      if (this._canBuildJump()) {
        this._buildJump();
      }
      this._changeAnimation();
      this._changeState();
      return this._updateCameraFocus();
    };

    Player.prototype._initAnimations = function() {
      this.animations.add('run', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], 30, true);
      this.animations.add('stop', [12, 13, 14, 15, 16, 17], 24);
      this.animations.add('start', [17, 16, 15, 14, 13, 12], 24);
      this.animations.add('jump', [18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31], 24);
      this.animations.add('land', [32, 33, 18, 17], 24);
      this.animations.add('end', [34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52], 12);
      return this._nextActionOnComplete = null;
    };

    Player.prototype._initDebugging = function(gui) {
      var completedInit, i, len, prop, ref, results;
      this.debugNamespace = 'player';
      this.debugging = defines.debugging;
      completedInit = this._initDebugMixin(gui);
      if (!completedInit) {
        return;
      }
      this.gui.addOpenFolder('drag').addRange(this.physics.drag, 'x');
      this.gui.addOpenFolder('maxVelocity').addRange(this.maxVelocity, 'x').addRange(this.maxVelocity, 'y');
      ref = ['jumpAcceleration', 'jumpMaxDuration', 'jumpVelocityFactor', 'airFrictionRatio', 'runAcceleration'];
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        prop = ref[i];
        results.push(this.gui.addRange(this, prop));
      }
      return results;
    };

    Player.prototype._initPhysics = function() {
      var height, ref, ref1, width;
      this.physics = this.sprite.body;
      ref = this.physics, this.velocity = ref.velocity, this.acceleration = ref.acceleration;
      this.physics.collideWorldBounds = true;
      this.physics.tilePadding = new Point(0, this.sprite.height);
      this.physics.drag.x = 1500;
      ref1 = this.sprite, height = ref1.height, width = ref1.width;
      this._yOffset = playerYOffset;
      this.physics.setSize(width / 2, height / 2, this._xOffset(), this._yOffset);
      this.jumpAcceleration = -4250;
      this.jumpMaxDuration = 500;
      this.jumpVelocityFactor = 1 / 4;
      this.airFrictionRatio = 1 / 20;
      this.runAcceleration = 300;
      this.cameraFocusFollowResistance = 30;
      this.maxVelocity = new Point(200, 800);
      return this._jumpTimer = this.sprite.game.time.create();
    };

    Player.prototype._initState = function() {
      this.animation = null;
      this.direction = Direction.Right;
      this.state = 'still';
      this.nextAction = 'none';
      this.nextDirection = null;
      this.nextState = null;
      this.control = true;
      this._fallingPoint = null;
      this._keepCameraFocusUpdated = true;
      return this._turnDirection = null;
    };

    Player.prototype._changeAnimation = function() {
      var animation, ref, ref1, ref2;
      if (!(this._isInMidAir() || this.nextAction === 'none')) {
        animation = this.playAnimation(this.nextAction, (ref = this.animation) != null ? ref.loop : void 0);
        if (animation && (this._nextActionOnComplete != null)) {
          animation.onComplete.addOnce(this._nextActionOnComplete, this);
          this._nextActionOnComplete = null;
        }
        return;
      }
      switch (this.nextState) {
        case 'running':
          return this.playAnimation('run', false);
        case 'still':
          return this.playAnimation(17, (ref1 = this.animation) != null ? ref1.loop : void 0);
        case 'falling':
          return this.playAnimation(31, (ref2 = this.animation) != null ? ref2.loop : void 0);
        case 'landing':
          return this.playAnimation('land');
      }
    };

    Player.prototype._changeState = function() {
      var ref;
      if (this.nextState === this.state) {
        return;
      }
      if (this.state === 'rising') {
        this.debug('jump:peak', this.physics.y);
      }
      this.debug('state', this.nextState);
      if (this.nextState === 'rising') {
        this.debug('jump:start', this.physics.position);
      }
      if (this.nextState === 'falling') {
        if (this._fallingPoint == null) {
          this._fallingPoint = (ref = this.physics.position) != null ? ref.clone() : void 0;
        }
      } else if (this.nextState === 'still' && (this._fallingPoint != null)) {
        this._fallingPoint = null;
      }
      return this.state = this.nextState;
    };

    Player.prototype._isAnimationInterruptible = function() {
      var ref, ref1;
      return ((ref = this.animation) != null ? ref.isFinished : void 0) || (this.animation == null) || ((ref1 = this.animation) != null ? ref1.loop : void 0);
    };

    Player.prototype._isFullyFalling = function() {
      return this.state === 'falling' && this.velocity.y === this.maxVelocity.y;
    };

    Player.prototype._isFullyRunning = function() {
      var ref;
      return this.state === 'running' && ((ref = this.animation) != null ? ref.name : void 0) === 'run';
    };

    Player.prototype._isFullyStill = function() {
      return this.state === 'still' && (this.animations.frame === 17 && (this.animation == null));
    };

    Player.prototype._isInMidAir = function() {
      var ref;
      return (ref = this.state) === 'rising' || ref === 'falling';
    };

    Player.prototype._isLanded = function() {
      var ref;
      return ((ref = this.animation) != null ? ref.name : void 0) === 'land' && this.animation.isFinished;
    };

    Player.prototype._xDirectionInput = function() {
      var ref, ref1;
      if ((ref = this.cursors) != null ? ref.left.isDown : void 0) {
        return Direction.Left;
      } else if ((ref1 = this.cursors) != null ? ref1.right.isDown : void 0) {
        return Direction.Right;
      }
    };

    Player.prototype._xOffset = function(direction) {
      if (direction == null) {
        direction = this.direction;
      }
      return direction * 10;
    };

    Player.prototype._canBeginJump = function() {
      var ref;
      return ((ref = this.cursors) != null ? ref.up.isDown : void 0) && (this._isFullyRunning() || this._isFullyStill());
    };

    Player.prototype._canBuildJump = function() {
      var ref;
      return this.nextAction !== 'jump' && ((ref = this.cursors) != null ? ref.up.isDown : void 0) && this._jumpTimer.running;
    };

    Player.prototype._canEndJump = function() {
      var ref;
      return this.nextAction !== 'jump' && this._jumpTimer.running && (((ref = this.cursors) != null ? ref.up.isUp : void 0) || this._jumpTimer.ms >= this.jumpMaxDuration);
    };

    Player.prototype._canFall = function() {
      return this.velocity.y > 0 && (this.state !== 'rising' || (!this._jumpTimer.running && this.state === 'rising'));
    };

    Player.prototype._canLand = function() {
      return this.state === 'falling' && this.physics.onFloor();
    };

    Player.prototype._beginJump = function() {
      var kVelocity, ratio;
      this._jumpTimer.start();
      this.nextAction = 'jump';
      this.nextState = 'rising';
      ratio = Math.abs(this.velocity.x / this.maxVelocity.x);
      kVelocity = (1 - this.jumpVelocityFactor) + this.jumpVelocityFactor * ratio;
      return this.acceleration.y = this.jumpAcceleration * kVelocity;
    };

    Player.prototype._buildJump = function() {
      var kEasing;
      kEasing = (1000 - this.jumpMaxDuration) + (this.jumpMaxDuration - this._jumpTimer.ms);
      kEasing = Math.pow(kEasing / 1000, 2);
      this.acceleration.y *= kEasing;
      return this.debug('jump:build', kEasing);
    };

    Player.prototype._endJump = function() {
      this.debug('jump:end', this._jumpTimer.ms, {
        position: this.physics.position
      });
      this.acceleration.y = this.gravity.y;
      return this._jumpTimer.stop();
    };

    Player.prototype._canBeginRun = function() {
      return (this.nextDirection != null) && this.nextDirection === this.direction && !this._isInMidAir() && (this._isFullyStill() || this._isLanded());
    };

    Player.prototype._canBuildRun = function() {
      return this.nextDirection != null;
    };

    Player.prototype._canEndRun = function() {
      return !((this.nextDirection != null) || this._isInMidAir());
    };

    Player.prototype._canKeepRunning = function() {
      return !(this._canLand() || this._isInMidAir());
    };

    Player.prototype._beginRun = function() {
      this.nextAction = 'start';
      return this.nextState = 'running';
    };

    Player.prototype._buildRun = function() {
      return this.acceleration.x = this._isInMidAir() ? this.runAcceleration * this.airFrictionRatio * -this.nextDirection : this.runAcceleration * this.nextDirection;
    };

    Player.prototype._endRun = function() {
      if (this.velocity.x !== 0) {
        this.nextAction = 'stop';
        return;
      }
      this.nextState = 'still';
      return this._turnDirection = null;
    };

    Player.prototype._canBeginTurn = function() {
      return (this.nextDirection != null) && this.nextDirection !== this.direction && this.nextAction !== 'start' && (this._turnDirection == null);
    };

    Player.prototype._canEndTurn = function() {
      return this.nextAction !== 'stop' && (this._turnDirection != null) && this._isAnimationInterruptible();
    };

    Player.prototype._beginTurn = function() {
      if (!this._isFullyStill()) {
        this.nextAction = 'stop';
      }
      this._turnDirection = this.nextDirection;
      this.debug('turn:start', this.velocity.x);
      return this.debug('facing', this.nextDirection);
    };

    Player.prototype._endTurn = function() {
      this._visualizeTurn();
      this.nextAction = 'start';
      this.direction = this._turnDirection;
      this._turnDirection = null;
      return this.debug('turn:end', this.velocity.x);
    };

    Player.prototype._visualizeTurn = function(direction) {
      if (direction == null) {
        direction = this._turnDirection;
      }
      this.sprite.scale.x = direction;
      return this.physics.offset.set(this._xOffset(direction), this._yOffset);
    };

    Player.prototype._updateCameraFocus = function() {
      var kEasing, step;
      if (this.nextAction === 'jump') {
        this._keepCameraFocusUpdated = false;
      }
      if (!this._keepCameraFocusUpdated) {
        if (this.nextState === 'falling') {
          this._keepCameraFocusUpdated = true;
        }
        return false;
      }
      kEasing = this.cameraFocusFollowResistance;
      if (this._isFullyFalling()) {
        kEasing /= 3;
      }
      step = this.physics.position.clone().subtractPoint(this.cameraFocus.position).divide(kEasing, kEasing);
      return this.cameraFocus.position.addPoint(step);
    };

    return Player;

  })();
  _.extend(Player.prototype, AnimationMixin, DebugMixin);
  return Player;
});

//# sourceMappingURL=player.js.map
