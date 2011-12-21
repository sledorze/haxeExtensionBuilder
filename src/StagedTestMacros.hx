package ;

import com.mindrocks.macros.Staged;
import haxe.util.ObjectExtensions;
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
    var curPos = Context.currentPos();
    var c = 12;
    var arr = [];
    
    [0, 1, 2, 3].map(function (ind) {

      c -= 1;
      var xxx = "yop" + ind + c;
      var indExpr = Staged.exp( { $ind; } );
      
      arr.push(
        Staged.exp({
          trace('wow ' + $c + " " + $xxx + " " + $_indExpr);
        })
      );
      
    });
    
    return { expr : EBlock(arr), pos : Context.currentPos() };
  }

}