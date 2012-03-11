package
{
  import flash.text.TextField;

  import org.flixel.FlxText;

  public class Text extends FlxText
  {
    public static const BASELINE:uint = 40;
    public static const H1:uint = 32;
    public static const H2:uint = 16;

    public function Text(X:Number, Y:Number, Width:uint, Text:String=null, Size:uint=H2, EmbeddedFont:Boolean=true)
    {
      super(X, Y, Width, Text, EmbeddedFont);
      this.alignment = "center";
      this.size = Size;
    }

    public function getTextField():TextField
    {
      return this._textField;
    }

  }
}