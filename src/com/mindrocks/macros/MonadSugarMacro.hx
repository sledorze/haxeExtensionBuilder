package com.mindrocks.macros;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Tools;

using Lambda;

using com.mindrocks.macros.Staged;
import com.mindrocks.macros.Staged;

using PreludeExtensions;
// using haxe.data.collections.ArrayExtensions;

// Introduire des rewrite rules

import com.mindrocks.functional.Functional;

/**
 * ...
 * @author sledorze
 */
class OptionM {
  
  static function optimize(m : MonadOp, position : Position) : MonadOp {
    function mk(e : ExprDef) return { pos : position, expr : e };
    switch(m) {
      case MFlatMap(e, bindName, body):
        var body = optimize(body, position);
        var e = optimize(e, position);
        
        switch (e) {
          case MCall(name, params):
            switch (name) {
              case "ret": return optimize(MFuncApp(bindName, body, MExp(params[0])), position);
              default :
            }            
          default:
            switch (body) {
              case MCall(name, params):
                switch (name) {
                  case "ret": return optimize(MMap(e, bindName, MExp(params[0])), position);
                  default :
                }
              default:
            }
        }
        
        return MFlatMap(e, bindName, body);
        
      default:
        return m;
    }
  }
  
  @:macro public static function Do(body : Expr) return
    Monad.Do("OptionM", body, Context, optimize)

  inline public static function ret<T>(x : T) return
    Some(x)
  
  inline public static function map < T, U > (x : Option<T>, f : T -> U) : Option<U> {
    switch (x) {
      case Some(x) : return Some(f(x));
      default : return None;
    }
  }

  inline public static function flatMap<T, U>(x : Option<T>, f : T -> Option<U>) : Option<U> {
    switch (x) {
      case Some(x) :
        var xx = f(x);
        return xx;
      default : return None;
    }
  }
}

class ArrayM {
  @:macro public static function Do(body : Expr) return
    Monad.Do("ArrayM", body, Context, function (x, _) return x)

  inline public static function ret<T>(x : T) return
    [x]
  
  inline public static function flatMap<T, U>(xs : Array<T>, f : T -> Array<U>) : Array<U> {
    var res = [];
    for (x in xs) {
      for (y in f(x)) {
        res.push(y);  
      }      
    }
    return res;
  }  
}

enum MonadOp {
  MExp(e : Expr);
  MFuncApp(paramName : String, body : MonadOp, app : MonadOp);
  MFlatMap(e : MonadOp, bindName : String, body : MonadOp);
  MMap(e : MonadOp, bindName : String, body : MonadOp);
  MCall(name : String, params : Array<Expr>);
}

class Monad {

  public static function Do(monadTypeName : String, body : Expr, context : Dynamic, optimize : MonadOp -> Position -> MonadOp) {
    var position : Position = context.currentPos();
    function mk(e : ExprDef) return { pos : position, expr : e };

    function promoteExpression(e : Expr) : MonadOp {
      switch (e.expr) {        
        case ECall(exp, params) :
          switch (exp.expr) {
            case EConst(const):
              switch (const) {
                case CIdent(name):
                  try {
                    context.typeof(exp);
                  } catch (e : Dynamic) {
                    return MCall(name, params);
                  }
                default:
              }
            default:
          }
        default:
      }
      return MExp(e);
    }
    
    function transform(e : Expr, nexts : Option<MonadOp>) : Option<MonadOp> {
      switch (e.expr) {
        case EBinop(op, l, rightExpr) :
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
                var e = promoteExpression(rightExpr);
                switch (nexts) {                  
                  case Some(next):
                    return Some(MFlatMap(e, name, next));
                  case None :
                    return Some(e);
                }
              }
              
            default :
          }
        
        default:
      }
      return Some(promoteExpression(e));
    }
    
    function materialise(m : MonadOp) : Expr {
      switch (m) {
        case MExp(e) : return e;
        
        case MFlatMap(e, bindName, body) :
          var rest = mk(EReturn(materialise(body)));
          var func = mk(EFunction(null, { args : [ { name : bindName, type : null, opt : false, value : null } ], ret : null, expr : rest, params : [] } ));
          var res = mk(ECall(mk(EField(mk(EConst(CType(monadTypeName))), "flatMap")), [materialise(e), func]));
          return res;
          
        case MMap(e, bindName, body) :
          var rest = mk(EReturn(materialise(body)));
          var func = mk(EFunction(null, { args : [ { name : bindName, type : null, opt : false, value : null } ], ret : null, expr : rest, params : [] } ));
          var res = mk(ECall(mk(EField(mk(EConst(CType(monadTypeName))), "map")), [materialise(e), func]));
          return res;
          
        case MCall(name, params) :
          return mk(ECall(mk(EField(mk(EConst(CType(monadTypeName))), name)), params));

        case MFuncApp(paramName, body, app):
          var bdy = mk(EReturn(materialise(body)));
          var func = mk(EFunction(null, { args : [ { name : paramName, type : null, opt : false, value : null } ], ret : null, expr : bdy, params : [] } ));
          return mk(ECall(func, [materialise(app)]));
      }
    }
    
    switch (body.expr) {
      case EBlock(exprs):
        switch(exprs.foldr(None, transform)) {
          case Some(monad): return materialise(optimize(monad, position));
          case None: return mk(EBlock([]));
        }
        
      default : return body;
    };
  }  
}
