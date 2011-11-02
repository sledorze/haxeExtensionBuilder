package ;

/**
 * ...
 * @author sledorze
 */

import StaggedTestMacros; 
 
class StaggedTest {

  public static function compilationTest() {
    
    var i;
    StaggedTestMacros.forExample2(i = 0, i < 10, i++, trace(i));
    
    trace("final i " + i);
    
    var res = StaggedTestMacros.testMeta(function (x : Int) { return x + 1; } );
    
    trace("res " + res());
  }
  
}