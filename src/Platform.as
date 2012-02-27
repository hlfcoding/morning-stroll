package
{
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxRect;
  import org.flixel.FlxTilemap;
  import org.flixel.FlxU;
  
  public class Platform extends FlxTilemap
  {
    public var tileWidth:uint;
    public var tileHeight:uint;
    
    public var minLedgeSize:uint;
    public var maxLedgeSize:uint;
    
    public var minLedgeSpacing:FlxPoint;
    public var maxLedgeSpacing:FlxPoint;
    
    public var bounds:FlxRect;
    
    public var structureMode:uint;
    public const SIDE_TO_SIDE:uint = 1;
    
    public var tilingMode:uint;
    
    public var hasCeiling:Boolean;
    public var hasFloor:Boolean;
    
    private var mapData:String;
    
    public function Platform()
    {
      super();
      this.tilingMode = FlxTilemap.AUTO;
    }
    
    public function generateData():void
    {
      var rows:int = Math.floor(this.bounds.height / this.tileWidth);
      var cols:int = Math.floor(this.bounds.width / this.tileHeight);
      // Smarts of our algo.
      var cStart:uint, cEnd:uint, facing:uint, rSize:int, rSpacing:int, sizeRange:uint, spacingRange:uint, inverse:Boolean;
      // Grunts of our algo.
      var r:int, c:int, col:Array;
      
      mapData = '';
      sizeRange = (this.maxLedgeSize - this.minLedgeSize);
      spacingRange = (this.maxLedgeSpacing.y - this.minLedgeSpacing.y);
      facing = FlxObject.RIGHT;
      
      for (r = 0; r < rows; r++) 
      {
        inverse = false;
        col = [];
        if (r >= rows - this.minLedgeSpacing.y || r < this.minLedgeSpacing.y)
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
        else
        {
          if (rSpacing == 0)
          {
            rSpacing = this.minLedgeSpacing.y + int(Math.random() * spacingRange);
            rSize = this.minLedgeSize + uint(Math.random() * sizeRange);
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
      
    }
    
    public function makeMap(tileGraphic:Class):FlxTilemap 
    {
      if (mapData == null) {
        this.generateData();
      }
        
      return super.loadMap(
        mapData, 
        tileGraphic, 
        this.tileWidth, this.tileHeight, 
        this.tilingMode
      );
    }
    
  }
}