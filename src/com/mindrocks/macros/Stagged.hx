package com.mindrocks.macros;

/**
 * ...
 * @author sledorze
 */
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using Std;

class Stagged {

  static function extractLookup(b : Expr) : Array<{ field : String, expr : Expr }> return {
    switch(b.expr) {
      case EObjectDecl(fields): fields;
      default : throw ("shouldn't happened - lookup expression " + Std.string(b.expr));
    }
  }
  
  static function substitueSeveral(src : Array<Expr>, subs : Array<{field : String, expr : Expr }>) {
    for (exp in src) {
      substitueExp(exp, subs);
    }
  }

  static function substitueTypeParam(tp : TypeParam, subs : Array<{field : String, expr : Expr }>) {
    switch (tp) {
      case TPType( ct ) : substitueComplexType(ct, subs);
	    case TPExpr( e ) : substitueExp(e, subs);
    }
  }

  static function substitueTypePath(tp : TypePath, subs : Array<{field : String, expr : Expr }>) {
    for (param in tp.params) {
      substitueTypeParam(param, subs);
    }
  }

  static function substitueFunc(func : Function, subs : Array<{field : String, expr : Expr }>) {
    for (arg in func.args) {      
      substitueComplexType(arg.type, subs);
      substitueExp(arg.value, subs);
    }
    substitueExp(func.expr, subs);
    for (param in func.params) {
      for (constraint in param.constraints) {
        substitueComplexType(constraint, subs);
      }
    }
  }
  
  static function substitueField(field : Field, subs : Array<{field : String, expr : Expr }>) {
    switch (field.kind) {
      case FVar(ct, e):
        substitueComplexType(ct, subs);
        substitueExp(e, subs);
      case FProp(get, set, t, e):
        substitueComplexType(t, subs);
        substitueExp(e, subs);
      case FFun(f):
        substitueExp(f.expr, subs);
        for (funArg in f.args) {
          substitueComplexType(funArg.type, subs);
          substitueExp(funArg.value, subs);
        }
        for (param in f.params) {
          for (constraint in param.constraints) {
            substitueComplexType(constraint, subs);
          }
        }
    }    
  }

  static function substitueComplexType(ct : ComplexType, subs : Array<{field : String, expr : Expr }>) {
    switch (ct) {
      case TPath(tp): substitueTypePath(tp, subs);
      case TParent(t): substitueComplexType(t, subs);
      case TFunction(args, ret):
        for (arg in args) {
          substitueComplexType(arg, subs);
        }
        substitueComplexType(ret, subs);
      case TExtend(tp, fields):
        substitueTypePath(tp, subs);
        for (field in fields) {
          substitueField(field, subs);
        }
      case TAnonymous(fields):
        for (field in fields) {
          substitueField(field, subs);
        }
    }
  }
  
  static function substitueExp(src : Expr, subs : Array<{field : String, expr : Expr }>) {
    if (src == null) return;
    switch (src.expr) {
      case EConst( c ):
        switch (c) {
          case CIdent( identName ):
            for (sub in subs) {
              if (sub.field == identName) {
                src.expr = sub.expr.expr;
                break;
              }
            }
          default:
        }
      case EArray( e1, e2) : substitueExp(e1, subs); substitueExp(e2, subs);
      case EBinop( op, e1, e2) : substitueExp(e1, subs); substitueExp(e2, subs);
      case EField( e, field) : substitueExp(e, subs);
      case EType( e, field) :  substitueExp(e, subs);
      case EParenthesis( e ) :  substitueExp(e, subs);
      case EObjectDecl( fields) :
        for (field in fields)
        substitueExp(field.expr, subs);
      case EArrayDecl( values) : substitueSeveral(values, subs);
      case ECall( e, params) :  substitueExp(e, subs); substitueSeveral(params, subs);
      case ENew( t, params) : substitueSeveral(params, subs);
      case EUnop( op, postFix, e ) : substitueExp(e, subs); 
      case EVars( vars):
        for (vr in vars) {
          substitueExp(vr.expr, subs); 
        }
      case EFunction( name, f) : substitueFunc(f, subs);        
      case EBlock( exprs) : substitueSeveral(exprs, subs);
      case EFor( it, expr):  substitueExp(it, subs); substitueExp(expr, subs); 
      case EIn( e1, e2) : substitueExp(e1, subs); substitueExp(e2, subs);
      case EIf( econd, eif, eelse): substitueExp(econd, subs); substitueExp(eif, subs); substitueExp(eelse, subs);
      case EWhile( econd, e, normalWhile): substitueExp(econd, subs); substitueExp(e, subs);
      case ESwitch( e, cases, edef):
        substitueExp(e, subs); 
        for (cas in cases) {
          substitueExp(cas.expr, subs); 
        }        
        substitueExp(edef, subs); 
      case ETry( e, catches):
        substitueExp(e, subs); 
        for (cat in catches) {
          substitueExp(cat.expr, subs); 
        }        
      case EReturn(e):
        substitueExp(e, subs); 
      case EBreak:
      case EContinue:
      case EUntyped( e):
        substitueExp(e, subs); 
      case EThrow( e):
        substitueExp(e, subs); 
      case ECast( e, t):
        substitueExp(e, subs);
        substitueComplexType(t, subs);
      case EDisplay( e, isCall):
        substitueExp(e, subs);
      case EDisplayNew(t): //: TypePath 
        substitueTypePath(t, subs);

      case ETernary( econd, eif, eelse):
        substitueExp(econd, subs);
        substitueExp(eif, subs);
        substitueExp(eelse, subs);
      case ECheckType( e, t):
        substitueExp(e, subs);
        substitueComplexType(t, subs);
    }
  }
  /*
  @:macro public static function subs(exp : Expr, nameToExpressions : Expr) : Expr {
    substitueExp(exp, extractLookup(nameToExpressions));
    return exp;
  }
  */
  
  private static var mapping : Array<Dynamic> = [];
  private static var staggedRes : Array<Expr> = [];
  
  public static function setMappings(m : Dynamic) {
    mapping.push(m);
  }
  public static function getMappings() : Dynamic {
    return mapping.pop();
  }

  public static function set(m : Expr) {
    staggedRes.push(m);
  }
  public static function get() : Expr {
    return staggedRes.pop();
  }

  @:macro public static function make(exp : Expr) : Expr {
    var arr = [];
    var mapping = getMappings();
    for (field in Reflect.fields(mapping)) {
      arr.push( { field : field, expr : untyped Reflect.field(mapping, field) } );
    }
    substitueExp(exp, arr);
    set(exp);
    return { expr : EBlock([]), pos : exp.pos};
  }

  @:macro public static function stagged(code : String) : Expr {
    var r : EReg = ~/%[a-zA-Z0-9_-]+/;
    var identifiers = [];
    var newCode = 
      r.customReplace(code, function (reg) {
        var ident = reg.matched(0).substr(1);      
        identifiers.push(ident);
        return ident;
      });
    var mappings = "Stagged.setMappings({ " + identifiers.map(function (str) return str + " : " + str).join(", ") + " });";
    var staggedCall = "{" + mappings + "Stagged.make( " + newCode + "); return Stagged.get(); }";
    return Context.parse(staggedCall, Context.currentPos());
  }
  
}
