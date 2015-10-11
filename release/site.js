define(['app/defines'], function(defines) {
  'use strict';
  var _game, classlist, csstransitions, fiddle, flipDuration, frame, gameParent, history, prefixedCSS, site, style, toggleAbout;
  _game = null;
  document.body.className = 'ready';
  classlist = Modernizr.classlist, csstransitions = Modernizr.csstransitions, history = Modernizr.history, prefixedCSS = Modernizr.prefixedCSS;
  if (history) {
    window.history.replaceState({
      fiddle: false
    }, document.title);
    fiddle = document.querySelector('#fiddle');
    fiddle.addEventListener('click', function() {
      defines.developing = true;
      window.history.pushState({
        fiddle: true
      }, document.title + " (fiddling)", 'fiddle');
      return fiddle.setAttribute('disabled', '');
    });
    window.addEventListener('popstate', function(e) {
      if (_game.state.current === 'play') {
        return window.location.reload();
      } else if (e.state.fiddle === false) {
        defines.developing = false;
        return fiddle.removeAttribute('disabled');
      }
    });
    gameParent = document.querySelector('#morning-stroll');
    gameParent.addEventListener('state:play', function() {
      return fiddle.setAttribute('disabled', '');
    });
    gameParent.addEventListener('state:menu', function() {
      fiddle.removeAttribute('disabled');
      if (window.history.state.fiddle === true) {
        return window.history.back();
      }
    });
  }
  if (classlist && csstransitions) {
    style = window.getComputedStyle(document.querySelector('#framed'));
    flipDuration = (parseFloat(style[prefixedCSS('transition-duration')]) + parseFloat(style[prefixedCSS('transition-delay')])) * 1000;
    frame = document.querySelector('#frame');
    toggleAbout = document.querySelector('#toggle-about');
    toggleAbout.addEventListener('click', function() {
      frame.classList.toggle('flipped');
      frame.classList.add('flipping');
      toggleAbout.setAttribute('disabled', '');
      return setTimeout(function() {
        frame.classList.remove('flipping');
        return toggleAbout.removeAttribute('disabled');
      }, flipDuration);
    });
  }
  return site = {
    setGame: function(game) {
      return _game = game;
    }
  };
});

//# sourceMappingURL=site.js.map
