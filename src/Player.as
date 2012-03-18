package
{
  import org.flixel.FlxG;
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxSprite;
  import org.flixel.FlxTimer;
  import org.flixel.FlxU;
  import org.flixel.system.FlxAnim;

  // Player that has more complex running and jumping abilities.
  // It makes use of an animation delegate and has a simple state
  // tracking system. It also takes into account custom offsets.
  // It also allows for custom camera tracking.
  // This class is meant to be very configurable and has many hooks.

  public class Player extends FlxSprite
  {

    public var currently:uint;
    public static const STILL:uint = 0;
    public static const RUNNING:uint = 1;
    public static const LANDING:uint = 2;
    public static const RISING:uint = 101;
    public static const FALLING:uint = 102;

    // Note this is not always cleared.
    public var nextAction:uint;
    public static const NO_ACTION:uint = 0;
    public static const JUMP:uint = 1;
    public static const STOP:uint = 2;
    public static const START:uint = 3;

    public var controlled:Boolean;

    public var animDelegate:IPlayerAnimationDelegate;

    public var naturalForces:FlxPoint = new FlxPoint(1000, 500);
    public var pVelocity:FlxPoint;
    public var accelFactor:Number = 0.5;
    public var jumpMaxVelocity:FlxPoint;
    public var jumpAccel:FlxPoint;
    // This should be small. Negative creates some drag.
    public var accelJumpFactor:Number = -0.001;
    public var jumpDrag:FlxPoint;
    public var oDrag:FlxPoint;
    public var jumpMinDuration:Number = 0.1;
    public var jumpMaxDuration:Number = 0.5;
    private var jumpTimer:FlxTimer;

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

      this.currently = FALLING;
      this.nextAction = NO_ACTION;
      
      this.controlled = true;

      this.pVelocity = this.velocity;
      this.jumpMaxVelocity = new FlxPoint();
      this.jumpAccel = new FlxPoint();
      this.oDrag = new FlxPoint();
      this.jumpDrag = new FlxPoint();
      jumpTimer = new FlxTimer();
      jumpTimer.stop();

      this.tailOffset = new FlxPoint();
      this.headOffset = new FlxPoint();

      this.cameraFocus = new FlxObject(this.x, this.y, this.width, this.height);
      this.updateFocus = true;
    }

    public function init():void
    {
      this.drag.x = this.naturalForces.x;
      this.acceleration.y = this.naturalForces.y;
      this.oDrag.x = this.drag.x;
      this.jumpDrag.x = this.oDrag.x * 2;
      if (this.animDelegate == null)
      {
        throw new Error('Player animation delegate is required.');
      }
      this.animDelegate.playerIsFalling();
    }

    // Flixel Methods
    // --------------
    override public function update():void
    {
      if (!this.controlled) return;

      // Horizontal
      // - Revert to still. (Our acceleration updates funny.)
      if (!this.inMidAir())
      {
        this.acceleration.x = 0;
      }
      // - Basically handle switching direction, and running or being still
      // when not in the air. Note the player still runs in midair, but run
      // will behave differently.
      if (FlxG.keys.LEFT)
      {
        if (this.facing == FlxObject.RIGHT)
        {
          this.face(FlxObject.LEFT);
        }
        run(-1);
      }
      else if (FlxG.keys.RIGHT)
      {
        if (this.facing == FlxObject.LEFT)
        {
          this.face(FlxObject.RIGHT);
        }
        run();
      }
      else if (!this.inMidAir())
      {
        if (this.acceleration.x == 0)
        {
          this.nextAction = (this.velocity.x == 0) ? START : STOP;
        }
        if (this.velocity.x == 0)
        {
          this.currently = STILL;
        }
      }

      // Vertical
      // - Constrain jump.
      if (!jumpTimer.finished)
      {
        // Negative is up.
        this.velocity.y = FlxU.bound(this.velocity.y, 0, this.jumpMaxVelocity.y);
      }
      // - Basically handle starting and ending of jump, and starting of
      // falling. The tracking of pVelocity is an extra complexity. The
      // possibility of hitting the ceiling during jump is another one.
      if (
        FlxG.keys.justPressed('UP') && jumpTimer.finished &&
        this.isTouching(FlxObject.FLOOR)
      )
      {
        // Try to jump.
        jumpStart();
      }
      else if (FlxG.keys.justReleased('UP'))
      {
        jumpEnd();
      }
      else if (this.isTouching(FlxObject.UP) && this.currently == RISING)
      {
        // Start falling.
        this.currently = FALLING;
        this.pVelocity = null;
      }
      else if (this.velocity.y > 0)
      {
        if (this.currently == FALLING)
        {
          this.pVelocity = this.velocity;
        }
        else
        {
          this.currently = FALLING;
        }
      }
      // - Handle ending of falling.
      if (this.justFell())
      {
        this.currently = LANDING;
      }
      
      // - Handle focus.
      if (this.updateFocus)
      {
        this.cameraFocus.x += (this.x - this.cameraFocus.x) / this.cameraSpeed;
        this.cameraFocus.y += (this.y - this.cameraFocus.y) / this.cameraSpeed;
      }
    }
    // Animations get updated after movement.
    override protected function updateAnimation():void
    {
      this.animDelegate.playerWillUpdateAnimation();
      if (this.currently == STILL)
      {
        this.animDelegate.playerIsStill();
      }
      else if (this.currently == RUNNING)
      {
        this.animDelegate.playerIsRunning();
      }
      else if (this.currently == LANDING)
      {
        this.animDelegate.playerIsLanding();
      }
      else if (this.currently == RISING)
      {
        this.animDelegate.playerIsRising();
      }
      else if (this.currently == FALLING)
      {
        this.animDelegate.playerIsFalling();
      }
      super.updateAnimation();
      this.animDelegate.playerDidUpdateAnimation();
    }

    // Update API
    // ----------
    public function justFell():Boolean
    {
      var did:Boolean =
        this.justTouched(FlxObject.DOWN)
        && this.currently == FALLING
        && this.pVelocity != null;

      return did;
    }
    public function inMidAir():Boolean
    {
      return this.currently >= RISING;
    }
    public function face(direction:uint):void
    {
      if (
        this.velocity.x != 0 &&
        this.nextAction != STOP &&
        this.facing != direction
      )
      {
        this.nextAction = STOP;
        if (!this.inMidAir())
        {
          this.animDelegate.playerWillStop();
        }
      }
      else if (this.finished)
      {
        this.nextAction = START;
        if (!this.inMidAir())
        {
          this.animDelegate.playerWillStart();
        }
        if (direction == FlxObject.RIGHT)
        {
          this.offset.x = this.tailOffset.x;
          this.facing = FlxObject.RIGHT;
        }
        else if (direction == FlxObject.LEFT)
        {
          this.offset.x = 0;
          this.facing = FlxObject.LEFT;
        }
      }
    }
    public function currentAnimation():FlxAnim
    {
      return this._curAnim;
    }

    // Update Routines
    // ---------------
    private function run(direction:int=1):void
    {
      var factor:Number = this.accelFactor;
      if (this.inMidAir())
      {
        factor = this.accelJumpFactor;
      }
      else if (this.currently != RUNNING)
      {
        this.currently = RUNNING;
      }
      this.acceleration.x = this.drag.x * factor * direction;
    }
    private function jumpStart():void
    {
      var jumpMaxDuration:Number = this.jumpMinDuration +
        FlxU.abs(this.velocity.x/this.maxVelocity.x) * (this.jumpMaxDuration-this.jumpMinDuration);
      this.animDelegate.playerWillJump();
      this.y--;
      this.currently = RISING;
      this.acceleration.y = this.jumpAccel.y;
      this.acceleration.x = 0;
      this.drag.x = this.jumpDrag.x;
      jumpTimer.start(jumpMaxDuration, 1,
        function(timer:FlxTimer):void {
          jumpEnd();
        });
    }
    private function jumpEnd():void
    {
      this.acceleration.y = this.naturalForces.y;
      this.drag.x = this.oDrag.x;
      jumpTimer.stop();
    }
  }
}