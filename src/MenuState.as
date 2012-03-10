package
{
  import org.flixel.FlxG;
  import org.flixel.FlxState;
  import org.flixel.FlxU;
  
  public class MenuState extends FlxState
  {
    [Embed(source="data/cursor.png")] protected var ImgCursor:Class;
    
    private var title:Text;
    private var instructions:Text;
    private var start:Button;
    
    override public function create():void
    {
      FlxG.mouse.show(ImgCursor, 0.5);
      
      // Layout.
      title = new Text(0, Text.BASELINE * 6, FlxG.width,
        "Morning Stroll", Text.H1);
      instructions = new Text(0, title.y + Text.BASELINE * 2, FlxG.width,
        "Climb and see!");
      start = new Button(0, // see below
        instructions.y + Text.BASELINE * 2, "Start", Text.H2,
        function():void {
          FlxG.fade(0xff000000, 1, function():void {
            FlxG.switchState(new PlayState());
          });
        });
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
