package ;

/**
 * ...
 * @author sledorze
 */

import com.mindrocks.functional.monads.Standard;
using com.mindrocks.functional.monads.Standard;

class MonadTest {

  public static function foo() {
    
  }
  
  public static function compilationTest() {
    
    var res =
      OptionM.Do({
        value <= ret(55);
        value1 <= ret(value * 2);        
        x <= ret(value1 + value);
        ret(x);
      });
      
    var res2 = 
      ArrayM.Do({
        a <= [0, 1, 2];
        b <= [10, 20, 30];
        c <= ret(1000);
        [a + b + c];
      });
      
    var res3 =
      StateM.Do({
        passedState <= gets();
        puts("2");
        state <= gets();
        ret('passed state: '+passedState+' new state: '+state);
      }).runState("1");
      
    trace("result " + Std.string(res));
    trace("result2 " + Std.string(res2)); // MonadTest.hx:41: result2 [10,20,30,11,21,31,12,22,32]
    trace("result3 " + Std.string(res3)); // MonadTest.hx:41: result2 [10,20,30,11,21,31,12,22,32]
  }  
}
