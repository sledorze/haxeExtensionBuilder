package ;

/**
 * ...
 * @author sledorze
 */

import StaggedTestMacros; 
 
class StaggedTest {

  public static function compilationTest() {
    
//    StaggedTestMacros.forExample(i = 0, i < 10, i++, trace("a"+i));
    var res = StaggedTestMacros.forExample2(i = 0, i < 10, i++, trace(i));
    trace("res " + res);
//    var res = StaggedTestMacros.testMeta(function (x : Int) { return x + 1; } );
    
   // trace("res " + res());
  }
  
}