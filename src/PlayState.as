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
    
    [Embed(source="player.png")] private static var ImgPlayer:Class;
    
    [Embed(source="background.jpg")] private static var ImgBg:Class;
    
    // Some static constants for the size of the tilemap tiles
    private const TILE_WIDTH:uint = 24;
    private const TILE_HEIGHT:uint = 24;
    private const PLAYER_WIDTH:uint = 72;
    private const PLAYER_HEIGHT:uint = 72;
    
    // The dynamically generated FlxTilemap we're using.
    private var collisionMap:FlxTilemap;
    // Ledge controls, in tiles.
    private var minLedgeSize:uint = 3;
    private var maxLedgeSize:uint = 6;
    private var minLedgeSpacing:FlxPoint = new FlxPoint(4, 2);
    private var maxLedgeSpacing:FlxPoint = new FlxPoint(8, 4);
    
    // Instance of custom player class.
    private var player:Player;
    private var fallChecking:Boolean;
    
    private var bg:FlxSprite;
    
    // Flixel Methods
    // --------------
    override public function create():void
    {
      // Globals.
      FlxG.framerate = 50;
      FlxG.flashFramerate = 50;
      fallChecking = true;
      
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
      // Load our scenery.
      bg = new FlxSprite(0, 0);
      bg.loadGraphic(ImgBg);
      
      // Generate our map string.
      var mapData:String = '';
      var rows:int = Math.round(Math.round(bg.height / TILE_HEIGHT)) ;
      var cols:int = Math.round(Math.round(bg.width / TILE_WIDTH));
      // Smarts of our algo.
      var cStart:uint, cEnd:uint, facing:uint, rSize:int, rSpacing:int, sizeRange:uint, spacingRange:uint; 
      // Grunts of our algo.
      var r:int, c:int, col:Array;
      sizeRange = (maxLedgeSize - minLedgeSize);
      spacingRange = (maxLedgeSpacing.y - minLedgeSpacing.y);
      facing = FlxObject.RIGHT;
      for (r = 0; r < rows; r++) {
        col = [];
        if (r >= rows - minLedgeSpacing.y) {
          cStart = 0;
          cEnd = 0;
        }
        if (r == rows-1) {
          cStart = 0;
          cEnd = cols;
          rSpacing = 0;
        } else {
          if (rSpacing == 0) {
            rSpacing = minLedgeSpacing.y + int(Math.random() * spacingRange);
            rSize = minLedgeSize + uint(Math.random() * sizeRange);
            if (facing == FlxObject.LEFT) {
              cStart = 0; 
              cEnd = rSize;
              facing = FlxObject.RIGHT;
            } else if (facing == FlxObject.RIGHT) {
              cStart = cols - rSize;
              cEnd = cols;
              facing = FlxObject.LEFT;
            }
          } else {
            rSpacing--;
          }
        }
        for (c = 0; c < cStart; c++) {
          col.push('0');
        }
        for (c = cStart; c < cEnd; c++) {
          col.push((rSpacing == 0) ? '1' : '0');
        }
        for (c = cEnd; c < cols; c++) {
          col.push('0');
        }
        mapData += col.join(',')+"\n";
      }
      
      // Creates a new tilemap with no arguments.
      collisionMap = new FlxTilemap();
      // Initializes the map using the generated string, the tile images, and the tile size.
      collisionMap.loadMap(mapData, auto_tiles, TILE_WIDTH, TILE_HEIGHT, FlxTilemap.AUTO);
      
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
      player.loadGraphic(ImgPlayer, true, true, 72);
      
      // Bounding box tweaks.
      player.height = 36;
      player.offset.y = 36;
      
      // Basic player physics.
      player.drag.x = 900; // anti-friction
      player.acceleration.y = 500; // gravity
      player.maxVelocity.x = 300;
      player.maxVelocity.y = 700;
      
      // Player jump physics.
      player.jumpVelocity.y = -420;
      
      // Animations.
      player.addAnimation('idle', [7]);
      player.addAnimation('run', [0,1,2,3,4,5,6,7,8,9,10,11], 12);
      player.addAnimation('jump', [3]);
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
    // Hooks.
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
    // Hooked routines.
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
