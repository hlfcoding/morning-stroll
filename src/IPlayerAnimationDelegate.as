package
{
  // This allows separating the player movement logic from the player
  // presentation logic. It is important in these methods to only play
  // when the current animation has stopped (when logical), this allows
  // animation precedence, since the delegate methods are called in
  // precedence.
  public interface IPlayerAnimationDelegate
  {
    function playerWillUpdateAnimation():void;
    function playerDidUpdateAnimation():void;
    function playerWillStop():void;
    function playerWillStart():void;
    function playerWillJump():void;
    function playerIsStill():void;
    function playerIsRunning():void;
    function playerIsLanding():void;
    function playerIsRising():void;
    function playerIsFalling():void;
  }
}