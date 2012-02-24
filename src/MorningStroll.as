package
{
  
  import org.flixel.*;
  [SWF(width=400, height=600, backgroundColor="#000000")]
  [Frame(factoryClass="Preloader")]
  
  public class MorningStroll extends FlxGame
  {
    public function MorningStroll()
    {
      super(400, 600, MenuState, 1, 20, 20);
    }
  }
}
