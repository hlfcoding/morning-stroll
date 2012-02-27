package
{
  
  import org.flixel.*;
  [SWF(width=416, height=600, backgroundColor="#000000")]
  [Frame(factoryClass="Preloader")]
  
  public class MorningStroll extends FlxGame
  {
    public function MorningStroll()
    {
      super(416, 600, MenuState, 1, 24, 24);
    }
  }
}
