#!/bin/bash

# Run from project root.

cd lib

curl -O https://raw.github.com/jrburke/requirejs/master/require.js \
     -O https://raw.github.com/amdjs/underscore/master/underscore.js \
     https://raw.github.com/photonstorm/phaser/master/build/phaser-093.js -o phaser.js

cd -
