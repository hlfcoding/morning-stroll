package
{
  import flash.text.TextField;

  import org.flixel.FlxText;

  public class Text extends FlxText
  {
    public static const BASELINE:uint = 40;
    public static const H1:uint = 32;
    public static const H2:uint = 16;
    
    [Embed(source='data/Museo300-Regular.otf', fontFamily='Museo300', embedAsCFF='false')]private static var FontLight:Class;
    [Embed(source='data/Museo500-Regular.otf', fontFamily='Museo500', embedAsCFF='false')]private static var FontMedium:Class;
    [Embed(source='data/Museo700-Regular.otf', fontFamily='Museo700', embedAsCFF='false')]private static var FontHeavy:Class;

    public function Text(X:Number, Y:Number, Width:uint, Text:String=null, Size:uint=H2, EmbeddedFont:Boolean=true)
    {
      super(X, Y, Width, Text, EmbeddedFont);
      this.alignment = 'center';
      this.size = Size;
      if (this.size == H2)
      {
        this.font = 'Museo500';
      }
      else
      {
        this.font = 'Museo300';
      }
    }

    public function getTextField():TextField
    {
      return this._textField;
    }

  }
}