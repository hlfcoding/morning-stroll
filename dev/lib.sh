#!/bin/bash

# Run from project root.

cd lib

curl -O https://raw.github.com/jrburke/requirejs/master/require.js \
     -O https://raw.github.com/amdjs/underscore/master/underscore.js \
     https://raw.github.com/hlfcoding/phaser/amd/build/phaser.amd.js -o phaser.js

cd -
