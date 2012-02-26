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
    private const CEILING_TILE_Y:uint = 15; 
    private const MIN_LEDGE_SIZE:uint = 3;
    private const MAX_LEDGE_SIZE:uint = 6;
    private const MIN_LEDGE_SPACING:FlxPoint = new FlxPoint(4, 2);
    private const MAX_LEDGE_SPACING:FlxPoint = new FlxPoint(8, 4);
    
    // The dynamically generated FlxTilemap we're using.
    private var collisionMap:FlxTilemap;
    // Ledge controls, in tiles.
    
    // Instance of custom player class.
    private var player:Player;
    private var fallChecking:Boolean;
    
    private var bg:FlxSprite;
    
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
      var cStart:uint, cEnd:uint, facing:uint, rSize:int, rSpacing:int, sizeRange:uint, spacingRange:uint, inverse:Boolean;
      // Grunts of our algo.
      var r:int, c:int, col:Array;
      sizeRange = (MAX_LEDGE_SIZE - MIN_LEDGE_SIZE);
      spacingRange = (MAX_LEDGE_SPACING.y - MIN_LEDGE_SPACING.y);
      facing = FlxObject.RIGHT;
      for (r = 0; r < rows; r++) 
      {
        inverse = false;
        col = [];
        if (r >= rows - MIN_LEDGE_SPACING.y || r < MIN_LEDGE_SPACING.y + CEILING_TILE_Y)
        {
          cStart = 0;
          cEnd = 0;
        }
        if (r == rows-1)
        {
          cStart = 0;
          cEnd = cols;
          rSpacing = 0;
        } 
        else if (r > CEILING_TILE_Y + MIN_LEDGE_SPACING.y)
        {
          if (rSpacing == 0)
          {
            rSpacing = MIN_LEDGE_SPACING.y + int(Math.random() * spacingRange);
            rSize = MIN_LEDGE_SIZE + uint(Math.random() * sizeRange);
            if (facing == FlxObject.LEFT) 
            {
              cStart = 0; 
              cEnd = rSize;
              facing = FlxObject.RIGHT;
            } 
            else if (facing == FlxObject.RIGHT)
            {
              cStart = cols - rSize;
              cEnd = cols;
              facing = FlxObject.LEFT;
            }
          }
          else
          {
            rSpacing--;
          }
        } 
        else if (r == CEILING_TILE_Y)
        {
          cStart = MIN_LEDGE_SIZE + 2;
          cEnd = cols - (MIN_LEDGE_SIZE + 2);
          rSpacing = 0;
          inverse = true;
        }
        for (c = 0; c < cStart; c++)
        {
          col.push(inverse ? '1' : '0');
        }
        for (c = cStart; c < cEnd; c++)
        {
          col.push((rSpacing == 0 && !inverse) ? '1' : '0');
        }
        for (c = cEnd; c < cols; c++)
        {
          col.push(inverse ? '1' : '0');
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
//      start.x = 0;
//      start.y = 0;
      setupPlayer(start);
      
      // Move until we don't overlap.
      while (collisionMap.overlaps(player)) 
      {
        if (player.x <= 0) 
        {
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
      player.height = player.frameWidth / 2;
      player.offset.y = player.frameWidth - player.height;
      player.tailOffset.x = 35;
      player.headOffset.x = 10;
      player.width = player.frameWidth - player.tailOffset.x;
      player.face(FlxObject.RIGHT);
      
      // Basic player physics.
      player.drag.x = 900; // anti-friction
      player.acceleration.y = 500; // gravity
      player.maxVelocity.x = 300;
      player.maxVelocity.y = 1500;
      
      // Player jump physics.
      player.jumpVelocity.y = -420;
      
      // Animations.
      player.addAnimation('idle', [12,13,14], 12);
      player.addAnimation('wait', [15,16,17], 12, false);
      player.addAnimation('run', [0,1,2,3,4,5,6,7,8,9,10,11], 12);
      player.addAnimation('jump', [18,19,20,21,22,23,24,25,26,27,28,29,30], 18, false);
      player.addAnimation('fall', [31]);
      player.addAnimation('land', [32,33], 12, false);
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
      
      if (player.willJump) // We only need to play the jump animation once.
      {
        player.play('jump');
      }
      else if (player.justFell()) 
      {
        player.play('land');
      }
      else if (!player.rising) 
      {
        if (player.finished && player.falling)
        {
          player.play('fall');
        }
        else if (player.finished && player.velocity.x == 0 || player.x == 0 || player.x >= (collisionMap.width - player.width))
        {
          player.play('idle');
        }
        else if (player.finished)
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
      obj.x = FlxU.bound(obj.x, 0, (collisionMap.width - obj.width));
      obj.y = FlxU.bound(obj.y, 0, (collisionMap.height - obj.height));
    }
  }
}
