package ;

/**
 * ...
 * @author sledorze
 */

import Prelude;
using PreludeExtensions;


import com.mindrocks.functional.Functional;
using com.mindrocks.functional.Functional;

import com.mindrocks.macros.MonadSugarMacro;
using com.mindrocks.macros.MonadSugarMacro;
 
class MonadTest {

  
  public static function compilationTest() {
    
    var res =
      D.o({
        value <= Some(55);
        value <= Some(value * 2);
        D.o({
          v <= Some(123);
          Some(v + value);
        });
      }); 
    
    var res2 = 
      D.o({
        a <= [0, 1, 2];
        b <= [10, 20, 30];
        [a + b];
      });
      
    trace("result " + Std.string(res)); // MonadTest.hx:40: result Some(233)
    trace("result2 " + Std.string(res2)); // MonadTest.hx:41: result2 [10,20,30,11,21,31,12,22,32]  }
  
} 