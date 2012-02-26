package
{
  import org.flixel.*;
  
  public class MenuState extends FlxState
  {
    private var title:String;
    private var instructions:String;
    
    override public function create():void
    {
      title = "Morning Stroll";
      instructions = "Don't stop climbing!";
      
      drawTitle();
      drawInstructions();
      
      FlxG.mouse.show();
    }
    
    override public function update():void
    {
      super.update();
      
      if (FlxG.mouse.justPressed()) 
      {
        FlxG.switchState(new PlayState());
      }
    }
    
    private function drawTitle():void
    {
      var t:FlxText = new FlxText(
        0,
        FlxG.height/2-20,
        FlxG.width, 
        this.title
      );
      t.size = 32;
      t.alignment = "center";
      add(t);
    }
    
    private function drawInstructions():void
    {
      var t:FlxText = new FlxText(
        FlxG.width/2-100,
        FlxG.height/2+60,
        200, 
        this.instructions
      );
      t.size = 16;
      t.alignment = "center";
      add(t);
    }
  }
}
