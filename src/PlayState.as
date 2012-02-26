package
{
  import flash.display.BlendMode;
  
  import org.flixel.*;
  import org.flixel.FlxPoint;
  
  public class PlayState extends FlxState
  {
    // Tileset that works with AUTO mode (best for thin walls)
    [Embed(source = 'auto_tiles.png')]private static var auto_tiles:Class;
    
    // Tileset that works with ALT mode (best for thicker walls)
    [Embed(source = 'alt_tiles.png')]private static var alt_tiles:Class;
    
    // Tileset that works with OFF mode (do what you want mode)
    [Embed(source = 'empty_tiles.png')]private static var empty_tiles:Class;
    
    // Default tilemaps. Embedding text files is a little weird.
    [Embed(source = 'default_auto.txt', mimeType = 'application/octet-stream')]private static var default_auto:Class;
    [Embed(source = 'default_alt.txt', mimeType = 'application/octet-stream')]private static var default_alt:Class;
    [Embed(source = 'default_empty.txt', mimeType = 'application/octet-stream')]private static var default_empty:Class;
    
    [Embed(source="player.png")] private static var ImgPlayer:Class;
    
    [Embed(source="background.jpg")] private static var ImgBg:Class;
    
    // Some static constants for the size of the tilemap tiles
    private const TILE_WIDTH:uint = 16;
    private const TILE_HEIGHT:uint = 16;
    private const PLAYER_WIDTH:uint = 16;
    private const PLAYER_HEIGHT:uint = 16;
    
    // The FlxTilemap we're using
    private var collisionMap:FlxTilemap;
    
    // Player modified from "Mode" demo
    private var player:Player;
    
    private var bg:FlxSprite;
    
    private var fallChecking:Boolean;
    
    
    // Flixel Methods
    // --------------
    override public function create():void
    {
      // Globals.
      FlxG.framerate = 50;
      FlxG.flashFramerate = 50;
      fallChecking = false;
      
      // Start our setup chain.
      setupPlatform();
      
      // For now, we add things in order to get correct layering.
      // TODO - offload to draw method?
      add(bg);
      add(collisionMap);
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
      // Creates a new tilemap with no arguments.
      collisionMap = new FlxTilemap();
      // Initializes the map using the generated string, the tile images, and the tile size.
      collisionMap.loadMap(new default_auto(), auto_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.AUTO);

      bg = new FlxSprite(0, 0);
      bg.loadGraphic(ImgBg);

      setupPlatformAfter();
    }
    // Hooks.
    private function setupPlatformAfter():void
    {
      // Draw player at the bottom.
      var start:FlxPoint = new FlxPoint();
      var floorHeight:Number = PLAYER_HEIGHT;
      start.x = (FlxG.width - PLAYER_HEIGHT) / 2;
      start.y = collisionMap.height - (PLAYER_HEIGHT + floorHeight);
      setupPlayer(start);
      
      // Move until we don't overlap.
      while (collisionMap.overlaps(player)) {
        if (player.x <= 0) {
          player.x = FlxG.width;
        }
        player.x -= TILE_WIDTH;
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
      player.loadGraphic(ImgPlayer, true, true, 16);
      
      // Bounding box tweaks.
      player.width = 14;
      player.height = 14;
      player.offset.x = 1;
      player.offset.y = 1;
      
      // Basic player physics.
      player.drag.x = 640; // friction?
      player.acceleration.y = 420; // gravity
      player.maxVelocity.x = 80;
      player.maxVelocity.y = 200;
      
      // Animations.
      player.addAnimation('idle', [0]);
      player.addAnimation('run', [1, 2, 3, 0], 12);
      player.addAnimation('jump', [4]);
    }
    private function setupCamera():void
    {
      FlxG.camera.follow(player);
      collisionMap.follow();
    }
    
    // Update Routines
    // ---------------
    private function updatePlatform():void
    {
      updatePlatformAfter();
    }
    private function updatePlatformAfter():void
    {
      // Tilemaps can be collided just like any other FlxObject, and flixel
      // automatically collides each individual tile with the object.
      FlxG.collide(player, collisionMap);
      
      wrapToStage(player);
      updatePlayer();
      
      updatePlatformAndPlayerAfter();
    }
    private function updatePlatformAndPlayerAfter():void
    {
      updateCamera(player.justFell());
    }
    private function updatePlayer():void
    {
      player.moveWithInput();
      
      if (player.velocity.y != 0)
      {
        player.play('jump');
      }
      else if (player.velocity.x == 0)
      {
        player.play('idle');
      }
      else
      {
        player.play('run');
      }
    }
    private function updateCamera(playerJustFell:Boolean):void
    {
      if (fallChecking && playerJustFell) {
        FlxG.camera.shake(
          0.01,
          0.1, null, true, 
          FlxCamera.SHAKE_VERTICAL_ONLY
        );
      }
    }
    
    // Helpers
    // -------
    private function wrapToStage(obj:FlxObject):void
    {
      obj.x = Math.min(Math.max(obj.x, 0), (collisionMap.width - obj.width));
    }
  }
}
