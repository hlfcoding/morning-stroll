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
    
    public var ledgeThickness:uint;
    
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
      var r:int, c:int, l:int, col:Array;
      // Subroutines.
      var addRow:Function, setupEmptyRow:Function, setupFloorRow:Function, setupLedgeRow:Function, setupEachRow:Function;
      
      mapData = '';
      sizeRange = (this.maxLedgeSize - this.minLedgeSize);
      spacingRange = (this.maxLedgeSpacing.y - this.minLedgeSpacing.y);
      facing = FlxObject.RIGHT;
      
      addRow = function():void
      {
        if (col.length == 0) 
        {
          for (c = 0; c < cStart; c++) // For each column.
          {
            col.push(inverse ? '1' : '0');
          }
          for (c = cStart; c < cEnd; c++)
          {
            col.push(!inverse ? '1' : '0');
          }
          for (c = cEnd; c < cols; c++)
          {
            col.push(inverse ? '1' : '0');
          }
        }
        mapData += col.join(',')+"\n";
      };
      setupEmptyRow = function():void
      {
        cStart = 0;
        cEnd = 0;      
      };
      setupFloorRow = function():void
      {
        col = [];
        cStart = 0;
        cEnd = cols;
        rSpacing = 0;
      };
      setupLedgeRow = function():void
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
      };
      setupEachRow = function():void
      {
        inverse = false;
        if (l == 0) {
          col = [];
        }
      };
      
      for (r = 0; r < rows; r++) // For each row. 
      {
        if (r == rows-1)
        {
          setupFloorRow.call(this);
        }
        else 
        {
          setupEachRow.call(this);
          if (r >= rows - this.minLedgeSpacing.y || r < this.minLedgeSpacing.y)
          {
            setupEmptyRow.call(this);
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