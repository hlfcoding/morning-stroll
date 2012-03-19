package
{
  import flash.display.BlendMode;
  
  import org.flixel.*;

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

    [Embed(source='data/player.png')]private static var ImgPlayer:Class;
    [Embed(source='data/mate.png')]private static var ImgMate:Class;

    [Embed(source="data/morning-stroll.mp3")]private static var SndMain:Class;
    
    // From farthest to closest.
    [Embed(source='data/bg-1.png')]private static var ImgBg1:Class;
    [Embed(source='data/bg-2.png')]private static var ImgBg2:Class;
    [Embed(source='data/bg-3.png')]private static var ImgBg3:Class;
    [Embed(source='data/bg-4.png')]private static var ImgBg4:Class;
    [Embed(source='data/bg-5.png')]private static var ImgBg5:Class;
    [Embed(source='data/bg-6.png')]private static var ImgBg6:Class;
    [Embed(source='data/bg-7.png')]private static var ImgBg7:Class;
    [Embed(source='data/bg-8.png')]private static var ImgBg8:Class;
    [Embed(source='data/bg-9.png')]private static var ImgBg9:Class;
    [Embed(source='data/bg-10.png')]private static var ImgBg10:Class;
    [Embed(source='data/bg-11.png')]private static var ImgBg11:Class;
    [Embed(source='data/bg-12.png')]private static var ImgBg12:Class;
    [Embed(source='data/bg-13.png')]private static var ImgBg13:Class;
    [Embed(source='data/bg-14.png')]private static var ImgBg14:Class;
    [Embed(source='data/bg-15.png')]private static var ImgBg15:Class;
    [Embed(source='data/bg-16.png')]private static var ImgBg16:Class;

    // The dynamically generated and extended FlxTilemap.
    private var platform:Platform;
    private static const FLOOR_HEIGHT:uint = 32;
    
    // The extend FlxSprite.
    private static const PLAYER_WIDTH:uint = 72;
    private static const PLAYER_HEIGHT:uint = 72;
    private var player:Player;
    private var mate:FlxSprite;

    // The background with parallax.
    private var bg:Background;
    
    // Some game switches.
    private var fallChecking:Boolean;

    // Internal helpers.
    private var gameStatePollInterval:FlxTimer;
    private var didTheEnd:Boolean;
    private var endAnimDuration:Number;

    // Flixel Methods
    // --------------
    override public function create():void
    {
      FlxG.mouse.hide();

      // Globals.
      FlxG.framerate = 30;
      FlxG.flashFramerate = 30;
      fallChecking = false;
      FlxG.debug = true;

      // Start our setup chain.
      setupPlatform();
      setupPlatformAfter();
      setupPlatformAndPlayerAfter();

      // For now, we add things in order to get correct layering.
      add(bg);
      add(platform);
      add(mate);
      add(player);

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
      setupBg();
      
      // Creates a new tilemap with no arguments.
      platform = new Platform();

      // Hook into delegated methods.
      platform.delegate = this;
      
      // Customize our tile generation.
      // Vertical ledge spacing and horizontal ledge size affect difficulty.
      platform.tileWidth = 32;
      platform.tileHeight = 32;
      platform.minLedgeSize = 3;
      platform.maxLedgeSize = 5;
      platform.minLedgeSpacing = new FlxPoint(4, 2);
      platform.maxLedgeSpacing = new FlxPoint(8, 4);
      platform.ledgeThickness = 2;

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
      
      FlxG.log('Ending point: '+[platform.numRows-1 - ledge.rowIndex, platform.endingPoint.x, platform.endingPoint.y]);
    }
    // Hooks.
    private function setupPlatformAfter():void
    {
      // Draw player at the bottom.
      setupPlayer(platform.startingPoint);
//      setupPlayer(platform.endingPoint);

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
      player = new Player(0, 0);
      player.loadGraphic(ImgPlayer, true, true, 72);

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
      player.addAnimation('run',  [0,1,2,3,4,5,6,7,8,9,10,11], 24);
      player.addAnimation('stop', [12,13,14,15,16,17], 24, false);
      player.addAnimation('start',[17,16,15,14,13,12], 24, false);
      player.addAnimation('jump', [18,19,20,21,22,23,24,25,26,27,28,29,30,31], 24, false);
      player.addAnimation('fall', [31]);
      player.addAnimation('land', [32,33,18,17], 12, false);
      var endFrames:Array = [34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53];
      var endFramerate:Number = 12;
      endAnimDuration = endFrames.length / endFramerate;
      player.addAnimation('end', endFrames, endFramerate, false);
      player.animDelegate = this;

      // Process settings.
      player.init();
    }
    private function setupMate(start:FlxPoint):void
    {
      mate = new FlxSprite(start.x, start.y);
      mate.loadGraphic(ImgMate, true, true, PLAYER_WIDTH);
      
      mate.height = 46;
      mate.offset.y = mate.frameHeight - mate.height;
      mate.y -= mate.frameHeight - mate.height - 6; // TODO - Magic pixel hack.
      mate.x -= 20;
      
      mate.addAnimation('end', [1,4,5,6,7,8,9,10,11,12,13,14], 12, false);
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
      if (!FlxG.debug)
      {
        FlxG.playMusic(SndMain);
      }
    }
    private function setupBg():void
    {
      // Load our scenery.
      bg = new Background();
      bg.bounds.x = 0;
      bg.bounds.y = 0;
      bg.parallaxFactor = 0.95; // Our first bg is more "foreground".
      bg.parallaxBuffer = 1.7;
      bg.parallaxTolerance = -64;

      // This is the lamest image loading ever.
      bg.addImage(ImgBg1);
      bg.addImage(ImgBg2);
      bg.addImage(ImgBg3);
      bg.addImage(ImgBg4);
      bg.addImage(ImgBg5);
      bg.addImage(ImgBg6);
      bg.addImage(ImgBg7);
      bg.addImage(ImgBg8);
      bg.addImage(ImgBg9);
      bg.addImage(ImgBg10);
      bg.addImage(ImgBg11);
      bg.addImage(ImgBg12);
      bg.addImage(ImgBg13);
      bg.addImage(ImgBg14);
      bg.addImage(ImgBg15);
      bg.addImage(ImgBg16);

      bg.layout();
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
    private function updateAudio():void
    {
      
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
        MorningStroll.endGame();
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
      
      FlxG.log('Before: '+[facing, ledge.spacing, ledge.size]);
      
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
      
      FlxG.log('After: '+[facing, ledge.spacing, ledge.size, factor]);
      
      return ledge;
    }
    
    // Player Delegate Methods
    // -----------------------
    public function playerWillUpdateAnimation():void {}
    public function playerDidUpdateAnimation():void {}
    // Smooth, once.
    public function playerWillStart():void
    {
      if (!player.finished) return;
      if (player.currentAnimation().name == 'start') return;
      player.play('start');
    }
    // Interruptive, once.
    public function playerWillStop():void
    {
      if (player.currentAnimation().name == 'stop') return;
      player.play('stop');
    }
    // Interruptive, once.
    public function playerWillJump():void
    {
      if (player.currentAnimation().name == 'jump') return;
      player.play('jump');
      player.updateFocus = false;
    }
    // Smooth.
    public function playerIsStill():void
    {
      if (!player.finished) return;
      player.play('still');
    }
    // Smooth.
    public function playerIsRunning():void
    {
      if (!player.finished) return;
      player.play('run');
    }
    // Smooth, once.
    public function playerIsLanding():void
    {
      if (!player.finished) return;
      if (player.currentAnimation().name == 'land') return;
      player.play('land');
    }
    public function playerIsRising():void {}
    // Smooth.
    public function playerIsFalling():void
    {
      if (!player.finished) return;
      player.play('fall');
      player.updateFocus = true;
    }

  }
}
