package
{
  import org.flixel.*;
  
  public class Player extends FlxSprite
  {
    
    // These aren't really used, but eventually may come in handy.
    public var rising:Boolean;
    public var falling:Boolean;
    public var willJump:Boolean;
    public var pVelocity:FlxPoint;
    public var jumpVelocity:FlxPoint;
    public var tailOffset:FlxPoint;
    public var headOffset:FlxPoint;
    
    public function Player(X:Number=0, Y:Number=0, SimpleGraphic:Class=null)
    {
      super(X, Y, SimpleGraphic);
      this.rising = false;
      this.falling = false;
      this.willJump = false;
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
    
    public function moveWithInput():void 
    {
      this.acceleration.x = 0;
      
      if (FlxG.keys.LEFT) 
      {
        if (this.facing == FlxObject.RIGHT)
        {
          this.face(FlxObject.LEFT);
        }
        this.acceleration.x -= this.drag.x;
      }
      else if (FlxG.keys.RIGHT)
      {
        if (this.facing == FlxObject.LEFT)
        {
          this.face(FlxObject.RIGHT);
        }
        this.acceleration.x += this.drag.x;
      }
      // Try to jump.
      if (FlxG.keys.justPressed('UP') && this.velocity.y == 0)
      {
        this.y -= 1;
        this.velocity.y = this .jumpVelocity.y; // Negative is up.
        this.rising = true;
        this.falling = false;
        this.willJump = true;
      }
      else if (this.willJump) 
      {
        this.willJump = false;
      }
      // Start falling.
      else if (this.isTouching(FlxObject.UP) && this.rising)
      {
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
  }
}