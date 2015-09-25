```js
package
{
  import org.flixel.FlxG;
  import org.flixel.FlxPoint;
  import org.flixel.FlxState;

  // The main coordinator: part config list, part asset list, part delegate.
  // Handles all of the character animations, and custom platform generation.
  // The stage is set up based on the bg group's bounds; the platform and
  // camera are set up around it.

  public class PlayState extends FlxState
  {
    // Flixel Methods
    // --------------
    override public function create():void
    {
      FlxG.mouse.hide();
    }

    // Hooked routines.
    private function setupPlayer(start:FlxPoint):void
    {
      // Bounding box tweaks.
      player.tailOffset.x = 35;
      player.headOffset.x = 10;

      // Process settings.
      player.init();
    }
  }
}

package
{
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxSprite;

  public class Player extends FlxSprite
  {

    public static const LANDING:uint = 2;

    public var tailOffset:FlxPoint;
    public var headOffset:FlxPoint;

    public function Player(X:Number=0, Y:Number=0, SimpleGraphic:Class=null)
    {
      super(X, Y, SimpleGraphic);

      this.finished = true;

      this.tailOffset = new FlxPoint();
      this.headOffset = new FlxPoint();
    }

    override public function update():void
    {
      // Vertical
      else if (this.isTouching(FlxObject.UP) && this.currently == RISING)
      {
        // Start falling.
        this.pVelocity = null;
      }
    }

    // Update Routines
    // ---------------
    private function jumpStart():void
    {
      this.y--;
    }
  }
}
```
