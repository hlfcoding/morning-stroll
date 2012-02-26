package
{
  
  import org.flixel.*;
  [SWF(width=412, height=600, backgroundColor="#000000")]
  [Frame(factoryClass="Preloader")]
  
  public class MorningStroll extends FlxGame
  {
    public function MorningStroll()
    {
      super(412, 600, MenuState, 1, 24, 24);
    }
  }
}
