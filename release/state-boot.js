var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

define(['phaser'], function(Phaser) {
  'use strict';
  var BootState;
  BootState = (function(superClass) {
    extend(BootState, superClass);

    function BootState() {
      return BootState.__super__.constructor.apply(this, arguments);
    }

    BootState.prototype.init = function() {
      this.input.maxPointers = 1;
      return this.stage.disableVisibilityChange = true;
    };

    BootState.prototype.preload = function() {
      this.load.image('progress-bar-bg', 'assets/progress-bar-bg.png');
      return this.load.image('progress-bar-fg', 'assets/progress-bar-fg.png');
    };

    BootState.prototype.create = function() {
      return this.state.start('preload');
    };

    return BootState;

  })(Phaser.State);
  return BootState;
});

//# sourceMappingURL=state-boot.js.map
