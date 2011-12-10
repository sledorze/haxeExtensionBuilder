package ;

import com.mindrocks.macros.Staged;
using com.mindrocks.macros.Staged;
import haxe.macro.Expr;
import haxe.macro.Context;

using Lambda;


/**
 * ...
 * @author sledorze
 */

class StagedTestMacros {

  @:macro public static function forExample2(init : Expr, cond : Expr, inc : Expr, body : Expr, nb : Int = 5) : Expr return {
    
    var arr = [];
    for (ind in 0...5) {
      
      var localExpr =
        "{
          trace('wow' + $ind);
        }".staged();
        
      arr.push(
        "{
          trace('i ' + $ind);
          $localExpr;
          $init;
          
          function oneTime() {
            if ($cond) {
              $body;
              $inc;
              oneTime();
            }
          }
          oneTime();
        }".staged()
      );
    }
    
    return { expr : EBlock(arr), pos : Context.currentPos() };
  }
  
}