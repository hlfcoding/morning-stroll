package
{
  import org.flixel.FlxG;
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxRect;
  import org.flixel.FlxTilemap;
  import org.flixel.FlxU;

  // Platform that can dynamically generate a map, and track the dynamically
  // generated ledges. This makes up for FlxTilemap's lack of an API to get
  // tile groups (ledges) that have meta-data. Only supports the `SIDE_TO_SIDE`
  // generation scheme for now.
  
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
    public static const SIDE_TO_SIDE:uint = 1;

    public var tilingMode:uint;
    public var tilingStart:uint;

    public var hasCeiling:Boolean;
    public var hasFloor:Boolean;

    public var mapData:String;

    public var startingPoint:FlxPoint;
    public var endingPoint:FlxPoint;
    
    public var delegate:IPlatformDelegate;
    // To help the delegate.
    public var ledges:Array;
    public var ledgeRowCount:uint;
    
    public static const EMPTY_TILE:String = '0';
    public static const SOLID_TILE:String = '1';
    public static const META_TILE:String = '2';
    
    public static const EMPTY_ROW:uint = 0;
    public static const LEDGE_ROW:uint = 1;
    public static const SOLID_ROW:uint = 2;

    public function Platform()
    {
      super();
      this.structureMode = SIDE_TO_SIDE;
      this.tilingMode = FlxTilemap.AUTO;
      this.tilingStart = FlxObject.FLOOR;
      this.hasFloor = true;
      this.startingPoint = new FlxPoint();
      this.endingPoint = new FlxPoint();
      this.ledges = [];
    }

    public function generateData():void
    {
      var rows:int = Math.floor(this.bounds.height / this.tileWidth);
      var cols:int = Math.floor(this.bounds.width / this.tileHeight);
      // Smarts of our algo.
      var cStart:uint, cEnd:uint, facing:uint, rSize:uint, rSpacing:uint,
          sizeRange:uint, spacingRange:uint, inverse:Boolean, rClearance:uint,
          rStart:uint, rEnd:uint, rType:uint, ledge:PlatformLedge;
      // Grunts of our algo.
      var r:int, // Absolute row index.
          rL:int, // Ledge row index.
          c:int, // Column index.
          l:int, // Ledge layer index.
          col:Array;
      // Subroutines.
      var addRow:Function, setupEmptyRow:Function, setupFloorRow:Function,
          setupLedgeRow:Function, setupEachRow:Function;

      mapData = '';
      sizeRange = (this.maxLedgeSize - this.minLedgeSize);
      spacingRange = (this.maxLedgeSpacing.y - this.minLedgeSpacing.y);
      rClearance = this.minLedgeSpacing.y + this.ledgeThickness - 1;
      facing = FlxObject.RIGHT;
      if (this.tilingStart == FlxObject.FLOOR)
      {
        rStart = rows-1;
        rEnd = 0;
      }
      else
      {
        rEnd = rows-1;
        rStart = 0;
      }
      // Estimate the ledge row count.
      this.ledgeRowCount = rows /
        ((this.maxLedgeSpacing.y + this.minLedgeSpacing.y) / 2 +
          (this.ledgeThickness - 1));
      FlxG.log('Ledge row count: '+this.ledgeRowCount);
      // Plot the row, given the type. 
      addRow = function():void
      {
        if (rType == LEDGE_ROW && this.delegate != null)
        {
          // Pack.
          ledge = new PlatformLedge();
          ledge.index = rL;
          ledge.size = rSize;
          ledge.spacing = rSpacing;
          ledge.start = cStart;
          ledge.end = cEnd;
          ledge.facing = facing;
          // Transform.
          ledge = delegate.platformWillSetupLedgeRow(ledge);
          // Save.
          this.ledges.push(ledge);
          // Unpack.
          cStart = ledge.start;
          cEnd = ledge.end;
        }
        if (col.length == 0)
        {
          for (c = 0; c < cStart; c++) // For each column.
          {
            col.push(inverse ? SOLID_TILE : EMPTY_TILE);
          }
          for (c = cStart; c < cEnd; c++)
          {
            col.push(!inverse ? SOLID_TILE : EMPTY_TILE);
          }
          for (c = cEnd; c < cols; c++)
          {
            col.push(inverse ? SOLID_TILE : EMPTY_TILE);
          }
        }
        if (this.tilingStart == FlxObject.FLOOR)
        {
          mapData = col.join(',')+"\n" + mapData;
        }
        else
        {
          mapData += col.join(',')+"\n";
        }
      };
      // Prepare for emply plot.
      setupEmptyRow = function():void
      {
        cStart = 0;
        cEnd = 0;
        rType = EMPTY_ROW;
      };
      // Prepare for full plot.
      setupFloorRow = function():void
      {
        col = [];
        cStart = 0;
        cEnd = cols;
        rSpacing = 0;
        rType = SOLID_ROW;
      };
      // Prepare for partial plot. This just does a simple random, anything
      // more complicated is delegated.
      setupLedgeRow = function():void
      {
        rL++;
        rSize = this.minLedgeSize + uint(Math.random() * sizeRange);
        if (facing == FlxObject.LEFT)
        {
          cStart = 0;
          cEnd = rSize;
          // Prepare for next ledge.
          facing = FlxObject.RIGHT;
        }
        else if (facing == FlxObject.RIGHT)
        {
          cStart = cols - rSize;
          cEnd = cols;
          // Prepare for next ledge.
          facing = FlxObject.LEFT;
        }
        rType = LEDGE_ROW;
        // Prepare for next ledge.
        rSpacing = this.minLedgeSpacing.y + int(Math.random() * spacingRange);
      };
      // Reset on each row.
      setupEachRow = function():void
      {
        inverse = false;
        if (l == 0) {
          col = [];
        }
      };
      for ( // For each row.
        r = rStart;
        // Top-to-bottom or bottom-to-top.
        (rStart < rEnd && r < rEnd) || (rStart > rEnd && r >= rEnd);
        (rEnd != 0) ? r++ : r--
      ) 
      {
        if (r == rStart && this.tilingStart == FlxObject.FLOOR && this.hasFloor)
        {
          setupFloorRow.call(this);
          rSpacing = this.minLedgeSpacing.y;
        }
        else
        {
          setupEachRow.call(this);
          if (
            // If top-to-bottom.
            (rStart < rEnd && r+rClearance >= rEnd) ||
            // If bottom-to-top.
            (rStart > rEnd && r-rClearance <= rEnd) 
          )
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
      FlxG.log('Ledges: '+rL);
      FlxG.log('Map: '+this.mapData);

    }

    public function makeMap(tileGraphic:Class):FlxTilemap
    {
      if (mapData == null)
      {
        this.generateData();
      }

      return super.loadMap(
        mapData,
        tileGraphic,
        this.tileWidth, this.tileHeight,
        this.tilingMode
      );
    }

    public function isAtEndingPoint(obj:FlxObject):Boolean
    {
      var test:Boolean;
      // Bottom-to-top.
      if (this.endingPoint.y < this.startingPoint.y)
      {
        test = obj.y <= this.endingPoint.y;
      }
      // Top-to-bottom.
      else
      {
        test = obj.y >= this.endingPoint.y;
      }
      return test;
    }
  }
}