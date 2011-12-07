package ;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.functional.Functional;

class OptionIsAMonad {
  public static function return_ <T>(x : T) : Option<T> return Some(x)
  
  public static function bind_  < T, U > (x : Option<T>, f : T -> Option<U>) : Option<U> {
    switch (x) {
      case Some(v) : return f(v);
      case None : return None;
    }
  }
}

import com.mindrocks.macros.MonadSugarMacro;
using com.mindrocks.macros.MonadSugarMacro;
 
class MonadTest {

  public static function compilationTest() {
    
    var res =
      MonadSugarMacro.monad(
        {
          value <= Some(55);
          Some(value + 5);
        },
        OptionIsAMonad
      ); 
      
    trace("result " + Std.string(res));
  }
  
} 