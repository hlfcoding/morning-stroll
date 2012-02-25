package
{
  import flash.display.BlendMode;
  
  import org.flixel.*;
  
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
    
    [Embed(source="spaceman.png")] private static var ImgSpaceman:Class;
    
    // Some static constants for the size of the tilemap tiles
    private const TILE_WIDTH:uint = 16;
    private const TILE_HEIGHT:uint = 16;
    
    // The FlxTilemap we're using
    private var collisionMap:FlxTilemap;
    
    // Player modified from "Mode" demo
    private var player:Player;
    
    private var fallChecking:Boolean;
    
    
    // Flixel Methods
    // --------------
    override public function create():void
    {
      // Globals.
      FlxG.framerate = 50;
      FlxG.flashFramerate = 50;
      fallChecking = false;
      
      // Creates a new tilemap with no arguments.
      collisionMap = new FlxTilemap();
      
      // Initializes the map using the generated string, the tile images, and the tile size.
      collisionMap.loadMap(new default_auto(), auto_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.AUTO);
      add(collisionMap);
      
      setupPlayer();
      setupPanning();
    }
    override public function update():void
    {
      // Tilemaps can be collided just like any other FlxObject, and flixel
      // automatically collides each individual tile with the object.
      FlxG.collide(player, collisionMap);
      
      updateCamera(updatePlayer());
      
      super.update();
    }
    override public function draw():void
    {
      super.draw();
    }
    
    // Setup Routines
    // --------------
    private function setupPlayer():void
    {
      player = new Player(FlxG.width/2, FlxG.height/2);
      player.loadGraphic(ImgSpaceman, true, true, 16);
      
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
      
      add(player);
    }
    private function setupPanning():void
    {
      FlxG.camera.follow(player);
      collisionMap.follow();
    }
    
    // Update Routines
    // ---------------
    private function updatePlayer():Array
    {
      wrapToStage(player);
      
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
      
      var results:Array = new Array();
      results['justFell'] = player.justFell();
      
      return results;
    }
    private function updateCamera(updateResults:Array):void
    {
      if (fallChecking && updateResults['justFell']) {
        player.rising = false;
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
