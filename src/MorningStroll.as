package
{
  
  import org.flixel.*;
  [SWF(width=300, height=500, backgroundColor="#000000")]
  [Frame(factoryClass="Preloader")]
  
  public class MorningStroll extends FlxGame
  {
    public function MorningStroll()
    {
      super(300, 500, MenuState, 1, 20, 20);
    }
  }
}
