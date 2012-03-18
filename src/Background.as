package
{
  import org.flixel.FlxBasic;
  import org.flixel.FlxG;
  import org.flixel.FlxGroup;
  import org.flixel.FlxPoint;
  import org.flixel.FlxRect;
  import org.flixel.FlxSprite;
  import org.flixel.FlxU;

  // A gradient of bg and scroll factors based on coefficients.
  // We're extending FlxGroup b/c there's nothing else. ArrayList would
  // be better.

  public class Background extends FlxGroup
  {

    // Main knobs.
    public var parallaxFactor:Number;
    public var parallaxBuffer:Number;
    public var parallaxTolerance:Number;

    // To work with our foreground.
    public var bounds:FlxRect;

    public var mode:uint;
    // Images are only partial, and clip the transparent leftovers.
    public static const CLIP_BGS:uint = 1;
    // Each image is the since of the full original.
    public static const FULL_BGS:uint = 2;

    public function Background(MaxSize:uint=0)
    {
      this.bounds = new FlxRect();
      this.parallaxFactor = 0.9; // This IS a background, after all.
      this.parallaxBuffer = 2.0;
      this.mode = FULL_BGS;
      super(MaxSize);
    }

    public function addImage(image:Class):void
    {
      var layer:FlxSprite = new FlxSprite(0, 0, image);
      this.add(layer);
    }

    // Apply the scroll factors using a simple algorithm:
    // - Exponential distance (and scroll factor).
    // - Apply a factor to that to increase, as well as a buffer to decrease.
    // Also set the bounds on the entire group, based on the nearest (last) layer.
    public function layout():void
    {
      var nearest:FlxSprite = this.members[this.length-1];
      var farthest:FlxSprite = this.members[0];
      this.bounds.width = nearest.width;
      var n:Number, shift:Number;
      var i:uint = 0; // Assume we added the bottom layers first.
      for each (var bg:FlxSprite in this.members)
      {
        // TODO - Test.
        if (this.mode == CLIP_BGS)
        {
          this.bounds.height += bg.frameHeight;
        }
        // Factor in exponentially and constrain.
        n = Math.pow(i/this.length, 2) * this.parallaxFactor;
        // Add buffer to further constrain.
        n = (n + this.parallaxBuffer/2.0) / this.parallaxBuffer;
        // Shift based on scroll factor for full bg visibility.
        if (i != this.length-1)
        {
          bg.y -= bg.height * (1 - n) - this.parallaxTolerance;
        }
        // Set scroll factor.
        bg.scrollFactor = new FlxPoint(n, n);
        // Set shift.
        if (i == 0)
        {
          shift = -farthest.y;
        }
        bg.y += shift;
        i++;
      }
      if (this.mode == FULL_BGS)
      {
        // TODO - Remove the need for this magical-number hack.
        nearest.y += 12;
        this.bounds.height = shift + nearest.height / Math.pow(this.parallaxFactor, 0.32);
      }
    }

  }
}