var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

define(['dat.gui', 'phaser', 'underscore', 'app/background', 'app/defines', 'app/helpers', 'app/in-state-menu', 'app/platforms', 'app/player'], function(dat, Phaser, _, Background, defines, Helpers, InStateMenu, Platforms, Player) {
  'use strict';
  var AnimationMixin, CameraMixin, DebugDisplayMixin, DebugMixin, Key, Keyboard, MateLastFrame, Physics, PlayState, Point, Rectangle, State, TextMixin, Timer, artH, deadzoneH, domStateEvents, fontLarge, fontSmall, mapH, playerH, playerW, playerYOffset, shakeFallH;
  Key = Phaser.Key, Keyboard = Phaser.Keyboard, Physics = Phaser.Physics, Point = Phaser.Point, Rectangle = Phaser.Rectangle, State = Phaser.State, Timer = Phaser.Timer;
  domStateEvents = defines.domStateEvents, artH = defines.artH, mapH = defines.mapH, fontLarge = defines.fontLarge, fontSmall = defines.fontSmall, playerH = defines.playerH, playerW = defines.playerW, playerYOffset = defines.playerYOffset, shakeFallH = defines.shakeFallH, deadzoneH = defines.deadzoneH;
  AnimationMixin = Helpers.AnimationMixin, CameraMixin = Helpers.CameraMixin, DebugMixin = Helpers.DebugMixin, DebugDisplayMixin = Helpers.DebugDisplayMixin, TextMixin = Helpers.TextMixin;
  MateLastFrame = 14;
  PlayState = (function(superClass) {
    extend(PlayState, superClass);

    function PlayState() {
      return PlayState.__super__.constructor.apply(this, arguments);
    }

    PlayState.prototype.init = function() {
      var e;
      if (domStateEvents) {
        e = document.createEvent('CustomEvent');
        e.initCustomEvent('state:play');
        this.game.parent.dispatchEvent(e);
      }
      this.debugging = defines.debugging, this.developing = defines.developing;
      this.detachedCamera = false;
      this.ended = false;
      this.debugDisplay = this.gui = null;
      this.cursors = null;
      this.background = this.mate = this.platforms = this.player = null;
      this.textLayout = null;
      _.extend(this.camera, CameraMixin);
      this.game.onBlur.add(this.onBlur, this);
      this.game.onFocus.add(this.onFocus, this);
      this._initDebugMixin;
      return this._initDebugDisplayMixin(this.game);
    };

    PlayState.prototype.create = function() {
      this.physics.startSystem(Physics.ARCADE);
      this.physics.arcade.gravity.y = 500;
      this.cursors = this.input.keyboard.createCursorKeys();
      this.quitKey = this._addKey(Keyboard.Q, this.quit);
      this.onHit = this.input[this.game.device.touch ? 'onTap' : 'onUp'];
      this.onHit.add((function(_this) {
        return function(trigger) {
          if (!_this.quit(trigger)) {
            return _this.inStateMenu.toggle();
          }
        };
      })(this), this);
      if (this.developing) {
        this.gui = new dat.GUI();
        this.gui.add(this, 'debugging').listen().onFinishChange((function(_this) {
          return function() {
            _this.background.debugging = _this.platforms.debugging = _this.player.debugging = _this.debugging;
            if (!_this.debugging) {
              return _this.debugDisplay.reset();
            }
          };
        })(this));
        this.gui.add(this, 'detachedCamera').onFinishChange((function(_this) {
          return function() {
            return _this._toggleCameraAttachment();
          };
        })(this));
        this.gui.addOpenFolder('gravity').addRange(this.physics.arcade.gravity, 'y');
      }
      this._addMusic();
      this._addBackground();
      this._addPlatforms();
      this._addPlayer();
      this._addMate();
      this._addInStateMenu();
      return this._toggleCameraAttachment(true);
    };

    PlayState.prototype.update = function() {
      this.physics.arcade.collide(this.player.sprite, this.platforms.layer);
      this.background.update();
      this.player.update();
      this._updateVolumeOnPlayerLand();
      this.camera.updateShake();
      if (this._shakeOnPlayerFall()) {
        this.camera.unfollow();
      } else if (!(this.detachedCamera || (this.camera.target != null) || this.camera.isShaking())) {
        this.camera.follow(this.player.cameraFocus);
      }
      if (this.detachedCamera) {
        this.camera.updatePositionWithCursors(this.cursors);
      }
      if (this._isPlayerReadyToEnd()) {
        return this.end();
      }
    };

    PlayState.prototype.render = function() {
      if (this.debugging) {
        this._renderDebugDisplay();
      }
      if (this.debugging) {
        return this._renderDebugOverlays();
      }
    };

    PlayState.prototype.shutdown = function() {
      var gameObject, i, j, key, len, len1, ref, ref1, ref2;
      ref = [this.background, this.inStateMenu, this.music, this.platforms, this.player];
      for (i = 0, len = ref.length; i < len; i++) {
        gameObject = ref[i];
        gameObject.destroy();
      }
      this.game.onBlur.remove(this.onBlur, this);
      this.game.onFocus.remove(this.onFocus, this);
      this.onHit.remove(this.quit, this);
      ref1 = [this.loudKey, this.muteKey, this.quietKey, this.quitKey];
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        key = ref1[j];
        key.onDown.removeAll(this);
      }
      return (ref2 = this.gui) != null ? ref2.destroy() : void 0;
    };

    PlayState.prototype.onBlur = function() {
      var ref;
      return (ref = this.music) != null ? ref.pause() : void 0;
    };

    PlayState.prototype.onFocus = function() {
      var ref;
      return (ref = this.music) != null ? ref.resume() : void 0;
    };

    PlayState.prototype.end = function() {
      var animation;
      animation = this.player.startEnding(this.mate);
      animation.onComplete.addOnce((function(_this) {
        return function() {
          animation = _this.mate.play('end');
          return animation.onComplete.addOnce(function() {
            _this.player.animations.frame = Player.LastFrame;
            return _this.mate.animations.frame = MateLastFrame;
          });
        };
      })(this));
      return _.delay((function(_this) {
        return function() {
          return _this._renderEndingDisplay();
        };
      })(this), 5 * Timer.SECOND);
    };

    PlayState.prototype.quit = function(trigger) {
      var _quit;
      if (!(this.ended || trigger instanceof Key)) {
        return false;
      }
      _quit = (function(_this) {
        return function() {
          return _this.state.startWithTransition(null, 'menu', true);
        };
      })(this);
      if (this.music.volume === 0) {
        return _quit();
      } else {
        this.music.fadeOut(3 * Timer.SECOND);
        return this.music.onFadeComplete.addOnce(_quit);
      }
    };

    PlayState.prototype._addBackground = function() {
      var parallaxTolerance;
      parallaxTolerance = mapH - artH;
      this.background = new Background({
        parallaxTolerance: parallaxTolerance
      }, this.game);
      this.background.addImages(_.template('bg<%= zIndex %>'), 16);
      return this.background.layout();
    };

    PlayState.prototype._addInStateMenu = function() {
      return this.inStateMenu = new InStateMenu([
        [
          'Paused', {
            fontSize: fontLarge
          }
        ], [
          'Hold arrow keys to accelerate', {
            fontSize: fontSmall
          }
        ], [
          'Press 0, -, + for volume', {
            fontSize: fontSmall
          }
        ], [
          'Press Q to quit', {
            fontSize: fontSmall
          }
        ]
      ], this.game, {
        pauseHandler: (function(_this) {
          return function(paused) {
            return _this.player.control = !paused;
          };
        })(this)
      });
    };

    PlayState.prototype._addKey = function(keyCode, callback) {
      var key;
      key = this.input.keyboard.addKey(keyCode);
      key.onDown.add(callback, this);
      this.input.keyboard.removeKeyCapture(keyCode);
      return key;
    };

    PlayState.prototype._addMate = function() {
      var i, ref, results, x, y;
      ref = this.endingPoint, x = ref.x, y = ref.y;
      x += 20;
      y -= 10;
      this.mate = this.add.sprite(x, y, 'mate', 1);
      this.mate.anchor = new Point(0.5, 0.5);
      return this.mate.animations.add('end', (function() {
        results = [];
        for (var i = 4; 4 <= MateLastFrame ? i <= MateLastFrame : i >= MateLastFrame; 4 <= MateLastFrame ? i++ : i--){ results.push(i); }
        return results;
      }).apply(this), 12);
    };

    PlayState.prototype._addMusic = function() {
      var increment, ref;
      this.userVolume = 1;
      this.music = this.add.audio('bgm', 0.2, true);
      this.music.mute = this.developing || this.debugging;
      this.music.play();
      if ((ref = this.gui) != null) {
        ref.add(this.music, 'mute').listen();
      }
      increment = 0.1;
      this.loudKey = this._addKey(Keyboard.EQUALS, (function(_this) {
        return function() {
          return _this.userVolume += increment;
        };
      })(this));
      this.muteKey = this._addKey(Keyboard.ZERO, (function(_this) {
        return function() {
          return _this.music.mute = !_this.music.mute;
        };
      })(this));
      return this.quietKey = this._addKey(Keyboard.UNDERSCORE, (function(_this) {
        return function() {
          return _this.userVolume -= increment;
        };
      })(this));
    };

    PlayState.prototype._addPlatforms = function() {
      var ref;
      this.platforms = new Platforms({
        mapH: mapH,
        tileImageKey: 'balcony'
      }, this.game, (ref = this.gui) != null ? ref.addOpenFolder('platforms') : void 0);
      this.endingPoint = this.platforms.ledges.slice(-1)[0].createMidpoint(this.platforms);
      return this.startingPoint = new Point(playerW, this.world.height - playerH + playerYOffset);
    };

    PlayState.prototype._addPlayer = function() {
      var origin, ref;
      origin = this.startingPoint;
      return this.player = new Player({
        origin: origin
      }, this.game, this.cursors, (ref = this.gui) != null ? ref.addOpenFolder('player') : void 0);
    };

    PlayState.prototype._addText = function(text, style) {
      var tween;
      _.defaults(style, {
        fill: '#fff',
        font: 'Enriqueta'
      });
      text = this.addCenteredText(text, this.textLayout, style);
      return tween = this.fadeTo(text, Timer.SECOND, 1);
    };

    PlayState.prototype._isPlayerReadyToEnd = function() {
      return this.player.state === 'still' && this.player.control === true && this.player.sprite.y <= this.endingPoint.y;
    };

    PlayState.prototype._renderDebugDisplay = function() {
      this.resetDebugDisplayLayout();
      if (this.player.debugging) {
        this.renderDebugDisplayItems((function(_this) {
          return function(layoutX, layoutY) {
            return _this.debugDisplay.bodyInfo(_this.player.sprite, layoutX, layoutY);
          };
        })(this), 6);
        return this.renderDebugDisplayItems(this.player.debugTextItems);
      }
    };

    PlayState.prototype._renderDebugOverlays = function() {
      if (this.player.debugging) {
        this.debugDisplay.body(this.player.sprite);
        this.debugDisplay.spriteBounds(this.player.sprite);
        return this.debugDisplay.spriteBounds(this.player.cameraFocus);
      }
    };

    PlayState.prototype._renderEndingDisplay = function() {
      this.textLayout = {
        y: 120,
        baseline: 40
      };
      return this._addText('The End', {
        fontSize: fontLarge
      }).onComplete.addOnce((function(_this) {
        return function() {
          _this._addText('Click to play again', {
            fontSize: fontSmall
          });
          return _this.ended = true;
        };
      })(this));
    };

    PlayState.prototype._shakeOnPlayerFall = function() {
      if (!(this.player.nextState === 'landing' && this.player.distanceFallen() > shakeFallH)) {
        return false;
      }
      return this.camera.shake();
    };

    PlayState.prototype._toggleCameraAttachment = function(attached) {
      var base, base1;
      if (attached == null) {
        attached = !this.detachedCamera;
      }
      if (attached) {
        this.camera.follow(this.player.cameraFocus);
        if ((base = this.player).cursors == null) {
          base.cursors = this.cursors;
        }
        return (base1 = this.camera).deadzone != null ? base1.deadzone : base1.deadzone = new Rectangle(0, (this.game.height - deadzoneH) / 2, this.game.width, deadzoneH);
      } else {
        this.camera.unfollow();
        return this.player.cursors = null;
      }
    };

    PlayState.prototype._updateVolumeOnPlayerLand = function() {
      var volume;
      if (this.player.nextState !== 'landing') {
        return false;
      }
      volume = Math.pow((this.platforms.tilemap.heightInPixels - this.player.sprite.y) / this.platforms.tilemap.heightInPixels, 1.3);
      volume *= this.math.clamp(this.userVolume, 0, 2);
      volume = this.math.clamp(volume, 0.2, 0.8);
      return this.music.fadeTo(Timer.SECOND, volume);
    };

    return PlayState;

  })(State);
  _.extend(PlayState.prototype, AnimationMixin, DebugMixin, DebugDisplayMixin, TextMixin);
  return PlayState;
});

//# sourceMappingURL=state-play.js.map
