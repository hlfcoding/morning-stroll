var hasProp = {}.hasOwnProperty,
  slice = [].slice;

define(['dat.gui', 'phaser', 'underscore'], function(dat, Phaser, _) {
  'use strict';
  var AnimationMixin, CameraMixin, DebugDisplayMixin, DebugMixin, Easing, Point, PointMixin, RegExps, RenderTexture, Sprite, StateManagerMixin, TextMixin, Timer, addOpenFolder, addRange, autoSetTiles, isPlainObject, kPhaserLayoutX, kPhaserLineRatio;
  Easing = Phaser.Easing, Point = Phaser.Point, RenderTexture = Phaser.RenderTexture, Sprite = Phaser.Sprite, Timer = Phaser.Timer;
  RegExps = {
    PrettyHashRemove: /[{}"]/g,
    PrettyHashPad: /[:,]/g
  };
  AnimationMixin = {
    playAnimation: function(nameOrFrame, interrupt) {
      var frame, name, ref, ref1;
      if (interrupt == null) {
        interrupt = true;
      }
      if (interrupt === false && ((ref = this.animation) != null ? ref.isPlaying : void 0)) {
        return false;
      }
      if (_.isNumber(nameOrFrame)) {
        frame = nameOrFrame;
        this.animations.frame = frame;
        this.animation = null;
      } else {
        name = nameOrFrame;
        if (((ref1 = this.animation) != null ? ref1.name : void 0) === name) {
          return false;
        }
        this.animation = this.animations.play(name);
      }
      if (typeof this.debug === "function") {
        this.debug('animation', nameOrFrame);
      }
      return this.animation;
    },
    fadeTo: function(gameObject, duration, alpha, init) {
      var tween;
      if (init == null) {
        init = true;
      }
      if (init) {
        gameObject.alpha = (alpha === 0 ? 1 : 0);
      }
      return tween = this.add.tween(gameObject).to({
        alpha: alpha
      }, duration, 'Cubic', true);
    }
  };
  CameraMixin = {
    updatePositionWithCursors: function(cursors, velocity) {
      if (velocity == null) {
        velocity = 4;
      }
      if (cursors.up.isDown) {
        return this.y -= velocity;
      } else if (cursors.down.isDown) {
        return this.y += velocity;
      } else if (cursors.left.isDown) {
        return this.x -= velocity;
      } else if (cursors.right.isDown) {
        return this.x += velocity;
      }
    },
    isShaking: function() {
      return this._shake._counter > 0;
    },
    shake: function(config) {
      if (config == null) {
        config = {};
      }
      this._shake = _.defaults(config, {
        _counter: -1,
        count: 4,
        sensitivity: 4,
        shakeX: true,
        shakeY: true
      });
      return this._shake._counter = this._shake.count;
    },
    updateShake: function() {
      var _counter, direction, offset, ref, sensitivity, shakeX, shakeY, x, y;
      if (this._shake == null) {
        return false;
      }
      ref = this._shake, _counter = ref._counter, sensitivity = ref.sensitivity, shakeX = ref.shakeX, shakeY = ref.shakeY;
      if (_counter === 0) {
        return false;
      }
      direction = _counter % 2 === 0 ? -1 : 1;
      offset = _counter * sensitivity * direction;
      x = this.x, y = this.y;
      if (shakeX) {
        x += offset;
      }
      if (shakeY) {
        y += offset;
      }
      this.setPosition(x, y);
      if (_counter > 0) {
        return this._shake._counter--;
      }
    }
  };
  DebugMixin = {
    _initDebugMixin: function(gui) {
      var toggle;
      if (this.debugging == null) {
        this.debugging = true;
      }
      if (this.tracing == null) {
        this.tracing = false;
      }
      this.debugTextItems = {};
      if (gui == null) {
        return false;
      }
      this.gui = gui;
      toggle = this.gui.add(this, 'debugging');
      toggle.listen();
      toggle.onFinishChange((function(_this) {
        return function() {
          return _this.debugTextItems = {};
        };
      })(this));
      this.gui.add(this, 'tracing');
      return true;
    },
    debug: function(label, value, details) {
      if (!this.debugging) {
        return;
      }
      if (_.isNumber(value)) {
        value = parseFloat(value.toFixed(2));
      }
      if (value instanceof Point) {
        value = this._prettyHash(this._prettyPoint(value));
      }
      if ((details != null ? details.position : void 0) && details.position instanceof Point) {
        details.position = this._prettyPoint(details.position);
      }
      if (this.tracing) {
        label = this.debugNamespace + ":" + label;
        if (details != null) {
          return console.trace(label, value, details);
        } else {
          return console.trace(label, value);
        }
      } else {
        if (_.isArray(value) && (_.isArray(value[0]) || _.isPlainObject(value[0]))) {
          label = this.debugNamespace + ":" + label;
          console.groupCollapsed(label);
          if (typeof console.table === "function") {
            console.table(value);
          }
          return console.groupEnd();
        } else {
          details = details != null ? this._prettyHash(details) : '';
          return this.debugTextItems[label] = (label + ": " + value + " " + details).trim();
        }
      }
    },
    _prettyPoint: function(point) {
      return _.chain(point).pick('x', 'y').mapObject(function(n) {
        return parseFloat(n.toFixed(2));
      }).value();
    },
    _prettyHash: function(hash) {
      return JSON.stringify(hash).replace(RegExps.PrettyHashRemove, '').replace(RegExps.PrettyHashPad, '$& ');
    }
  };
  kPhaserLayoutX = -8;
  kPhaserLineRatio = 1.8;
  DebugDisplayMixin = {
    _initDebugDisplayMixin: function(game) {
      if (this.debugFontSize == null) {
        this.debugFontSize = 9;
      }
      this._debugGutter = 2 * this.debugFontSize;
      this._debugLine = kPhaserLineRatio * this.debugFontSize;
      this.debugDisplay = game.debug;
      return this.debugDisplay.font = this.debugFontSize + "px Menlo";
    },
    resetDebugDisplayLayout: function() {
      this._layoutX = this._debugGutter + kPhaserLayoutX;
      return this._layoutY = this._debugGutter;
    },
    renderDebugDisplayItems: function(items, lines) {
      var label, results, text;
      if (_.isFunction(items) && (lines != null)) {
        items(this._layoutX, this._layoutY);
        return this._layoutY += lines * this._debugLine;
      } else {
        results = [];
        for (label in items) {
          if (!hasProp.call(items, label)) continue;
          text = items[label];
          this.debugDisplay.text(text, this._layoutX, this._layoutY, null, this.debugDisplay.font);
          results.push(this._layoutY += this._debugLine);
        }
        return results;
      }
    }
  };
  addOpenFolder = function() {
    var folder;
    folder = this.addFolder.apply(this, arguments);
    folder.open();
    return folder;
  };
  addRange = function(obj, prop, chain) {
    var gui, max, min, ref, value;
    if (chain == null) {
      chain = true;
    }
    value = obj[prop];
    ref = [value / 2, 2 * value], min = ref[0], max = ref[1];
    if (value < 0) {
      gui = this.add(obj, prop, max, min);
    } else if (value > 0) {
      gui = this.add(obj, prop, min, max);
    } else {
      gui = this.add(obj, prop);
    }
    if (chain) {
      return this;
    } else {
      return gui;
    }
  };
  _.extend(dat.GUI.prototype, {
    addOpenFolder: addOpenFolder,
    addRange: addRange
  });
  autoSetTiles = function(tiles) {
    var bottom, c, col, i, j, left, len, len1, r, result, right, row, tile, top;
    result = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = tiles.length; i < len; i++) {
        row = tiles[i];
        results.push(_.clone(row));
      }
      return results;
    })();
    for (r = i = 0, len = result.length; i < len; r = ++i) {
      row = result[r];
      for (c = j = 0, len1 = row.length; j < len1; c = ++j) {
        col = row[c];
        if (!(col === 1)) {
          continue;
        }
        left = right = top = bottom = 1;
        if (c !== 0) {
          left = tiles[r][c - 1];
        }
        if (c !== row.length - 1) {
          right = tiles[r][c + 1];
        }
        if (r !== 0) {
          top = tiles[r - 1][c];
        }
        if (r !== tiles.length - 1) {
          bottom = tiles[r + 1][c];
        }
        switch ([top, right, bottom, left].join()) {
          case '0,0,0,0':
            tile = 1;
            break;
          case '1,0,0,0':
            tile = 2;
            break;
          case '0,1,0,0':
            tile = 3;
            break;
          case '1,1,0,0':
            tile = 4;
            break;
          case '0,0,1,0':
            tile = 5;
            break;
          case '1,0,1,0':
            tile = 6;
            break;
          case '0,1,1,0':
            tile = 7;
            break;
          case '1,1,1,0':
            tile = 8;
            break;
          case '0,0,0,1':
            tile = 9;
            break;
          case '1,0,0,1':
            tile = 10;
            break;
          case '0,1,0,1':
            tile = 11;
            break;
          case '1,1,0,1':
            tile = 12;
            break;
          case '0,0,1,1':
            tile = 13;
            break;
          case '1,0,1,1':
            tile = 14;
            break;
          case '0,1,1,1':
            tile = 15;
            break;
          case '1,1,1,1':
            tile = 16;
        }
        row[c] = tile;
      }
    }
    return result;
  };
  PointMixin = {
    addPoint: function(point) {
      return this.add(point.x, point.y);
    },
    dividePoint: function(point) {
      return this.divide(point.x, point.y);
    },
    multiplyPoint: function(point) {
      return this.multiply(point.x, point.y);
    },
    subtractPoint: function(point) {
      return this.subtract(point.x, point.y);
    }
  };
  StateManagerMixin = {
    startWithTransition: function() {
      var create, destroy, duration, easing, init, interstitial, properties, ref, startArgs, state, stateName, texture, transitionOptions;
      transitionOptions = arguments[0], startArgs = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (transitionOptions == null) {
        transitionOptions = {};
      }
      ref = _.defaults(transitionOptions, {
        duration: 2 * Timer.SECOND,
        easing: Easing.Exponential.InOut,
        properties: {
          alpha: 0
        }
      }), duration = ref.duration, easing = ref.easing, properties = ref.properties;
      stateName = startArgs[0];
      state = this.states[stateName];
      init = state.init, create = state.create;
      this.game.camera.unfollow();
      this.game.paused = true;
      texture = new RenderTexture(this.game, this.game.width, this.game.height, "transition-to-" + stateName);
      texture.renderXY(this.game.world, -this.game.camera.x, -this.game.camera.y);
      this.game.paused = false;
      interstitial = new Sprite(this.game, 0, 0, texture);
      interstitial.fixedToCamera = true;
      destroy = function() {
        if (!((texture != null) && (interstitial != null))) {
          return;
        }
        texture.destroy();
        interstitial.destroy();
        texture = interstitial = null;
        state.init = init;
        return state.create = create;
      };
      state.init = (function(_this) {
        return function() {
          if (init != null) {
            init.apply(state, arguments);
          }
          return _this.game.add.existing(interstitial);
        };
      })(this);
      state.create = (function(_this) {
        return function() {
          if (create != null) {
            create.apply(state, arguments);
          }
          interstitial.bringToTop();
          return _this.game.add.tween(interstitial).to(properties, duration, easing, true).onComplete.addOnce(destroy);
        };
      })(this);
      _.delay(destroy, 2 * duration);
      return this.start.apply(this, startArgs);
    }
  };
  TextMixin = {
    addCenteredText: function(text, layout, style, group) {
      _.defaults(style, {
        boundsAlignH: 'center',
        boundsAlignV: 'middle'
      });
      text = this.add.text(this.world.centerX, layout.y, text, style, group);
      text.anchor.setTo(0.5);
      layout.y += text.height + layout.baseline;
      return text;
    }
  };
  isPlainObject = function(arg) {
    return _.isObject(arg) && !_.isFunction(arg);
  };
  _.mixin({
    isPlainObject: isPlainObject
  });
  return {
    AnimationMixin: AnimationMixin,
    CameraMixin: CameraMixin,
    DebugMixin: DebugMixin,
    DebugDisplayMixin: DebugDisplayMixin,
    PointMixin: PointMixin,
    RegExps: RegExps,
    StateManagerMixin: StateManagerMixin,
    TextMixin: TextMixin,
    autoSetTiles: autoSetTiles
  };
});

//# sourceMappingURL=helpers.js.map
