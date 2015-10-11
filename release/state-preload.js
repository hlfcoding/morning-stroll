var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

define(['phaser', 'underscore', 'app/defines'], function(Phaser, _, defines) {
  'use strict';
  var PreloadState, State, Timer, buttonH, buttonW, developing, playerH, playerW, progressH, progressW;
  State = Phaser.State, Timer = Phaser.Timer;
  buttonH = defines.buttonH, buttonW = defines.buttonW, developing = defines.developing, playerH = defines.playerH, playerW = defines.playerW, progressH = defines.progressH, progressW = defines.progressW;
  PreloadState = (function(superClass) {
    extend(PreloadState, superClass);

    function PreloadState() {
      return PreloadState.__super__.constructor.apply(this, arguments);
    }

    PreloadState.prototype.init = function() {
      _.bindAll(this, 'menu', 'update');
      return window.WebFontConfig = {
        active: (function(_this) {
          return function() {
            return _this.time.events.add(Timer.SECOND, _this.menu);
          };
        })(this),
        google: {
          families: ['Enriqueta:400:latin']
        }
      };
    };

    PreloadState.prototype.preload = function() {
      var i, id, x, y, zIndex;
      x = this.world.centerX - (progressW / 2);
      y = this.world.centerY - (progressH / 2);
      this.progressTrack = this.add.sprite(x, y, 'progress-bar-bg');
      this.progressThumb = this.add.sprite(x, y, 'progress-bar-fg');
      this.load.setPreloadSprite(this.progressThumb);
      this.load.script('webfont', '//ajax.googleapis.com/ajax/libs/webfont/1/webfont.js');
      this.load.audio('bgm', ['assets/morning-stroll.mp3'], true);
      this.load.spritesheet('button', 'assets/button.png', buttonW, buttonH);
      this.load.image('bg-start', 'assets/bg-start.jpg');
      this.load.image('balcony', 'assets/tiles-auto-balcony.png');
      for (zIndex = i = 16; i >= 1; zIndex = --i) {
        id = (16 - zIndex + 10000).toString().substr(1);
        this.load.image("bg" + zIndex, "assets/bg-_" + id + "_" + zIndex + ".png");
      }
      this.load.spritesheet('mate', 'assets/mate.png', playerW, playerH);
      return this.load.spritesheet('player', 'assets/player.png', playerW, playerH);
    };

    PreloadState.prototype.create = function() {
      return this.progressThumb.cropEnabled = false;
    };

    PreloadState.prototype.update = function() {
      if (this._onceMenu == null) {
        this._onceMenu = _.once(this.menu);
      }
      if (this.cache.isSoundDecoded('bgm')) {
        return this._onceMenu();
      } else {
        return this.time.events.add(Timer.HALF, this.update);
      }
    };

    PreloadState.prototype.menu = _.after(2, function() {
      var state;
      state = developing ? 'play' : 'menu';
      return this.state.start(state);
    });

    return PreloadState;

  })(State);
  return PreloadState;
});

//# sourceMappingURL=state-preload.js.map
