```js
package
{
  import org.flixel.FlxCamera;
  import org.flixel.FlxG;
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxSound;
  import org.flixel.FlxSprite;
  import org.flixel.FlxState;
  import org.flixel.FlxTimer;
  import org.flixel.FlxU;

  // The main coordinator: part config list, part asset list, part delegate.
  // Handles all of the character animations, and custom platform generation.
  // The stage is set up based on the bg group's bounds; the platform and
  // camera are set up around it.

  public class PlayState extends FlxState
    implements IPlayerAnimationDelegate
  {
    // Some game switches.
    private var fallChecking:Boolean;

    // Game state.
    private var gameStatePollInterval:FlxTimer;
    private var didTheEnd:Boolean;
    private var endAnimDuration:Number;

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
      // Don't do expensive operations too often, if possible.
      gameStatePollInterval = new FlxTimer();
      gameStatePollInterval.start(2, Number.POSITIVE_INFINITY,
        function(onTimer:FlxTimer):void {
          updateGameState(true);
        }
      );
      didTheEnd = false;

    }

    override public function destroy():void
    {
      super.destroy();

      gameStatePollInterval.destroy();
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
      updateMate();
    }
    private function updatePlatformAndPlayerAfter():void
    {
      updateCamera(player.justFell());
      updateGameState();
    }
    // Hooked routines.
    private function updatePlayer():void
    {
      // Tilemaps can be collided just like any other FlxObject, and flixel
      // automatically collides each individual tile with the object.
      if (player.controlled)
      {
        FlxG.collide(player, platform);
      }
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
    private function updateMate():void
    {
      FlxG.collide(mate, platform);
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
    private function updateAudio(force:Boolean=false):void
    {
      if (didTheEnd) return;
    }
    private function updateGameState(doChecks:Boolean=false):void
    {
      if (doChecks)
      {
        // Check if player is on top of last platform, periodically.
        // Play the end screen for a while, on click, switch to start screen.
        if (player.currently == Player.STILL && platform.isAtEndingPoint(FlxObject(player)))
        {
          if (player.controlled)
          {
            player.controlled = false;
            // TODO - Follow path, then animate.
            player.addAnimationCallback(
              function(name:String, frameNumber:uint, frameIndex:uint):void {
                if (name == 'end' && frameNumber == 6)
                {
                  mate.play('end');
                }
                if (name == 'still')
                {
                  player.frame = player.frames-1;
                  mate.frame = mate.frames-1;
                }
              }
            );
            player.x = mate.x;
            player.y = mate.y;
            player.height = mate.height;
            player.offset.y = mate.offset.y;
            player.offset.x = 43;
            player.facing = FlxObject.RIGHT;
            player.play('end');
            gameStatePollInterval.stop();
            gameStatePollInterval.start(5, 1, 
              function(onTimer:FlxTimer):void {
                var title:Text, instructions:Text;
                title = new Text(0, Text.BASELINE * 2, FlxG.width,
                  "The End", Text.H1);
                instructions = new Text(0, Text.BASELINE * 4, FlxG.width,
                  "Click to play again");
                instructions.size = 16;
                // Stay on the screen.
                instructions.scrollFactor = title.scrollFactor = new FlxPoint();
                add(title);
                add(instructions);
                didTheEnd = true;
              }
            );
          }
        }
      }
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

    // Player Delegate Methods
    // -----------------------
    // Interruptive, once.
    public function playerWillJump():void
    {
      player.updateFocus = false;
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

    public var currently:uint;
    public static const LANDING:uint = 2;

    public var controlled:Boolean;

    public var animDelegate:IPlayerAnimationDelegate;

    public var pVelocity:FlxPoint;

    public var tailOffset:FlxPoint;
    public var headOffset:FlxPoint;

    public var cameraFocus:FlxObject;
    public var updateFocus:Boolean;
    // Basically, 1/n traveled per tween.
    public var cameraSpeed:Number = 30;

    public function Player(X:Number=0, Y:Number=0, SimpleGraphic:Class=null)
    {
      super(X, Y, SimpleGraphic);

      this.finished = true;

      this.controlled = true;

      this.pVelocity = this.velocity;

      this.tailOffset = new FlxPoint();
      this.headOffset = new FlxPoint();

      this.cameraFocus = new FlxObject(this.x, this.y, this.width, this.height);
      this.updateFocus = true;
    }

    // Flixel Methods
    // --------------
    override public function destroy():void
    {
      super.destroy();

      this.pVelocity = null;

      this.tailOffset = null;
      this.headOffset = null;

      this.cameraFocus.destroy();
      this.cameraFocus = null;
    }

    override public function update():void
    {
      if (!this.controlled)
      {
        // TODO - Move to setter.
        this.velocity = new FlxPoint();
        this.acceleration = new FlxPoint();
        return;
      }

      // Vertical
      else if (this.isTouching(FlxObject.UP) && this.currently == RISING)
      {
        // Start falling.
        this.pVelocity = null;
      }

      // - Handle focus.
      if (this.updateFocus)
      {
        this.cameraFocus.x += FlxU.round((this.x - this.cameraFocus.x) / this.cameraSpeed);
        this.cameraFocus.y += FlxU.round((this.y - this.cameraFocus.y) / this.cameraSpeed);
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
  import org.flixel.FlxPoint;
  import org.flixel.FlxTilemap;

  public class Platform extends FlxTilemap
  {
    public var startingPoint:FlxPoint;
    public var endingPoint:FlxPoint;
    
    public function Platform()
    {
      super();
      this.startingPoint = new FlxPoint();
      this.endingPoint = new FlxPoint();
    }
    
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
```
