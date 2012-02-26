package
{
  import org.flixel.*;
  
  public class Player extends FlxSprite
  {
    
    // These aren't really used, but eventually may come in handy.
    public var rising:Boolean;
    public var falling:Boolean;
    public var pVelocity:FlxPoint;
    public var fallDist:Number;
    
    public function Player(X:Number=0, Y:Number=0, SimpleGraphic:Class=null)
    {
      super(X, Y, SimpleGraphic);
      this.rising = false;
      this.falling = false;
    }
    
    // This check can only be done once, for now.
    // TODO - Fix bugs.
    public function justFell():Boolean 
    {
      this.fallDist = this.y - this.fallDist;
      
      var did:Boolean = 
        this.justTouched(FlxObject.DOWN) 
        && this.falling 
        && this.pVelocity != null
        && this.fallDist > FlxG.height/2;
      
      if (did) 
      {
        this.falling = false;
      }
      
      return did;
    }
    
    public function moveWithInput():void {
      
      this.acceleration.x = 0;
      
      if (FlxG.keys.LEFT) 
      {
        this.facing = FlxObject.LEFT;
        this.acceleration.x -= this.drag.x;
      }
      else if (FlxG.keys.RIGHT)
      {
        this.facing = FlxObject.RIGHT;
        this.acceleration.x += this.drag.x;
      }
      // Try to jump.
      if (FlxG.keys.justPressed('UP') && this.velocity.y == 0)
      {
        this.y -= 1;
        this.velocity.y = -this.maxVelocity.y; // Negative is up.
        this.rising = true;
        this.fallDist = this.y;
      }
      // Start falling.
      else if (this.justTouched(FlxObject.UP) && this.rising)
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
        this.fallDist = this.y;
      }
      
    }
  }
}