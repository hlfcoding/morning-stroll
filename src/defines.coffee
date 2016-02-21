# Defines
# =======
# Constants that get shared throughout game logic.

define [], () ->

  'use strict'

  defines =

    # Turn off here to disable entirely (@release).
    # Off by default for performance.
    # Controllable via gui checkbox.
    debugging: off
    # Turn off here to disable entirely (@release).
    # Controllable via fiddle button.
    developing: off

    # Emit DOM events on (some) game state changes?
    domStateEvents: on

    # Game viewport size
    gameW: 416
    gameH: 600

    # Map height: without and with parallax added.
    artH: 2912
    mapH: 3136 # +224

    # Arbitrary, fragile button size.
    buttonW: 80
    buttonH: 30

    # Size of center region in viewport where player's camera-follow is off.
    deadzoneH: 100
    # Required distance to fall to trigger camera shake.
    shakeFallH: 300

    # Standard font sizes also defined in the styling.
    fontLarge: 32
    fontSmall: 16

    # Player sprite tile measures.
    playerH: 72
    playerW: 72
    playerYOffset: 16

    # Preload progress bar size, tied to game viewport size.
    progressW: 360
    progressH: 8
