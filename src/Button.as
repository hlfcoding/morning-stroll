package
{
  import org.flixel.FlxButton;
  import org.flixel.FlxPoint;
  import org.flixel.FlxSprite;
  import org.flixel.FlxText;
  
  // This actually overrides the default button class.
  // We need a little more customization.
  
  public class Button extends FlxButton
  {
    [Embed(source="data/button.png")] protected var ImgButton:Class;
    
    public function Button(X:Number=0, Y:Number=0, Label:String=null, LabelSize:Number=8, OnClick:Function=null)
    {
      this.x = X;
      this.y = Y;
      
      if (Label != null)
      {
        this.label = new FlxText(0, 0, 160, Label);
        this.label.setFormat(null, LabelSize, 0x333333, "center");
        this.labelOffset = new FlxPoint(-1, LabelSize/2);
      }
      this.loadGraphic(ImgButton, true, false, 160, 40);
      
      this.onUp = OnClick;
      this.onDown = null;
      this.onOut = null;
      this.onOver = null;
      
      this.soundOver = null;
      this.soundOut = null;
      this.soundDown = null;
      this.soundUp = null;
      
      this.status = FlxButton.NORMAL;
      this._onToggle = false;
      this._pressed = false;
      this._initialized = false;
    }
  }
}