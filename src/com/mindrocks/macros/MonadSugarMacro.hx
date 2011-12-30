package com.mindrocks.macros;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;

import com.mindrocks.functional.Functional;

/**
 * ...
 * @author sledorze
 */

 /**
  * AST used for transformations (includes optimizations).
  */
enum MonadOp {
  MExp(e : Expr);
  MFuncApp(paramName : String, body : MonadOp, app : MonadOp);
  MFlatMap(e : MonadOp, bindName : String, body : MonadOp);
  MMap(e : MonadOp, bindName : String, body : MonadOp);
  MCall(name : String, params : Array<Expr>);
}

class Monad {

  public static function Do(monadTypeName : String, body : Expr, context : Dynamic, optimize : MonadOp -> Position -> MonadOp) {
    var monadProxyName = monadTypeName + "__mnd";
    var monadRef = EConst(CIdent(monadProxyName));
    var position : Position = context.currentPos();
    function mk(e : ExprDef) return { pos : position, expr : e };

    function tryPromoteExpression(e : Expr) : MonadOp {
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
    
    function transform(e : Expr, nextOpt : Option<MonadOp>) : Option<MonadOp> {
      
      function flatMapThis(e : MonadOp, name : String) {
        switch (nextOpt) {
          case Some(next):
            return MFlatMap(e, name, next);
          case None :
            return e;
        }
      }
      
      switch (e.expr) {
        case EBinop(op, l, rightExpr) :
          switch (op) {
            case OpLte:              
              switch (l.expr) {
                case EConst(c) :
                  switch (c) {
                    case CIdent(name) :
                      var e = tryPromoteExpression(rightExpr);
                      return Some(flatMapThis(e, name));
                    default :
                  }
                default :
              }                  
            default :
          }        
        default:
      }      
      var res = {
        var e = tryPromoteExpression(e);        
        switch (e) {
          case MExp(_): e;
          default: flatMapThis(e, "_");
        };
      }
      return Some(res);
    }
    
    function toExpr(m : MonadOp) : Expr {
      switch (m) {
        case MExp(e) : return e;
        
        case MFlatMap(e, bindName, body) :
          var rest = mk(EReturn(toExpr(body)));
          var func = mk(EFunction(null, { args : [ { name : bindName, type : null, opt : false, value : null } ], ret : null, expr : rest, params : [] } ));
          var res = mk(ECall(mk(EField(mk(monadRef), "flatMap")), [toExpr(e), func]));
          return res;
          
        case MMap(e, bindName, body) :
          var rest = mk(EReturn(toExpr(body)));
          var func = mk(EFunction(null, { args : [ { name : bindName, type : null, opt : false, value : null } ], ret : null, expr : rest, params : [] } ));
          var res = mk(ECall(mk(EField(mk(monadRef), "map")), [toExpr(e), func]));
          return res;
          
        case MCall(name, params) :
          return mk(ECall(mk(EField(mk(monadRef), name)), params));

        case MFuncApp(paramName, body, app):
          var body = mk(EReturn(toExpr(body)));
          var func = mk(EFunction(null, { args : [ { name : paramName, type : null, opt : false, value : null } ], ret : null, expr : body, params : [] } ));
          return mk(ECall(func, [toExpr(app)]));
      }
    }
    
    switch (body.expr) {
      case EBlock(exprs):
        exprs.reverse();
        switch(exprs.fold(transform, None)) {
          case Some(monad):
            return 
              mk(EBlock([
                mk(EVars([{name: monadProxyName, expr : mk(EConst(CType(monadTypeName))), type : null }])), // add a var proxy
                toExpr(optimize(monad, position))
              ]));
            
          default:
        }
      default :
    };
    return body;
  }  
}
