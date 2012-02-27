package
{
  import flash.display.BlendMode;
  
  import org.flixel.*;
  
  public class PlayState extends FlxState
  {
    // Tileset that works with AUTO mode (best for thin walls)
    [Embed(source='auto_tiles.png')]private static var auto_tiles:Class;
    // Tileset that works with ALT mode (best for thicker walls)
    [Embed(source='alt_tiles.png')]private static var alt_tiles:Class;
    // Tileset that works with OFF mode (do what you want mode)
    [Embed(source='empty_tiles.png')]private static var empty_tiles:Class;
    
    [Embed(source='player.png')]private static var ImgPlayer:Class;
    
    [Embed(source='background.jpg')]private static var ImgBg:Class;
    
    // The dynamically generated and extended FlxTilemap.
    private var platform:Platform;
    // Ledge controls, in tiles.
    
    // The extend FlxSprite.
    private const PLAYER_WIDTH:uint = 72;
    private const PLAYER_HEIGHT:uint = 72;
    private var player:Player;
    
    // The background with parallax.
    private var bg:FlxSprite;
    
    // Some game switches.
    private var fallChecking:Boolean;
    
    // Flixel Methods
    // --------------
    override public function create():void
    {
      // Globals.
      FlxG.framerate = 30;
      FlxG.flashFramerate = 30;
      fallChecking = false;
      
      // Start our setup chain.
      setupPlatform();
      
      // For now, we add things in order to get correct layering.
      // TODO - offload to draw method?
      add(bg);
      add(platform);
      add(player);      
    }
    override public function update():void
    {
      // Start our update chain.
      updatePlatform();
      
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
      // Load our scenery.
      bg = new FlxSprite(0, 0);
      bg.loadGraphic(ImgBg);
      
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
      // TODO - Account for parallax.
      platform.bounds = new FlxRect(bg.x, bg.y, bg.frameWidth, bg.frameHeight);
      
      // Make our platform.
      platform.makeMap(auto_tiles);
      
      setupPlatformAfter();
    }
    // Hooks.
    private function setupPlatformAfter():void
    {
      // Draw player at the bottom.
      var start:FlxPoint = new FlxPoint();
      var floorHeight:Number = PLAYER_HEIGHT;
      start.x = (FlxG.width - PLAYER_HEIGHT) / 2;
      start.y = platform.height - (PLAYER_HEIGHT + floorHeight);
//      start.x = 0;
//      start.y = 0;
      setupPlayer(start);
      
      // Move until we don't overlap.
      while (platform.overlaps(player)) 
      {
        if (player.x <= 0) 
        {
          player.x = FlxG.width;
        }
        player.x -= platform.tileWidth;
      }
      
      setupPlatformAndPlayerAfter();
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
      player.drag.x = 1000; // friction
      player.acceleration.y = 500; // gravity
      player.maxVelocity.x = 200;
      player.maxVelocity.y = 1500;
      
      // Player jump physics.
      player.jumpVelocity.y = -420;
      
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
    }
    private function setupCamera():void
    {
      FlxG.camera.follow(player);
      platform.follow();
    }
    
    // Update Routines
    // ---------------
    private function updatePlatform():void
    {
      updatePlatformAfter();
    }
    // Hooks.
    private function updatePlatformAfter():void
    {
      // Tilemaps can be collided just like any other FlxObject, and flixel
      // automatically collides each individual tile with the object.
      FlxG.collide(player, platform);
      
      wrapToStage(player);
      updatePlayer();
      
      updatePlatformAndPlayerAfter();
    }
    private function updatePlatformAndPlayerAfter():void
    {
      updateCamera(player.justFell());
    }
    // Hooked routines.
    private function updatePlayer():void
    {
      player.moveWithInput();
      
      if (player.willJump) // We only need to play the jump animation once.
      {
        player.play('jump');
      }
      else if (player.justFell()) 
      {
        player.play('land');
      }
      else if (!player.rising && player.finished) 
      {
        if (player.falling)
        {
          player.play('fall');
        }
        else if (player.willStop) 
        {
          player.play('stop');
        }
        else if (player.velocity.x == 0 || 
          (player.x == 0 || player.x >= (platform.width - player.width))
        )
        {
          player.play('still');
        }
        else if (player.willStart)
        {
          player.play('start');
          player.willStart = false; // TODO - Hack.
        }
        else
        {
          player.play('run');
        }
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
    
    // Helpers
    // -------
    private function wrapToStage(obj:FlxSprite):void
    {
      obj.x = FlxU.bound(obj.x, 0, (platform.width - obj.width));
      obj.y = FlxU.bound(obj.y, 0, (platform.height - obj.height));
    }
  }
}
