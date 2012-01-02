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

  @:macro public static function for_(init : Expr, cond : Expr, inc : Expr, body : Expr) : Expr {
    var res = 
      Staged.exp({
        $_init;
        function oneLoop() {
          if ($_cond) {
            $_body;
            $_inc;
            oneLoop();
          }
        };
        oneLoop();
      });
    
    return res;
  }
  
  /**
   * Shows you can regenerate the AST on need (not just one time)
   * Use values and local / external Expressions; from various scopes.
   * 
   * @param	nb
   * @return
   */
  @:macro public static function generate(nb : Int = 5) : Expr return {

    var arr = [];

    var outerScope = 12;
    
    function pass(param : Int) {
      outerScope -= 1;
      var localVar =
        "lv " + param + outerScope;
        
      var localExpr =
        Staged.exp({ $param; });
      
      arr.push(
        Staged.exp({
          trace('evidence ' + $outerScope + " " + $localVar + " " + $_localExpr);
        })
      );      
    }
    
    for (ind in 0...nb) 
      pass(ind);
    
    return { expr : EBlock(arr), pos : Context.currentPos() };
  }

}