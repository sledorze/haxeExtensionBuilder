package com.mindrocks.macros;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Tools;

using Lambda;

using com.mindrocks.macros.Staged;
import com.mindrocks.macros.Staged;

using PreludeExtensions;
// using haxe.data.collections.ArrayExtensions;

// Introduire des rewrite rules (d'abord abstraire les transfos (mini AST pour separer la detection de la transformation)

import com.mindrocks.functional.Functional;

/**
 * ...
 * @author sledorze
 */
class OptionM {
  @:macro public static function Do(body : Expr) return
    Monad.Do("OptionM", body, Context)

  inline public static function ret<T>(x : T) return
    Some(x)
  
  inline public static function flatMap<T>(x : Option<T>, f : T -> Option<T>) : Option<T> {
    switch (x) {
      case Some(x) : return f(x);
      default : return None;
    }
  }
}

class ArrayM {
  @:macro public static function Do(body : Expr) return
    Monad.Do("ArrayM", body, Context)

  inline public static function ret<T>(x : T) return
    [x]
  
  inline public static function flatMap<T>(xs : Array<T>, f : T -> Array<T>) : Array<T> {
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
  MBind(e : MonadOp, bindName : String, body : MonadOp);
  MCall(name : String, params : Array<Expr>);
}

class Monad {

  public static function Do(monadTypeName : String, body : Expr, context : Dynamic) {
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
                    return Some(MBind(e, name, next));
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
        case MBind(e, bindName, body) :
          var exprs = materialise(body);
          var rest : Expr = mk(EReturn(exprs));
          var func = mk(EFunction(null, { args : [ { name : bindName, type : null, opt : false, value : null } ], ret : null, expr : rest, params : [] } ));
          var res = mk(ECall(mk(EField(mk(EConst(CType(monadTypeName))), "flatMap")), [materialise(e), func]));
          return res;
        case MCall(name, params) :
          var res = mk(ECall(mk(EField(mk(EConst(CType(monadTypeName))), name)), params));
          return res;
      }
    }
    
    switch (body.expr) {
      case EBlock(exprs):
        switch(exprs.foldr(None, transform)) {
          case Some(monad): return materialise(monad);
          case None: return mk(EBlock([]));
        }
        
      default : return body;
    };
  }
  
}

/*
class Monad {

  public static function Do<Q>(monadTypeName : String, body : Expr, context : Dynamic) {
    var position : Position = context.currentPos();
    function mk(e : ExprDef) return { pos : position, expr : e };

    function promoteExpression(e : Expr) : Expr {
      switch (e.expr) {        
        case ECall(exp, params) :
          switch (exp.expr) {
            case EConst(const):
              switch (const) {
                case CIdent(name):
                  try {
                    context.typeof(exp);
                  } catch (e : Dynamic) { // change this to a call from the Monad object.                     
                    return mk(ECall(mk(EField(mk(EConst(CType(monadTypeName))), name)), params));
                  }
                default:
              }
            default:
          }
        default:
      }
      return e;
    }
    
    function transform(e : Expr, nexts : Array<Expr>) : Array<Expr> {      
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
                
                var rest : Expr = mk(EReturn(mk(EBlock(nexts))));
                var func = mk(EFunction(null, { args : [ { name : name, type : null, opt : false, value : null } ], ret : null, expr : rest, params : [] } ));
                
                var res = mk(ECall(mk(EField(mk(EConst(CType(monadTypeName))), "flatMap")), [promoteExpression(rightExpr), func]));
                
//                var res = mk(ECall(mk(EField(promoteExpression(rightExpr), "flatMap")), [func]));
                
                return [res];
              }
              
            default :
          }
        
        default:
      }
      nexts.insert(0, promoteExpression(e));
      return nexts; 
    }
    
    switch (body.expr) {
      case EBlock(exprs): return mk(EBlock(exprs.foldr([], transform)));
      default : return body;
    };
  }
  
}
 * */