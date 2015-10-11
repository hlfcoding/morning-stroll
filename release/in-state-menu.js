define(['phaser', 'underscore', 'app/defines', 'app/helpers'], function(Phaser, _, defines, Helpers) {
  'use strict';
  var DebugMixin, InStateMenu, Keyboard, TextMixin, fontSmall;
  Keyboard = Phaser.Keyboard;
  fontSmall = defines.fontSmall;
  DebugMixin = Helpers.DebugMixin, TextMixin = Helpers.TextMixin;
  InStateMenu = (function() {
    function InStateMenu(textItems, game, options) {
      var ref;
      this.textItems = textItems;
      if (options == null) {
        options = {};
      }
      ref = _.defaults(options, {
        baseTextStyle: {
          fill: '#fff',
          font: 'Enriqueta'
        },
        layout: {
          y: 120,
          baseline: 40
        },
        pauseHandler: function(paused) {
          return game.paused = paused;
        },
        toggleKeyCode: Keyboard.P
      }), this.baseTextStyle = ref.baseTextStyle, this.pauseHandler = ref.pauseHandler, this.layout = ref.layout, this.toggleKeyCode = ref.toggleKeyCode;
      this.add = game.add, this.height = game.height, this.input = game.input, this.width = game.width, this.world = game.world;
      this._initialize();
    }

    InStateMenu.prototype._initialize = function() {
      var i, len, ref, ref1, style, text;
      this.group = this.add.group(null, 'in-state-menu', true);
      this.overlay = this.add.graphics(0, 0, this.group);
      this.overlay.beginFill(0x000000, 0.8);
      this.overlay.drawRect(0, 0, this.width, this.height);
      this.overlay.endFill();
      ref = this.textItems;
      for (i = 0, len = ref.length; i < len; i++) {
        ref1 = ref[i], text = ref1[0], style = ref1[1];
        this._addText(text, style);
      }
      this._addText('Press P again to continue', {
        fontSize: fontSmall
      });
      this.toggleKey = this.input.keyboard.addKey(this.toggleKeyCode);
      this.toggleKey.onDown.add(this.toggle, this);
      this.input.keyboard.removeKeyCapture(this.toggleKeyCode);
      this.toggle(false);
      return this._initDebugging();
    };

    InStateMenu.prototype._initDebugging = function() {
      var completedInit;
      this.debugNamespace = 'in-state-menu';
      this.tracing = true;
      return completedInit = this._initDebugMixin();
    };

    InStateMenu.prototype.destroy = function() {
      this.group.destroy();
      return this.toggleKey.onDown.removeAll(this);
    };

    InStateMenu.prototype.toggle = function(toggled) {
      if (!_.isBoolean(toggled)) {
        toggled = !this.group.visible;
      }
      this.group.visible = toggled;
      return this.pauseHandler(toggled);
    };

    InStateMenu.prototype._addText = function(text, style) {
      _.defaults(style, this.baseTextStyle);
      return this.addCenteredText(text, this.layout, style, this.group);
    };

    return InStateMenu;

  })();
  _.extend(InStateMenu.prototype, DebugMixin, TextMixin);
  return InStateMenu;
});

//# sourceMappingURL=in-state-menu.js.map
