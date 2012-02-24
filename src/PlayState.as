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
    
    // Box to show the user where they're placing stuff
    private var highlightBox:FlxObject;
    
    // Player modified from "Mode" demo
    private var player:FlxSprite;
    
    private var camera:FlxCamera;
    
    // Some interface buttons and text
    private var autoAltBtn:FlxButton;
    private var resetBtn:FlxButton;
    private var quitBtn:FlxButton;
    private var helperTxt:FlxText;
    
    override public function create():void
    {
      FlxG.framerate = 50;
      FlxG.flashFramerate = 50;
      
      // Creates a new tilemap with no arguments
      collisionMap = new FlxTilemap();
      
      /*
      * FlxTilemaps are created using strings of comma seperated values (csv)
      * This string ends up looking something like this:
      *
      * 0,0,0,0,0,0,0,0,0,0,
      * 0,0,0,0,0,0,0,0,0,0,
      * 0,0,0,0,0,0,1,1,1,0,
      * 0,0,1,1,1,0,0,0,0,0,
      * ...
      *
      * Each '0' stands for an empty tile, and each '1' stands for
      * a solid tile
      *
      * When using the auto map generation, the '1's are converted into the corresponding frame
      * in the tileset.
      */
      
      // Initializes the map using the generated string, the tile images, and the tile size
      collisionMap.loadMap(new default_auto(), auto_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.AUTO);
      add(collisionMap);
      
      highlightBox = new FlxObject(0, 0, TILE_WIDTH, TILE_HEIGHT);
      
      setupPlayer();
      setupPanning();
      
      // When switching between modes here, the map is reloaded with it's own data, so the positions of tiles are kept the same
      // Notice that different tilesets are used when the auto mode is switched
      autoAltBtn = new FlxButton(4, FlxG.height - 24, "AUTO", function():void
      {
        switch (collisionMap.auto)
        {
          case FlxTilemap.AUTO:
            collisionMap.loadMap(FlxTilemap.arrayToCSV(collisionMap.getData(true), collisionMap.widthInTiles),
              alt_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.ALT);
            autoAltBtn.label.text = "ALT";
            break;
          
          case FlxTilemap.ALT:
            collisionMap.loadMap(FlxTilemap.arrayToCSV(collisionMap.getData(true), collisionMap.widthInTiles),
              empty_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.OFF);
            autoAltBtn.label.text = "OFF";
            break;
          
          case FlxTilemap.OFF:
            collisionMap.loadMap(FlxTilemap.arrayToCSV(collisionMap.getData(true), collisionMap.widthInTiles),
              auto_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.AUTO);
            autoAltBtn.label.text = "AUTO";
            break;
        }
        
      });
//      add(autoAltBtn);
      
      resetBtn = new FlxButton(8 + autoAltBtn.width, FlxG.height - 24, "Reset", function():void
      {
        switch(collisionMap.auto)
        {
          case FlxTilemap.AUTO:
            collisionMap.loadMap(new default_auto(), auto_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.AUTO);
            player.x = 64;
            player.y = 220;
            break;
          
          case FlxTilemap.ALT:
            collisionMap.loadMap(new default_alt(), alt_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.ALT);
            player.x = 64;
            player.y = 128;
            break;
          
          case FlxTilemap.OFF:
            collisionMap.loadMap(new default_empty(), empty_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.OFF);
            player.x = 64;
            player.y = 64;
            break;
        }
      });
//      add(resetBtn);
      
      quitBtn = new FlxButton(FlxG.width - resetBtn.width - 4, FlxG.height - 24, "Quit",
        function():void { FlxG.fade(0xff000000, 0.22, function():void { FlxG.switchState(new MenuState()); } ); } );
//      add(quitBtn);
      
      helperTxt = new FlxText(12 + autoAltBtn.width*2, FlxG.height - 30, 150, "Click to place tiles\nShift-Click to remove tiles\nArrow keys to move");
//      add(helperTxt);
    }
    
    override public function update():void
    {
      // Tilemaps can be collided just like any other FlxObject, and flixel
      // automatically collides each individual tile with the object.
      FlxG.collide(player, collisionMap);
      
      highlightBox.x = Math.floor(FlxG.mouse.x / TILE_WIDTH) * TILE_WIDTH;
      highlightBox.y = Math.floor(FlxG.mouse.y / TILE_HEIGHT) * TILE_HEIGHT;
      
      if (FlxG.mouse.pressed())
      {
        // FlxTilemaps can be manually edited at runtime as well.
        // Setting a tile to 0 removes it, and setting it to anything else will place a tile.
        // If auto map is on, the map will automatically update all surrounding tiles.
        collisionMap.setTile(FlxG.mouse.x / TILE_WIDTH, FlxG.mouse.y / TILE_HEIGHT, FlxG.keys.SHIFT?0:1);
      }
      
      updatePlayer();
      super.update();
    }
    
    public override function draw():void
    {
      super.draw();
      highlightBox.drawDebug();
    }
    
    private function setupPlayer():void
    {
      player = new FlxSprite(FlxG.width/2, FlxG.height/2);
      player.loadGraphic(ImgSpaceman, true, true, 16);
      
      //bounding box tweaks
      player.width = 14;
      player.height = 14;
      player.offset.x = 1;
      player.offset.y = 1;
      
      //basic player physics
      player.drag.x = 640;
      player.acceleration.y = 420;
      player.maxVelocity.x = 80;
      player.maxVelocity.y = 200;
      
      //animations
      player.addAnimation("idle", [0]);
      player.addAnimation("run", [1, 2, 3, 0], 12);
      player.addAnimation("jump", [4]);
      
      add(player);
    }
    
    private function updatePlayer():void
    {
      wrap(player);
      
      //MOVEMENT
      player.acceleration.x = 0;
      if (FlxG.keys.LEFT)
      {
        player.facing = FlxObject.LEFT;
        player.acceleration.x -= player.drag.x;
      }
      else if (FlxG.keys.RIGHT)
      {
        player.facing = FlxObject.RIGHT;
        player.acceleration.x += player.drag.x;
      }
      if (FlxG.keys.justPressed("UP") && player.velocity.y == 0)
      {
        player.y -= 1;
        player.velocity.y = -200;
      }
      
      //ANIMATION
      if (player.velocity.y != 0)
      {
        player.play("jump");
      }
      else if (player.velocity.x == 0)
      {
        player.play("idle");
      }
      else
      {
        player.play("run");
      }
      
      //FlxG.camera.shake();
      
    }
    
    private function setupPanning():void
    {
      FlxG.camera.follow(player);
      collisionMap.follow();
    }
    
    private function wrap(obj:FlxObject):void
    {
      obj.x = Math.min(Math.max(obj.x, 0), (collisionMap.width - obj.width));
    }
  }
}
