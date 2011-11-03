package ;

import com.mindrocks.macros.Stagged;
using com.mindrocks.macros.Stagged;
import haxe.macro.Expr;
import haxe.macro.Context;

using Lambda;


/**
 * ...
 * @author sledorze
 */

class StaggedTestMacros {

  /*
  @:macro public static function testMeta(init : Expr) : Expr {
    Stagged.setMappings({
      init : init
    });
    Stagged.make(
      function () {
        return init(10);
      }
    );
    return Stagged.get();
  }

  @:macro public static function forExample(init : Expr, cond : Expr, inc : Expr, body : Expr) : Expr {
    Stagged.setMappings({
      init : init,
      cond : cond,
      inc : inc,
      body : body
    });
    Stagged.make({
      var i;
      init;
      function oneTime() {
        if (cond) {
          body;
          inc;
          oneTime();
        }
      }
      oneTime();
    });
    return Stagged.get();
  }
*/
  @:macro public static function forExample2(init : Expr, cond : Expr, inc : Expr, body : Expr, nb : Int = 5) : Expr return {
    
    var arr = [];
    for (ind in 0...5) {
      var stagged =
        Stagged.stagged("{
          trace('i ' + $ind);
          $init;
          function oneTime() {
            if ($cond) {
              $body;
              $inc;
              oneTime();
            }
          }
          oneTime();
        }");
      arr.push(stagged);
    }
    
    return { expr : EBlock(arr), pos : Context.currentPos() };
  }
  
}