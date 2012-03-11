package
{
  import org.flixel.FlxG;
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
    public static const SIDE_TO_SIDE:uint = 1;

    public var tilingMode:uint;
    public var tilingStart:uint;

    public var hasCeiling:Boolean;
    public var hasFloor:Boolean;

    private var mapData:String;

    public var startingPoint:FlxPoint;
    public var endingPoint:FlxPoint;

    public function Platform()
    {
      super();
      this.structureMode = SIDE_TO_SIDE;
      this.tilingMode = FlxTilemap.AUTO;
      this.tilingStart = FlxObject.FLOOR;
      this.hasFloor = true;
      this.startingPoint = new FlxPoint();
      this.endingPoint = new FlxPoint();
    }

    public function generateData():void
    {
      var rows:int = Math.floor(this.bounds.height / this.tileWidth);
      var cols:int = Math.floor(this.bounds.width / this.tileHeight);
      // Smarts of our algo.
      var cStart:uint, cEnd:uint, facing:uint, rSize:int, rSpacing:int,
          sizeRange:uint, spacingRange:uint, inverse:Boolean,
          rStart:int, rEnd:int;
      // Grunts of our algo.
      var r:int, c:int, l:int, col:Array;
      // Subroutines.
      var addRow:Function, setupEmptyRow:Function, setupFloorRow:Function,
          setupLedgeRow:Function, setupEachRow:Function;

      mapData = '';
      sizeRange = (this.maxLedgeSize - this.minLedgeSize);
      spacingRange = (this.maxLedgeSpacing.y - this.minLedgeSpacing.y);
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
        if (this.tilingStart == FlxObject.FLOOR)
        {
          mapData = col.join(',')+"\n" + mapData;
        }
        else
        {
          mapData += col.join(',')+"\n";
        }
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
      for (r = rStart;
           (rStart < rEnd && r < rEnd) || (rStart > rEnd && r >= rEnd);
           (rEnd != 0) ? r++ : r--) // For each row. // TODO - Optimize throughout.
      {
        if (r == rStart && this.tilingStart == FlxObject.FLOOR && this.hasFloor)
        {
          setupFloorRow.call(this);
          rSpacing = this.minLedgeSpacing.y;
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

    public function isAtEndingPoint(obj:FlxObject):Boolean
    {
      var test:Boolean;
      test = obj.isTouching(FlxObject.FLOOR);
      if (!test) {
        return test;
      }
      if (this.endingPoint.y < this.startingPoint.y) {
        test = obj.y <= this.endingPoint.y;
      } else {
        test = obj.y >= this.endingPoint.y;
      }
      return test;
    }
  }
}