package
{
  import org.flixel.FlxG;
  import org.flixel.FlxSprite;
  import org.flixel.FlxState;
  import org.flixel.FlxU;

  public class MenuState extends FlxState
  {
    [Embed(source="data/cursor.png")] protected var ImgCursor:Class;
    [Embed(source="data/bg-start.jpg")] protected var ImgStart:Class;

    private var title:Text;
    private var instructions:Text;
    private var start:Button;
    private var bg:FlxSprite;

    override public function create():void
    {
      // Globals.
      FlxG.mouse.show(ImgCursor);
      
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
      start.label.font = 'Museo700';
      start.label.color = 0xffffffff;
      
      bg = new FlxSprite(0, 0, ImgStart); 
      
      add(bg);
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
