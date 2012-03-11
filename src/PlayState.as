package
{
  import flash.display.BlendMode;
  
  import org.flixel.*;
  
  // The main coordinator: part config list, part asset list. 
  // Handles all of the character animations.
  
  public class PlayState extends FlxState implements IPlayerAnimationDelegate
  {
    // Tileset that works with AUTO mode (best for thin walls)
    [Embed(source='data/auto_tiles.png')]private static var ImgAutoTiles:Class;
    // Tileset that works with OFF mode (do what you want mode)
    [Embed(source='data/empty_tiles.png')]private static var ImgCustomTiles:Class;
    
    [Embed(source='data/player.png')]private static var ImgPlayer:Class;
    
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
    
    // The dynamically generated and extended FlxTilemap.
    private var platform:Platform;
    // Ledge controls, in tiles.
    
    // The extend FlxSprite.
    private static const PLAYER_WIDTH:uint = 72;
    private static const PLAYER_HEIGHT:uint = 72;
    private var player:Player;
    
    // The background with parallax.
    private var bg:Background;
    
    // Some game switches.
    private var fallChecking:Boolean;
    
    // Internal helpers.
    private var gameStatePollInterval:FlxTimer;
    
    // Flixel Methods
    // --------------
    override public function create():void
    {
      FlxG.mouse.hide();
      
      // Globals.
      FlxG.framerate = 30;
      FlxG.flashFramerate = 30;
      fallChecking = false;
      
      // Start our setup chain.
      setupPlatform();
      setupPlatformAfter();
      setupPlatformAndPlayerAfter();
      
      // For now, we add things in order to get correct layering.
      add(bg);
      add(platform);
      add(player);
      
      // Internals.
      // Don't do expensive operations too often, if possible.
      gameStatePollInterval = new FlxTimer();
      gameStatePollInterval.start(2, Number.POSITIVE_INFINITY,
        function(onTimer:FlxTimer):void {
          updateGameState(true);
        }
      );
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
        
      // Customize our tile generation.
      platform.tileWidth = 32;
      platform.tileHeight = 32;
      platform.minLedgeSize = 3;
      platform.maxLedgeSize = 6;
      platform.minLedgeSpacing = new FlxPoint(4, 2);
      platform.maxLedgeSpacing = new FlxPoint(8, 4);
      platform.ledgeThickness = 2;
      
      // Set the bounds based on the background.
      platform.bounds = new FlxRect(bg.bounds.x, bg.bounds.y, bg.bounds.width, bg.bounds.height);
      
      // Make our platform.
      platform.makeMap(ImgAutoTiles);
      
      // Set points.
      var floorHeight:Number = PLAYER_HEIGHT;
      platform.startingPoint.x = (FlxG.width - PLAYER_HEIGHT) / 2;
      platform.startingPoint.y = platform.height - (PLAYER_HEIGHT + floorHeight);
      platform.endingPoint.y = (platform.maxLedgeSpacing.y + 1) * platform.tileHeight - PLAYER_HEIGHT
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
    }
    private function setupPlatformAndPlayerAfter():void
    {
      setupCamera();
    }
    // Hooked routines.
    private function setupPlayer(start:FlxPoint):void
    {
      // Find start position for player.
      
      player = new Player(start.x, start.y);
      player.loadGraphic(ImgPlayer, true, true, 72);
      
      // Bounding box tweaks.
      player.height = player.frameWidth / 2;
      player.offset.y = player.frameWidth - player.height;
      player.tailOffset.x = 35;
      player.headOffset.x = 10;
      player.width = player.frameWidth - player.tailOffset.x;
      player.face(FlxObject.RIGHT);
      
      // Basic player physics.
      player.naturalForces.x = 1000; // friction
      player.naturalForces.y = 500; // gravity
      player.maxVelocity.x = 150;
      player.maxVelocity.y = 1500;
      
      // Player jump physics.
      player.jumpMaxVelocity.y = -250;
      player.jumpAccel.y = -0.3;
      
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
      player.animDelegate = this;
      
      // Process settings.
      player.init();
    }
    private function setupCamera():void
    {
      FlxG.camera.follow(player);
      platform.follow();
    }
    private function setupBg():void
    {
      // Load our scenery.
      bg = new Background();
      bg.bounds.x = 0;
      bg.bounds.y = 0;
      bg.parallax_factor = 1; // Our bg is part "foreground".
      bg.parallax_buffer = 1.7;
      
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
    }
    private function updatePlatformAndPlayerAfter():void
    {
      updateCamera(player.justFell());
      updateGameState();
    }
    // Hooked routines.
    private function updatePlayer():void
    {
      // Tilemaps can be collided just like any other FlxObject, and flixel
      // automatically collides each individual tile with the object.
      FlxG.collide(player, platform);
      // Wrap to stage.
      if (!player.inMidAir() && player.nextAction != Player.STOP)
      {
        var pPos:FlxPoint = new FlxPoint(player.x, player.y);
        wrapToStage(player);
        var pos:FlxPoint = new FlxPoint(player.x, player.y);
        if (FlxU.getDistance(pos, pPos) > 0)
        {
          player.nextAction = Player.STOP;
        }
      }
      else
      {
        wrapToStage(player);
      }
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
    private function updateGameState(doChecks:Boolean=false):void
    {
      if (doChecks)
      {
        // Check if player is on top of last platform, periodically.
        // Play the end screen for a while, on click, switch to start screen.
        if (player.isTouching(FlxObject.FLOOR) && platform.isAtEndingPoint(player))
        {
          if (player.controlled)
          {
            player.controlled = false;
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
          }
          else if (!player.controlled && FlxG.mouse.justPressed())
          {
            MorningStroll.endGame();
          }
        }
      }
      if (FlxG.keys.justPressed('Q'))
      {
        MorningStroll.endGame();
      }
    }
    
    // Delegate Methods
    // ----------------
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
    }
    
    // Helpers
    // -------
    private function wrapToStage(obj:FlxSprite):void
    {
      obj.x = FlxU.bound(obj.x, 0, (platform.width - obj.width));
      obj.y = FlxU.bound(obj.y, 0, (platform.height - obj.height));
    }
  }
}
