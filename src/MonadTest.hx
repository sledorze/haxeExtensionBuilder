package ;

/**
 * ...
 * @author sledorze
 */

// import Prelude;
using PreludeExtensions;

import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

import com.mindrocks.macros.MonadSugarMacro;
using com.mindrocks.macros.MonadSugarMacro;
 
class MonadTest {

  public static function foo() {
    
  }
  
  public static function compilationTest() {
    
    var res =
      OptionM.Do({
        value <= ret(55);
        value <= ret(value * 2);
        OptionM.Do({
          v <= ret(123);
          ret(v + value);
        });
      }); 
    
    var res2 = 
      ArrayM.Do({
        a <= [0, 1, 2];
        b <= [10, 20, 30];
        c <= ret(12);
        [a + b];
      });
      
    trace("result " + Std.string(res)); // MonadTest.hx:40: result Some(233)
//    trace("result2 " + Std.string(res2)); // MonadTest.hx:41: result2 [10,20,30,11,21,31,12,22,32]
  }  
}
