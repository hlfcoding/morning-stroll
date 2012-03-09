package
{
  import org.flixel.FlxG;
  import org.flixel.FlxRect;
  import org.flixel.FlxState;
  import org.flixel.FlxText;
  import org.flixel.FlxU;
  
  public class MenuState extends FlxState
  {
    [Embed(source="data/cursor.png")] protected var ImgCursor:Class;
    
    private var title:FlxText;
    private var instructions:FlxText;
    private var start:Button;
    
    override public function create():void
    {
      FlxG.mouse.show(ImgCursor, 0.5);
      
      // This is very archaic layout logic, having come from the DOM.
      var padding:Number = 36; 
      var bounds:FlxRect = new FlxRect(
          padding, padding, FlxG.width - padding * 2, FlxG.height - padding * 2);
      var h1:Number = 32;
      var h2:Number = 16;
      
      title = new FlxText(
        bounds.x, 
        bounds.y + padding * 6, 
        bounds.width,
        "Morning Stroll"
      );
      instructions = new FlxText(
        bounds.x, 
        title.y + h1 + padding, 
        bounds.width,
        "Climb and see!"
      );
      start = new Button(
        0, // see below
        instructions.y + h2 + padding,
        "Start",
        h2,
        function():void { FlxG.switchState(new PlayState()); }
      );

      instructions.alignment = title.alignment = "center"; 

      title.size = h1;
      instructions.size = h2;
      
      start.x = (FlxG.width - start.width) / 2;
      
      add(title);
      add(instructions);
      add(start);
    }
    
    override public function update():void
    {
      super.update();
      
    }
    
  }
}
