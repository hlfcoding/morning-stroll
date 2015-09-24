```js
package
{
  import org.flixel.FlxG;
  import org.flixel.FlxPoint;
  import org.flixel.FlxState;
  import org.flixel.FlxTimer;
  import org.flixel.FlxU;

  // The main coordinator: part config list, part asset list, part delegate.
  // Handles all of the character animations, and custom platform generation.
  // The stage is set up based on the bg group's bounds; the platform and
  // camera are set up around it.

  public class PlayState extends FlxState
  {
    // Some game switches.
    private var fallChecking:Boolean;

    // Game state.
    private var didTheEnd:Boolean;

    // The music.
    private var playMusic:Boolean;

    // Flixel Methods
    // --------------
    override public function create():void
    {
      FlxG.mouse.hide();

      // Globals.
      fallChecking = false;

      // Internals.
      didTheEnd = false;

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
    // Hooks.
    private function updatePlatformAfter():void
    {
      updatePlayer();
    }
    private function updatePlatformAndPlayerAfter():void
    {
      updateGameState();
    }
    // Hooked routines.
    private function updatePlayer():void
    {
      // Wrap to stage.
      if (!player.inMidAir() && player.nextAction != Player.STOP)
      {
        var pPos:FlxPoint = new FlxPoint(player.x, player.y);
        player.x = FlxU.bound(player.x, 0, (platform.width - player.width));
        var pos:FlxPoint = new FlxPoint(player.x, player.y);
        if (FlxU.getDistance(pos, pPos) > 0)
        {
          player.nextAction = Player.STOP;
        }
        pos = pPos = null;
      }
    }
    private function updateAudio(force:Boolean=false):void
    {
      if (didTheEnd) return;
    }
    private function updateGameState(doChecks:Boolean=false):void
    {
      if ((didTheEnd && FlxG.mouse.justPressed()) || FlxG.keys.justPressed('Q'))
      {
        var fadeDuration:Number = 3;
        FlxG.music.fadeOut(fadeDuration);
        gameStatePollInterval.stop();
        gameStatePollInterval.start(fadeDuration, 1,
          function(onTimer:FlxTimer):void {
            MorningStroll.endGame();
          }
        );
      }
    }
  }
}

package
{
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxSprite;
  import org.flixel.FlxU;

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

    // Flixel Methods
    // --------------
    override public function destroy():void
    {
      super.destroy();

      this.tailOffset = null;
      this.headOffset = null;

      this.cameraFocus.destroy();
      this.cameraFocus = null;
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

package
{
  import org.flixel.FlxObject;
  import org.flixel.FlxTilemap;

  public class Platform extends FlxTilemap
  {
    // Flixel Methods
    // --------------
    override public function destroy():void
    {
      super.destroy();
      
      this.mapData = null;
      
      this.startingPoint = null;
      this.endingPoint = null;
      
      for each (var l:PlatformLedge in this.ledges) { l = null; }
      this.ledges = null;
      
      this.minLedgeSpacing = null;
      this.maxLedgeSpacing = null;
      
      this.bounds = null;
      this.delegate = null;
    }
  }
}
```
