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
    public var parallax_factor:Number;
    public var parallax_buffer:Number;

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
      this.parallax_factor = 0.9; // This IS a background, after all.
      this.parallax_buffer = 2.0;
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
    public function layout():void
    {
      this.bounds.width = FlxSprite(this.members[0]).width;
      var n:Number;
      var i:uint = 0; // Assume we added the bottom layers first.
      for each (var bg:FlxSprite in this.members)
      {
        if (this.mode == CLIP_BGS)
        {
          this.bounds.height += bg.frameHeight;
        }
        n = Math.pow(i/this.length, 2) * this.parallax_factor;
        n = (n + this.parallax_buffer/2.0) / this.parallax_buffer;
        bg.scrollFactor = new FlxPoint(n, n);
        i++;
      }
      if (this.mode == FULL_BGS)
      {
        this.bounds.height = FlxSprite(this.members[0]).height;
      }
    }

  }
}