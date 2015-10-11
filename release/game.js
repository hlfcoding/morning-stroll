requirejs.config({
  baseUrl: 'lib',
  paths: {
    app: '../release'
  },
  shim: {
    'dat.gui': {
      exports: 'dat'
    },
    phaser: {
      exports: 'Phaser'
    }
  }
});

requirejs(['phaser', 'app/defines', 'app/helpers', 'app/state-boot', 'app/state-menu', 'app/state-preload', 'app/state-play'], function(Phaser, defines, Helpers, BootState, MenuState, PreloadState, PlayState) {
  'use strict';
  var Point, PointMixin, StateManagerMixin, debugging, game, gameH, gameW, initSite;
  Point = Phaser.Point;
  debugging = defines.debugging, gameH = defines.gameH, gameW = defines.gameW;
  PointMixin = Helpers.PointMixin, StateManagerMixin = Helpers.StateManagerMixin;
  _.extend(Point.prototype, PointMixin);
  game = new Phaser.Game(gameW, gameH, Phaser.AUTO, document.getElementById('morning-stroll'));
  _.extend(game.state, StateManagerMixin);
  game.state.add('boot', BootState);
  game.state.add('preload', PreloadState);
  game.state.add('menu', MenuState);
  game.state.add('play', PlayState);
  game.state.start('boot');
  initSite = function() {
    return require(['app/site'], function(site) {
      return site.setGame(game);
    });
  };
  if (document.readyState === 'complete') {
    initSite();
  } else {
    document.addEventListener('DOMContentLoaded', initSite);
  }
  if (debugging === true) {
    return window.game = game;
  }
});

//# sourceMappingURL=game.js.map
