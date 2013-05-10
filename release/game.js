// Generated by CoffeeScript 1.6.2
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['phaser', 'app/play-state'], function(Phaser, PlayState) {
    var C, MorningStroll;

    MorningStroll = (function(_super) {
      __extends(MorningStroll, _super);

      MorningStroll.WIDTH = 416;

      MorningStroll.HEIGHT = 600;

      MorningStroll.ID = 'morning-stroll';

      function MorningStroll() {
        MorningStroll.__super__.constructor.call(this, this, 'morning-stroll', C.WIDTH, C.HEIGHT, this.init, this.create, this.update);
      }

      MorningStroll.prototype.init = function() {};

      MorningStroll.prototype.create = function() {
        return this.switchState(new PlayState(this));
      };

      MorningStroll.prototype.update = function() {};

      MorningStroll.prototype.start = function() {};

      return MorningStroll;

    })(Phaser.Game);
    return C = MorningStroll;
  });

}).call(this);
