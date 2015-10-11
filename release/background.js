define(['underscore', 'app/defines', 'app/helpers'], function(_, defines, Helpers) {
  'use strict';
  var Background, DebugMixin;
  DebugMixin = Helpers.DebugMixin;
  Background = (function() {
    function Background(config, game) {
      if (config == null) {
        config = {};
      }
      this.layers = [];
      _.defaults(config, {
        parallaxFactor: 0.95,
        parallaxBuffer: 1.7,
        layoutMode: 'full'
      });
      this.layoutMode = config.layoutMode, this.parallaxBuffer = config.parallaxBuffer, this.parallaxFactor = config.parallaxFactor, this.parallaxTolerance = config.parallaxTolerance;
      this._topZIndex = 1;
      this._initialize(game);
    }

    Background.prototype._initialize = function(game) {
      this.add = game.add, this.camera = game.camera;
      this.group = this.add.group();
      this.group.visible = false;
      return this._initDebugging();
    };

    Background.prototype._initDebugging = function() {
      this.debugNamespace = 'background';
      this.debugging = defines.debugging;
      return this._initDebugMixin();
    };

    Background.prototype.destroy = function() {};

    Background.prototype.addImages = function(nameTemplate, topZIndex, bottomZIndex) {
      var i, image, name, ref, ref1, results, zIndex;
      if (bottomZIndex == null) {
        bottomZIndex = 1;
      }
      this._topZIndex = topZIndex;
      results = [];
      for (zIndex = i = ref = bottomZIndex, ref1 = topZIndex; ref <= ref1 ? i <= ref1 : i >= ref1; zIndex = ref <= ref1 ? ++i : --i) {
        name = nameTemplate({
          zIndex: zIndex
        });
        image = this.add.image(0, 0, name, this.group);
        image.autoCull = true;
        results.push(this.layers.push({
          image: image,
          zIndex: zIndex
        }));
      }
      return results;
    };

    Background.prototype.layout = function() {
      var factor, i, image, layer, len, ref, zIndex;
      ref = this.layers;
      for (i = 0, len = ref.length; i < len; i++) {
        layer = ref[i];
        image = layer.image, zIndex = layer.zIndex;
        factor = Math.pow(zIndex / this.layers.length, 2) * this.parallaxFactor;
        factor = (factor + this.parallaxBuffer / 2) / this.parallaxBuffer;
        layer.scrollFactor = Math.min(1, factor);
        layer.scrollResistance = Math.max(0, 1 - factor);
      }
      return this.debug('layers', this.layers);
    };

    Background.prototype.update = function() {
      var i, image, len, ref, ref1, results, scrollFactor, scrollResistance, zIndex;
      ref = this.layers;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        ref1 = ref[i], image = ref1.image, zIndex = ref1.zIndex, scrollFactor = ref1.scrollFactor, scrollResistance = ref1.scrollResistance;
        image.y = this.camera.y * scrollResistance;
        if (zIndex !== 1) {
          image.y += this.parallaxTolerance;
          if (zIndex !== this._topZIndex) {
            results.push(image.y -= this.parallaxTolerance * Math.pow(scrollFactor, 1 / 3));
          } else {
            results.push(void 0);
          }
        } else {
          results.push(void 0);
        }
      }
      return results;
    };

    return Background;

  })();
  _.extend(Background.prototype, DebugMixin);
  return Background;
});

//# sourceMappingURL=background.js.map
