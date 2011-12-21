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

  
  static function cpy<T>(x : T) : T {
   return
    switch (Type.typeof(x)) {
      case TNull: x;
	    case TInt: x;
	    case TFloat: x;
	    case TBool : x;
    case TObject :
        var obj : T = untyped { };
        untyped  obj.index = x.index;
        for (f in Reflect.fields(x)) {         
          Reflect.setField(obj, f, cpy(Reflect.field(x, f)));
        }
        obj;        
      case TFunction: x;
      case TClass( c ):
        if (Std.is(x, Array)) {
          var arr : Array<Dynamic> = untyped x;
          var res : Array<Dynamic> = arr.map(cpy).array();
          untyped res;
        } else {
          var obj : T = Type.createEmptyInstance(c);
          for (f in Reflect.fields(x)) {
            Reflect.setField(obj, f, cpy(Reflect.field(x, f)));
          }
          obj;          
        }
    	case TEnum( e  ):
        Type.createEnumIndex(e, Type.enumIndex(x), Type.enumParameters(x).map(cpy).array());
      case TUnknown:
        x;

    }
  }

  @:macro public static function forExample2(init : Expr, cond : Expr, inc : Expr, body : Expr, nb : Int = 5) : Expr return {
    var curPos = Context.currentPos();
    var c = 12;
    var arr = [];
    
    [0, 1, 2, 3].map(function (ind) {

      c -= 1;
      var xxx = "yop" + ind + c;
      var indExpr = Staged.staged2( { $ind; } );
      
      arr.push(
        Staged.staged2({
          trace('wow ' + $c + " " + $xxx + " " + $_indExpr);
        })
      );
      
    });
    
    return { expr : EBlock(arr), pos : Context.currentPos() };
  }

  
  @:macro public static function forExample2Orig(init : Expr, cond : Expr, inc : Expr, body : Expr, nb : Int = 5) : Expr return {
    
    var arr = [];
    for (ind in 0...5) {
      
      var localExpr =
        "{
          trace('wow' + $ind);
        }".staged();
      
      var iInd = "$ind".staged();
        
      arr.push(
        "{
          trace('i ' + $iInd);
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
    
    var res = { expr : EBlock(arr), pos : Context.currentPos() };
    
    for (a in  arr) {
      trace("Length " + a);
    }
    
    return res;
  }

}