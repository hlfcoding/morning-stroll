package
{
  import org.flixel.FlxG;
  import org.flixel.FlxObject;
  import org.flixel.FlxPoint;
  import org.flixel.FlxSprite;
  import org.flixel.FlxTimer;
  import org.flixel.FlxU;
  
  public class Player extends FlxSprite
  {
    
    // These aren't really used, but eventually may come in handy.
    public var rising:Boolean = false;
    public var falling:Boolean = false;
    public var willJump:Boolean = false;
    public var willStop:Boolean = false;
    public var willStart:Boolean = false;
    public var controlled:Boolean = true;

    public var pVelocity:FlxPoint;
    public var jumpMaxVelocity:FlxPoint;
    public var jumpAccel:FlxPoint;
    public var oDrag:FlxPoint;
    public var jumpDrag:FlxPoint;
    public var accelFactor:Number = 0.5;
    public var accelJumpFactor:Number = 0.1;
    public var naturalForces:FlxPoint = new FlxPoint(1000, 500);
    public var jumpMaxDuration:Number = 0.5;
    private var jumpTimer:FlxTimer;

    public var tailOffset:FlxPoint;
    public var headOffset:FlxPoint;

    public function Player(X:Number=0, Y:Number=0, SimpleGraphic:Class=null)
    {
      super(X, Y, SimpleGraphic);
      
      this.pVelocity = this.velocity;
      this.jumpMaxVelocity = new FlxPoint();
      this.jumpAccel = new FlxPoint();
      this.oDrag = new FlxPoint();
      this.jumpDrag = new FlxPoint();
      jumpTimer = new FlxTimer();
      jumpTimer.stop();
      
      this.tailOffset = new FlxPoint();
      this.headOffset = new FlxPoint();
    }
    
    public function init():void
    {
      this.drag.x = this.naturalForces.x;
      this.acceleration.y = this.naturalForces.y;
      this.oDrag.x = this.drag.x;
      this.jumpDrag.x = this.oDrag.x * 2;
    }
    
    // Flixel Methods
    // --------------
    override public function postUpdate():void 
    {
      if (this.justFell())
      {
        this.falling = false;
      }
      super.postUpdate();
    }
    
    // This check can only be done once, for now.
    // TODO - Fix bugs.
    public function justFell():Boolean
    {
      var did:Boolean = 
        this.justTouched(FlxObject.DOWN) 
        && this.falling 
        && this.pVelocity != null;
      
      return did;
    }
    
    public function face(direction:uint):void
    {
      if (this.velocity.x != 0 && !this.willStop && this.facing != direction) 
      {
        this.willStop = true;
        this.willStart = false;
      }
      else if (this.finished)
      {
        this.willStop = false;
        this.willStart = true;
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
    
    public function moveWithInput():void 
    {
      if (!this.controlled) { return; }
      if (!(this.rising || this.falling)) 
      {
        this.acceleration.x = 0;
      }
      if (!jumpTimer.finished) {
        // Negative is up.
        this.velocity.y = FlxU.bound(this.velocity.y, 0, this.jumpMaxVelocity.y);
      }
      // Horizontal
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
      else if (!(this.rising || this.falling) && this.acceleration.x == 0)
      {
        if (this.velocity.x == 0) 
        {
          this.willStop = false;
          this.willStart = true;
        }
        else
        {
          this.willStop = true;
          this.willStart = false;
        }
      }
      // Vertical
      if (FlxG.keys.justPressed('UP') && jumpTimer.finished &&
          this.isTouching(FlxObject.FLOOR))
      {
        // Try to jump.
        jumpStart();
      }
      else if (FlxG.keys.justReleased('UP'))
      {
        jumpEnd();
      }
      else if (this.willJump) 
      {
        this.willJump = false;
      }
      else if (this.isTouching(FlxObject.UP) && this.rising)
      {
        // Start falling.
        this.falling = true;
        this.rising = false;
        this.pVelocity = null;
      }
      else if (this.falling && this.velocity.y > 0) 
      {
        this.pVelocity = this.velocity;
      }
      else if (!this.falling && this.velocity.y > 0) 
      {
        this.rising = false;
        this.falling = true;
      }
    }
    private function run(direction:int=1):void
    {
      var factor:Number = this.accelFactor;
      if (this.rising || this.falling)
      {
        factor = this.accelJumpFactor;
      }
      this.acceleration.x = this.drag.x * factor * direction;
    }
    private function jumpStart():void
    {
//      trace('start');
      this.y--;
      this.rising = true;
      this.willJump = true;
      this.acceleration.y = this.jumpAccel.y;
      this.acceleration.x = 0;
      this.drag.x = this.jumpDrag.x;
      jumpTimer.start(this.jumpMaxDuration, 1, 
        function(timer:FlxTimer):void {
          jumpEnd(); 
        });
    }
    private function jumpEnd():void
    {
//      trace('end');
      this.acceleration.y = this.naturalForces.y;
      this.drag.x = this.oDrag.x;
      jumpTimer.stop();
    }
  }
}