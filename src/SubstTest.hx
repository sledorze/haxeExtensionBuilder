package ;

/**
 * ...
 * @author sledorze
 */

 import com.mindrocks.macros.SubstMacro;
 using com.mindrocks.macros.SubstMacro;
 import haxe.macro.Context;
 
 
class SubstTest {
  /*
        function () {
          trace('a ' + Std.string(mumumu));
          return mumumu; 
        }
        */
  public static function compilationTest() {
    
    trace("DotIT");
    /*
    var res =
      MetaMacro.moo(
        "function () {
          trace('a ' + Std.string(mumumu));
          return mumumu;
        }", {
          mumumu : 53  
        }
      );
      */
    function myExpression(x) return x + 1;

    var res =
      SubstMacro.subs(
        function () {
          return _myExpression(1);
        }, {
          _myExpression : myExpression
        }
      );

//    var res =
//      MetaMacro.mk();
    
//    SubstMacro.for2(i = 10, i < 10, i++, trace(i));
    SubstMacro.for3(function myExpression(x) return x + 1);
    
//    trace("result " + res());

    return null;
  }
  
}