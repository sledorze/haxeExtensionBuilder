package ;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.functional.Functional;

using com.mindrocks.functional.Functional;

import com.mindrocks.macros.MonadSugarMacro;
using com.mindrocks.macros.MonadSugarMacro;
 
class MonadTest {

  
  public static function compilationTest() {
    
    var res =
      D.o({
        value <= Some(55);
        trace("value " + value);
        value <= Some(value * 2);
        trace("value " + value);
        Some(value + 5);
      }); 
    
    trace("result " + Std.string(res));
  }
  
} 