var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

define(['phaser', 'app/defines', 'app/helpers'], function(Phaser, defines, Helpers) {
  'use strict';
  var MenuState, State, TextMixin, domStateEvents, fontLarge, fontSmall;
  State = Phaser.State;
  domStateEvents = defines.domStateEvents, fontLarge = defines.fontLarge, fontSmall = defines.fontSmall;
  TextMixin = Helpers.TextMixin;
  MenuState = (function(superClass) {
    extend(MenuState, superClass);

    function MenuState() {
      return MenuState.__super__.constructor.apply(this, arguments);
    }

    MenuState.prototype.init = function() {
      var e;
      if (domStateEvents) {
        e = document.createEvent('CustomEvent');
        e.initCustomEvent('state:menu', false, false, void 0);
        return this.game.parent.dispatchEvent(e);
      }
    };

    MenuState.prototype.create = function() {
      var buttonX, buttonY;
      this.add.image(0, 0, 'bg-start');
      this.layout = {
        y: this.game.height / 4,
        baseline: 40
      };
      this._addText('Morning Stroll', {
        fontSize: fontLarge
      });
      this._addText('Climb and see!', {
        fontSize: fontSmall
      });
      this.layout.y += 2 * this.layout.baseline;
      buttonX = (this.game.width - defines.buttonW) / 2;
      buttonY = this.layout.y - (defines.buttonH / 2);
      this.add.button(buttonX, buttonY, 'button', this.play, this, 1, 0, 2);
      return this._addText('start', {
        fontSize: fontSmall
      });
    };

    MenuState.prototype.update = function() {};

    MenuState.prototype.play = function() {
      return this.state.startWithTransition(null, 'play');
    };

    MenuState.prototype._addText = function(text, style) {
      _.defaults(style, {
        fill: '#fff',
        font: 'Enriqueta'
      });
      return text = this.addCenteredText(text, this.layout, style);
    };

    return MenuState;

  })(State);
  _.extend(MenuState.prototype, TextMixin);
  return MenuState;
});

//# sourceMappingURL=state-menu.js.map
