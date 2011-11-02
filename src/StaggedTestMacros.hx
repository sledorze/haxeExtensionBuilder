package ;

import com.mindrocks.macros.Stagged;
using com.mindrocks.macros.Stagged;
import haxe.macro.Context;
import haxe.macro.Expr;


/**
 * ...
 * @author sledorze
 */

class StaggedTestMacros {

  
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

  @:macro public static function forExample2(init : Expr, cond : Expr, inc : Expr, body : Expr) : Expr return
    "{
      var i;
      $init;
      function oneTime() {
        if ($cond) {
          $body;
          $inc;
          oneTime();
        }
      }
      oneTime();
    }".stagged()
  
}