package
{

  import flash.text.TextField;

  import org.flixel.FlxG;
  import org.flixel.FlxGame;
  import org.flixel.FlxU;

  [SWF(width=416, height=600, backgroundColor="#000000")]
  [Frame(factoryClass="Preloader")]

  // Custom FlxGame extensions.

  public class MorningStroll extends FlxGame
  {

    public function MorningStroll()
    {
      super(416, 600, MenuState, 1, 24, 24);
    }

    override protected function createFocusScreen():void
    {
      // Draw transparent black backdrop.
      // From Flixel.
      this._focus.graphics.moveTo(0, 0);
      this._focus.graphics.beginFill(0, 0.8);
      this._focus.graphics.lineTo(FlxG.width, 0);
      this._focus.graphics.lineTo(FlxG.width, FlxG.height);
      this._focus.graphics.lineTo(0, FlxG.height);
      this._focus.graphics.lineTo(0, 0);
      this._focus.graphics.endFill();

      var pauseTitle:TextField = new Text(0, 0, FlxG.width,
        "Paused", Text.H1).getTextField();
      var instructions:TextField = new Text(0, 0, FlxG.width, [
        "Arrow keys to move",
        "Press Q to quit",
        "Press 0, -, + for volume"
      ].join("\n\n")).getTextField();

      pauseTitle.y = Text.BASELINE * 6;
      instructions.y = pauseTitle.y + Text.BASELINE * 2;

      this._focus.addChild(pauseTitle);
      this._focus.addChild(instructions);

      addChild(this._focus);

    }

    public static function endGame():void
    {
      FlxG.fade(0xff000000, 1, function():void {
        FlxG.resetGame();
      });
    }

  }
}
