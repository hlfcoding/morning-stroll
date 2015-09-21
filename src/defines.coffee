# Defines
# =======

define [], () ->

  'use strict'

  defines = 

    # Turn off here to disable entirely (@release).
    # Off by default for performance.
    debugging: off
    # Turn off here to disable entirely (@release).
    developing: on

    progressW: 360
    progressH: 8

    buttonW: 80
    buttonH: 30

    playerH: 72
    playerW: 72

    artH: 2912
    mapH: 3152 # +240

    deadzoneH: 100
    shakeFallH: 300
