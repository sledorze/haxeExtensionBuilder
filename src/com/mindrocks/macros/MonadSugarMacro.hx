package com.mindrocks.macros;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Tools;

using Lambda;

using com.mindrocks.macros.Staged;
import com.mindrocks.macros.Staged;

using PreludeExtensions;
using haxe.data.collections.ArrayExtensions;

/**
 * ...
 * @author sledorze
 */

class D {


  @:macro public static function o(body : Expr) {

    function mk(e : ExprDef) return { pos : Context.currentPos(), expr : e };

    function transform(e : Expr, nexts : Array<Expr>) : Array<Expr> {
      switch (e.expr) {
        case EBinop(op, l, r) :
          switch (op) {
            case OpLte:
              
              var name : String =
                switch (l.expr) {
                  case EConst(c) :
                    switch (c) {
                      case CIdent(name) : name;
                      default : null;
                    }
                  default : null;
                }                  
              
              if (name != null) {              
                
                var rest = mk(EBlock(nexts));
                var func = EFunction(null, { args : [ { name : name, type : null, opt : false, value : null } ], ret : null, expr : "{ return $rest; }".staged(), params : []} );

                return ["{ ($r).flatMap($func); }".staged()];
              }
              
            default :
          }
        default:
      }
      nexts.insert(0, e);
      return nexts; 
    }

    switch (body.expr) {
      case EBlock(exprs): return mk(EBlock(exprs.foldr([], transform)));        
      default : return body;
    };
  }
  
}