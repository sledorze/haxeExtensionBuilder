package ;

/**
 * ...
 * @author sledorze
 */

import StagedTestMacros; 
 
class StagedTest {

  public static function compilationTest() {
    var i = 1;
    StagedTestMacros.forExample2(i = 0, i < 10, i++, trace(i));
    
    trace("final i " + i);
    
   // var res = StagedTestMacros.testMeta(function (x : Int) { return x + 1; } );
    
   // trace("res " + res());
  }
  
}