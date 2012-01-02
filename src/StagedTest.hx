package ;

/**
 * ...
 * @author sledorze
 */

import StagedTestMacros; 
 
class StagedTest {

  public static function compilationTest() {
    var i = 1;
    StagedTestMacros.for_(i = 0, i < 10, i++, trace(i));    
    trace("final i " + i);

    StagedTestMacros.generate(10);

  }
  
}