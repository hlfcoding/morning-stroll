```js
package
{
  import org.flixel.FlxCamera;
  import org.flixel.FlxG;
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxRect;
  import org.flixel.FlxSound;
  import org.flixel.FlxSprite;
  import org.flixel.FlxState;
  import org.flixel.FlxTimer;
  import org.flixel.FlxU;

  // The main coordinator: part config list, part asset list, part delegate.
  // Handles all of the character animations, and custom platform generation.
  // The stage is set up based on the bg group's bounds; the platform and
  // camera are set up around it.

  public class PlayState extends FlxState
    implements IPlayerAnimationDelegate, IPlatformDelegate
  {
    // Tileset that works with AUTO mode (best for thin walls)
    [Embed(source='data/tiles-auto-balcony.png')]private static var ImgAutoTiles:Class;
    // Tileset that works with OFF mode (do what you want mode)
    [Embed(source='data/tiles-manual-placeholder.png')]private static var ImgCustomTiles:Class;

    [Embed(source="data/morning-stroll.mp3")]private static var SndMain:Class;

    // The dynamically generated and extended FlxTilemap.
    private var platform:Platform;
    private static const FLOOR_HEIGHT:uint = 32;

    // Some game switches.
    private var fallChecking:Boolean;

    // Game state.
    private var gameStatePollInterval:FlxTimer;
    private var didTheEnd:Boolean;
    private var endAnimDuration:Number;

    // The music.
    private var targetMusicVolume:Number = 0;
    private static const MUSIC_VOLUME_FACTOR:Number = 1.3;
    private static const MIN_MUSIC_VOLUME:Number = 0.2;
    private static const MAX_MUSIC_VOLUME:Number = 0.8;
    private var playMusic:Boolean;

    // Flixel Methods
    // --------------
    override public function create():void
    {
      FlxG.mouse.hide();

      // Globals.
      fallChecking = false;
      FlxG.debug = false;
      playMusic = !FlxG.debug;

      // Start our setup chain.
      setupPlatform();
      setupPlatformAfter();
      setupPlatformAndPlayerAfter();

      // Internals.
      // Don't do expensive operations too often, if possible.
      gameStatePollInterval = new FlxTimer();
      gameStatePollInterval.start(2, Number.POSITIVE_INFINITY,
        function(onTimer:FlxTimer):void {
          updateGameState(true);
        }
      );
      didTheEnd = false;

    }

    override public function destroy():void
    {
      super.destroy();

      gameStatePollInterval.destroy();
    }

    override public function update():void
    {
      // Start our update chain.
      updatePlatform();
      updatePlatformAfter();
      updatePlatformAndPlayerAfter();

      super.update();
    }
    override public function draw():void
    {
      super.draw();
    }

    // Setup Routines
    // --------------
    // Since the observer pattern is too slow, we'll just name our functions to be like hooks.
    // The platform is the first thing that gets set up.
    private function setupPlatform():void
    {
      // Creates a new tilemap with no arguments.
      platform = new Platform();

      // Hook into delegated methods.
      platform.delegate = this;

      // Set the bounds based on the background.
      // TODO - Fix parallax bug.
      platform.bounds = new FlxRect(bg.bounds.x, bg.bounds.y, bg.bounds.width, bg.bounds.height + FLOOR_HEIGHT);

      // Make our platform.
      platform.makeMap(ImgAutoTiles);

      // Set points.
      platform.startingPoint.x = PLAYER_WIDTH;
      platform.startingPoint.y = platform.height - PLAYER_HEIGHT;
      var ledge:PlatformLedge = platform.ledges[platform.ledges.length-1]; // Always reads top-to-bottom.
      platform.endingPoint.y = (platform.numRows-1 - ledge.rowIndex) * platform.tileHeight;
      platform.endingPoint.x = (ledge.size * platform.tileWidth) / 2;
      if (ledge.facing == FlxObject.RIGHT)
      {
        platform.endingPoint.x = platform.bounds.width - platform.endingPoint.x;
      }

      // Process settings.
      platform.init();
      // FlxG.log('Ending point: '+[platform.numRows-1 - ledge.rowIndex, platform.endingPoint.x, platform.endingPoint.y]);
    }
    // Hooks.
    private function setupPlatformAfter():void
    {
      // Draw player at the bottom.
      setupPlayer(platform.startingPoint);

      // Move until we don't overlap.
      while (platform.overlaps(player))
      {
        if (player.x <= 0)
        {
          player.x = FlxG.width;
        }
        player.x -= platform.tileWidth;
      }
      // Draw its mate at the top.
      setupMate(platform.endingPoint);
    }
    private function setupPlatformAndPlayerAfter():void
    {
      setupCamera();
      setupAudio();
    }
    // Hooked routines.
    private function setupPlayer(start:FlxPoint):void
    {
      // Find start position for player.

      player = new Player(start.x, start.y);

      // Bounding box tweaks.
      player.height = player.frameHeight / 2;
      player.offset.y = player.frameHeight - player.height - 2;
      player.tailOffset.x = 35;
      player.headOffset.x = 10;
      player.width = player.frameWidth - player.tailOffset.x;
      player.face(FlxObject.RIGHT);

      // These are just set as a base to derive player physics
      player.naturalForces.x = 1000; // Friction.
      player.naturalForces.y = 600; // Gravity.

      // Basic player physics.
      player.maxVelocity.x = 220; // This gets achieved rather quickly.
      player.maxVelocity.y = 1500; // Freefall.

      // Player jump physics.
      // The bare minimum to clear the biggest possible jump.
      player.jumpMaxVelocity.y = -320; // This gets achieved rather quickly.
      player.jumpAccel.y = -2800; // Starting jump force.

      // Animations.
      // Make sure to add end transitions, otherwise the last frame is skipped if framerate is low.
      player.addAnimation('still',[17], 12);
      player.addAnimation('idle', [], 12, false);
      player.animDelegate = this;

      // Process settings.
      player.init();
    }
    private function setupMate(start:FlxPoint):void
    {
      mate = new FlxSprite(start.x, start.y);
      mate.height = 46;
      mate.offset.y = mate.frameHeight - mate.height;
      mate.y -= mate.frameHeight - mate.height - 6; // TODO - Magic pixel hack.
      mate.x -= 20;

    }
    private function setupCamera():void
    {
      // Follow the player's custom focus.
      FlxG.camera.follow(player.cameraFocus);
      // Constrain the camera to the platform.
      platform.follow();
      // Don't show the floor.
      FlxG.camera.setBounds(bg.bounds.x, bg.bounds.y, bg.bounds.width, bg.bounds.height);
    }
    private function setupAudio():void
    {
      if (!playMusic) return;
      FlxG.music = FlxG.loadSound(SndMain, targetMusicVolume, true, false, false);
      updateAudio(true);
      FlxG.music.play();
      FlxG.watch(FlxG.music, 'volume', 'Volume');
    }

    // Update Routines
    // ---------------
    private function updatePlatform():void
    {
    }
    // Hooks.
    private function updatePlatformAfter():void
    {
      updatePlayer();
      updateMate();
    }
    private function updatePlatformAndPlayerAfter():void
    {
      updateCamera(player.justFell());
      updateAudio();
      updateGameState();
    }
    // Hooked routines.
    private function updatePlayer():void
    {
      // Tilemaps can be collided just like any other FlxObject, and flixel
      // automatically collides each individual tile with the object.
      if (player.controlled)
      {
        FlxG.collide(player, platform);
      }
      // Wrap to stage.
      if (!player.inMidAir() && player.nextAction != Player.STOP)
      {
        var pPos:FlxPoint = new FlxPoint(player.x, player.y);
        player.x = FlxU.bound(player.x, 0, (platform.width - player.width));
        var pos:FlxPoint = new FlxPoint(player.x, player.y);
        if (FlxU.getDistance(pos, pPos) > 0)
        {
          player.nextAction = Player.STOP;
        }
        pos = pPos = null;
      }
      else
      {
        player.x = FlxU.bound(player.x, 0, (platform.width - player.width));
      }
    }
    private function updateMate():void
    {
      FlxG.collide(mate, platform);
    }
    private function updateCamera(playerJustFell:Boolean):void
    {
      if (fallChecking && playerJustFell)
      {
        FlxG.camera.shake(
          0.01,
          0.1, null, true,
          FlxCamera.SHAKE_VERTICAL_ONLY
        );
      }
    }
    private function updateAudio(force:Boolean=false):void
    {
      if (!playMusic) return;
      if (didTheEnd) return;
      // The music gets louder the higher the player gets.
      // The volume smoothly updates on each landing.
      if (force || player.currently == Player.FALLING)
      {
        targetMusicVolume = (platform.startingPoint.y - player.cameraFocus.y) / platform.distanceToTravel.y;
        targetMusicVolume = Math.pow(targetMusicVolume, MUSIC_VOLUME_FACTOR);
      }
      FlxG.music.volume += (targetMusicVolume - FlxG.music.volume) / player.cameraSpeed;
      FlxG.music.volume = FlxU.bound(FlxG.music.volume, MIN_MUSIC_VOLUME, MAX_MUSIC_VOLUME);
    }
    private function updateGameState(doChecks:Boolean=false):void
    {
      if (doChecks)
      {
        // Check if player is on top of last platform, periodically.
        // Play the end screen for a while, on click, switch to start screen.
        if (player.currently == Player.STILL && platform.isAtEndingPoint(FlxObject(player)))
        {
          if (player.controlled)
          {
            player.controlled = false;
            // TODO - Follow path, then animate.
            player.addAnimationCallback(
              function(name:String, frameNumber:uint, frameIndex:uint):void {
                if (name == 'end' && frameNumber == 6)
                {
                  mate.play('end');
                }
                if (name == 'still')
                {
                  player.frame = player.frames-1;
                  mate.frame = mate.frames-1;
                }
              }
            );
            player.x = mate.x;
            player.y = mate.y;
            player.height = mate.height;
            player.offset.y = mate.offset.y;
            player.offset.x = 43;
            player.facing = FlxObject.RIGHT;
            player.play('end');
            gameStatePollInterval.stop();
            gameStatePollInterval.start(5, 1, 
              function(onTimer:FlxTimer):void {
                var title:Text, instructions:Text;
                title = new Text(0, Text.BASELINE * 2, FlxG.width,
                  "The End", Text.H1);
                instructions = new Text(0, Text.BASELINE * 4, FlxG.width,
                  "Click to play again");
                instructions.size = 16;
                // Stay on the screen.
                instructions.scrollFactor = title.scrollFactor = new FlxPoint();
                add(title);
                add(instructions);
                didTheEnd = true;
              }
            );
          }
        }
      }
      if ((didTheEnd && FlxG.mouse.justPressed()) || FlxG.keys.justPressed('Q'))
      {
        var fadeDuration:Number = 3;
        FlxG.music.fadeOut(fadeDuration);
        gameStatePollInterval.stop();
        gameStatePollInterval.start(fadeDuration, 1,
          function(onTimer:FlxTimer):void {
            MorningStroll.endGame();
          }
        );
      }
    }

    // Platform Delegate Methods
    // -------------------------
    // Tweak the ledge drawing to directly control difficulty.
    // Ledges should get smaller as the ending comes closer.
    public function platformWillSetupLedgeRow(ledge:PlatformLedge):PlatformLedge
    {
      // TODO - Harden into config.
      var facing:String = (ledge.facing == FlxObject.LEFT) ? 'left' : 'right';

      // FlxG.log('Before: '+[facing, ledge.spacing, ledge.size]);

      // The amplifier for the size. Should limit it to 0.5 to 1.5.
      var factor:Number = Math.pow(Number(platform.ledgeRowCount) / (Number(ledge.index) * 3), 0.3);

      // Amplify.
      ledge.spacing = FlxU.round(ledge.spacing / factor);
      ledge.size = FlxU.round(ledge.size * factor);

      // Normalize.
      ledge.spacing = FlxU.bound(ledge.spacing, platform.minLedgeSpacing.y, platform.maxLedgeSpacing.y);
      ledge.size = FlxU.bound(ledge.size, platform.minLedgeSize, platform.maxLedgeSize);

      // Update.
      if (ledge.facing == FlxObject.LEFT)
      {
        ledge.end = ledge.size;
      }
      else if (ledge.facing == FlxObject.RIGHT)
      {
        ledge.start = ledge.end - ledge.size;
      }

      // FlxG.log('After: '+[facing, ledge.spacing, ledge.size, factor]);

      return ledge;
    }

    // Player Delegate Methods
    // -----------------------
    // Interruptive, once.
    public function playerWillJump():void
    {
      player.updateFocus = false;
    }
  }
}

package
{
  import org.flixel.FlxG;
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxSprite;
  import org.flixel.FlxTimer;
  import org.flixel.FlxU;
  import org.flixel.system.FlxAnim;

  // Player that has more complex running and jumping abilities.
  // It makes use of an animation delegate and has a simple state
  // tracking system. It also takes into account custom offsets.
  // It also allows for custom camera tracking.
  // This class is meant to be very configurable and has many hooks.

  public class Player extends FlxSprite
  {

    public var currently:uint;
    public static const LANDING:uint = 2;

    // Note this is not always cleared.
    public var nextAction:uint;

    public var controlled:Boolean;

    public var animDelegate:IPlayerAnimationDelegate;

    public var pVelocity:FlxPoint;
    public var accelFactor:Number = 0.5;
    // This should be small. Negative creates some drag.
    public var jumpAccelDecayFactor:Number = -0.001;

    public var tailOffset:FlxPoint;
    public var headOffset:FlxPoint;

    public var cameraFocus:FlxObject;
    public var updateFocus:Boolean;
    // Basically, 1/n traveled per tween.
    public var cameraSpeed:Number = 30;

    public function Player(X:Number=0, Y:Number=0, SimpleGraphic:Class=null)
    {
      super(X, Y, SimpleGraphic);

      this.finished = true;

      this.controlled = true;

      this.pVelocity = this.velocity;

      this.tailOffset = new FlxPoint();
      this.headOffset = new FlxPoint();

      this.cameraFocus = new FlxObject(this.x, this.y, this.width, this.height);
      this.updateFocus = true;
    }

    // Flixel Methods
    // --------------
    override public function destroy():void
    {
      super.destroy();

      this.pVelocity = null;

      this.tailOffset = null;
      this.headOffset = null;

      this.cameraFocus.destroy();
      this.cameraFocus = null;
    }

    override public function update():void
    {
      if (!this.controlled)
      {
        // TODO - Move to setter.
        this.velocity = new FlxPoint();
        this.acceleration = new FlxPoint();
        return;
      }

      // Vertical
      else if (this.isTouching(FlxObject.UP) && this.currently == RISING)
      {
        // Start falling.
        this.pVelocity = null;
      }

      // - Handle focus.
      if (this.updateFocus)
      {
        this.cameraFocus.x += FlxU.round((this.x - this.cameraFocus.x) / this.cameraSpeed);
        this.cameraFocus.y += FlxU.round((this.y - this.cameraFocus.y) / this.cameraSpeed);
      }
    }

    // Update Routines
    // ---------------
    private function jumpStart():void
    {
      this.y--;
    }
  }
}

package
{
  import org.flixel.FlxG;
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxRect;
  import org.flixel.FlxTilemap;
  import org.flixel.FlxU;

  // Platform that can dynamically generate a map, and track the dynamically
  // generated ledges. This makes up for FlxTilemap's lack of an API to get
  // tile groups (ledges) that have meta-data. Only supports the `SIDE_TO_SIDE`
  // generation scheme for now.
  
  public class Platform extends FlxTilemap
  {

    public var hasCeiling:Boolean;
    public var hasFloor:Boolean;

    public var mapData:String;

    public var startingPoint:FlxPoint;
    public var endingPoint:FlxPoint;
    
    public var delegate:IPlatformDelegate;
    // To help the delegate.
    public var ledges:Array;
    public var ledgeRowCount:uint;
    
    public static const EMPTY_ROW:uint = 0;
    public static const LEDGE_ROW:uint = 1;
    public static const SOLID_ROW:uint = 2;
    
    protected static const TOP_BOTTOM:uint = 1;
    protected static const BOTTOM_TOP:uint = 2;
    

    public function Platform()
    {
      super();
      this.hasFloor = true;
      this.startingPoint = new FlxPoint();
      this.endingPoint = new FlxPoint();
      this.ledges = [];
    }
    
    // Flixel Methods
    // --------------
    override public function destroy():void
    {
      super.destroy();
      
      this.mapData = null;
      
      this.startingPoint = null;
      this.endingPoint = null;
      
      for each (var l:PlatformLedge in this.ledges) { l = null; }
      this.ledges = null;
      
      this.minLedgeSpacing = null;
      this.maxLedgeSpacing = null;
      
      this.bounds = null;
      this.delegate = null;
    }
    
    public function get numRows():uint
    {
      return Math.floor(this.bounds.height / this.tileHeight);
    }
    
    public function get numCols():uint
    {
      return Math.floor(this.bounds.width / this.tileWidth);
    }
    
    // This is actually part of initialization.
    public function generateData():void
    {
      var rows:uint = this.numRows;
      var cols:uint = this.numCols;
      // Smarts of our algo.
      var cStart:uint, cEnd:uint, facing:uint, pFacing:uint, 
          rSize:uint, rSpacing:uint, sizeRange:uint, spacingRange:uint, 
          inverse:Boolean, rClearance:uint, rStart:uint, rEnd:uint, 
          rType:uint, ledge:PlatformLedge, dir:uint;
      // Grunts of our algo.
      var r:int, // Absolute row index.
          rL:int, // Ledge row index.
          c:int, // Column index.
          l:int, // Ledge layer index.
          col:Array;
      // Subroutines.
      var addRow:Function, setupEmptyRow:Function, setupFloorRow:Function,
          setupLedgeRow:Function, setupEachRow:Function;

      mapData = '';
      sizeRange = (this.maxLedgeSize - this.minLedgeSize);
      spacingRange = (this.maxLedgeSpacing.y - this.minLedgeSpacing.y);
      rClearance = this.minLedgeSpacing.y + this.ledgeThickness;
      facing = FlxObject.RIGHT;
      rStart = rows-1;
      rEnd = 0;
      dir = BOTTOM_TOP;
      // Estimate the ledge row count.
      this.ledgeRowCount = rows /
        ((this.maxLedgeSpacing.y + this.minLedgeSpacing.y) / 2 +
          (this.ledgeThickness - 1));
//      FlxG.log('Ledge row count: '+this.ledgeRowCount);
      // Plot the row, given the type. 
      addRow = function():void
      {
        if (rType == LEDGE_ROW && this.delegate != null)
        {
          // Pack.
          ledge = new PlatformLedge();
          ledge.index = rL;
          ledge.rowIndex = (dir == TOP_BOTTOM) ? r : rStart - r;
          ledge.size = rSize;
          ledge.spacing = rSpacing;
          ledge.start = cStart;
          ledge.end = cEnd;
          ledge.facing = pFacing;
          // Transform.
          ledge = delegate.platformWillSetupLedgeRow(ledge);
          // Save.
          this.ledges.push(ledge);
          // Unpack.
          cStart = ledge.start;
          cEnd = ledge.end;
        }
        if (col.length == 0)
        {
          for (c = 0; c < cStart; c++) // For each column.
          {
            col.push(inverse ? SOLID_TILE : EMPTY_TILE);
          }
          for (c = cStart; c < cEnd; c++)
          {
            col.push(!inverse ? SOLID_TILE : EMPTY_TILE);
          }
          for (c = cEnd; c < cols; c++)
          {
            col.push(inverse ? SOLID_TILE : EMPTY_TILE);
          }
        }
        mapData = col.join(',')+"\n" + mapData;
      };
      // Prepare for emply plot.
      setupEmptyRow = function():void
      {
        cStart = 0;
        cEnd = 0;
        rType = EMPTY_ROW;
      };
      // Prepare for full plot.
      setupFloorRow = function():void
      {
        col = [];
        cStart = 0;
        cEnd = cols;
        rSpacing = 0;
        rType = SOLID_ROW;
      };
      // Prepare for partial plot. This just does a simple random, anything
      // more complicated is delegated.
      setupLedgeRow = function():void
      {
        rL++;
        rSize = this.minLedgeSize + uint(Math.random() * sizeRange);
        pFacing = facing;
        if (facing == FlxObject.LEFT)
        {
          cStart = 0;
          cEnd = rSize;
          // Prepare for next ledge.
          facing = FlxObject.RIGHT;
        }
        else if (facing == FlxObject.RIGHT)
        {
          cStart = cols - rSize;
          cEnd = cols;
          // Prepare for next ledge.
          facing = FlxObject.LEFT;
        }
        rType = LEDGE_ROW;
        // Prepare for next ledge.
        rSpacing = this.minLedgeSpacing.y + int(Math.random() * spacingRange);
      };
      // Reset on each row.
      setupEachRow = function():void
      {
        inverse = false;
        if (l == 0) {
          col = [];
        }
      };
      for ( // For each row.
        r = rStart;
        (dir == TOP_BOTTOM && r < rEnd) || (dir == BOTTOM_TOP && r >= rEnd);
        (dir == TOP_BOTTOM) ? r++ : r--
      ) 
      {
        if (r == rStart && this.hasFloor)
        {
          setupFloorRow.call(this);
          rSpacing = this.minLedgeSpacing.y;
        }
        else
        {
          setupEachRow.call(this);
          if (
            (dir == TOP_BOTTOM && r+rClearance >= rEnd) ||
            (dir == BOTTOM_TOP && r-rClearance <= rEnd) 
          )
          {
            setupEmptyRow.call(this);
            if (l > 0)
            {
              l--;
              // TODO - Temp fix.
              PlatformLedge(this.ledges[this.ledges.length-1]).rowIndex =
                (dir == TOP_BOTTOM) ? r : rStart - r;
//              FlxG.log('Finishing up last row...');
            }
            else
            {
              col = [];
            }
          }
          else
          {
            if (rSpacing == 0)
            {
              setupLedgeRow.call(this);
              l = this.ledgeThickness-1;
            }
            else if (l > 0)
            {
              l--;
            }
            else
            {
              setupEmptyRow.call(this);
              rSpacing--;
              l = 0;
            }
          }
        }
        addRow.call(this);
      }
//      FlxG.log('Ledges: '+rL);
//      FlxG.log('Map: '+this.mapData);

    }

    public function makeMap(tileGraphic:Class):FlxTilemap
    {
      if (mapData == null)
      {
        this.generateData();
      }

      return super.loadMap(
        mapData,
        tileGraphic,
        this.tileWidth, this.tileHeight,
        this.tilingMode
      );
    }

    public function isAtEndingPoint(obj:FlxObject):Boolean
    {
      var test:Boolean;
      // Bottom-to-top.
      if (this.endingPoint.y < this.startingPoint.y)
      {
        test = obj.y <= this.endingPoint.y;
      }
      // Top-to-bottom.
      else
      {
        test = obj.y >= this.endingPoint.y;
      }
      return test;
    }
  }
}
```
