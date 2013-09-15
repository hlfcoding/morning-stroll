## Notes

###Code not ported

(1c0ec7d):

- PlayState.as
  - 82
  - 86

###Code adapted

(1c0ec7d):

- PlayState.as
  - 90 to 98 combined, callbacks changed to signals
- Platform.as
  - `mapData` already exists

():

- Player.as
  - `currently` -> `state`
  - `controlled` -> IS_CONTROLLED, using `flags`
  - [`animDelegate` changed to use signals]
  - `updateFocus` -> NEEDS_CAMERA_FOCUS
  - default state `FALLING` -> `STILL`
  - `inMidAir` -> `isInMidAir`
  - `justFell` -> `isJustFallen`
  - `jumpTimer`, `cameraFocus`
  - added:
    - no parity: `facing`
  - events:
    - putting events in a collection and dynamically dispatching them
    - using lowest priority for animation delegation
    - making animation delegate an object
    - using partial application to send in target to handler

General:

- FlxObject -> GameObject
- FlxTimer -> setTimeout
  - `start` -> `timer = setTimeout`
  - `finished` -> `timer?`
  - `stop` -> `clearTimeout timer`
- no parity:
  - `FlxSprite::finished`
  - `FlxSprite::updateAnimation`
  - `FlxSprite::offset`
- `isTouching` -> `touching`
- `justTouched` -> `wasTouching`

## Todos

- Fully port existing code.
- Add and integrate UnderscoreJS.
- Refactor on Phaser:
  - Use signals to replace delegation.
  - Make camera speed be from a real tween.

## Legend

- Prefixes:
  - `p` - previous.
  - `o` - original.
