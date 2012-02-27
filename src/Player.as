package
{
  import org.flixel.*;
  
  public class Player extends FlxSprite
  {
    
    // These aren't really used, but eventually may come in handy.
    public var rising:Boolean = false;
    public var falling:Boolean = false;
    public var willJump:Boolean = false;
    public var willStop:Boolean = false;
    public var willStart:Boolean = false;
    public var pVelocity:FlxPoint;
    public var jumpVelocity:FlxPoint;
    public var tailOffset:FlxPoint;
    public var headOffset:FlxPoint;
    public var acclFactor:Number = 0.5;
    public var acclJumpFactor:Number = 0.1;
    
    public function Player(X:Number=0, Y:Number=0, SimpleGraphic:Class=null)
    {
      super(X, Y, SimpleGraphic);
      this.jumpVelocity = new FlxPoint();
      this.pVelocity = this.velocity;
      this.tailOffset = new FlxPoint();
      this.headOffset = new FlxPoint();
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
      if (!(this.rising || this.falling)) 
      {
        this.acceleration.x = 0;
      }
      if (FlxG.keys.LEFT) 
      {
        if (this.facing == FlxObject.RIGHT)
        {
          this.face(FlxObject.LEFT);
        }
        this.run(-1);
      }
      else if (FlxG.keys.RIGHT)
      {
        if (this.facing == FlxObject.LEFT)
        {
          this.face(FlxObject.RIGHT);
        }
        this.run();
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
      if (FlxG.keys.justPressed('UP') && this.velocity.y == 0)
      {
        // Try to jump.
        this.y -= 1;
        this.velocity.y = this.jumpVelocity.y; // Negative is up.
        this.rising = true;
        this.falling = false;
        this.willJump = true;
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
      var factor:Number = this.acclFactor;
      if (this.rising || this.falling)
      {
        factor = this.acclJumpFactor;
      }
      this.acceleration.x = this.drag.x * factor * direction;
    }
  }
}