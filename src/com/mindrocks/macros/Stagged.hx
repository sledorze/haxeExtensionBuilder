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
      default : throw ("not supported" + Std.string(b.expr));
    }
  }
  
  static function substitueSeveral(src : Array<Expr>, subs : Array<{field : String, expr : Expr }>) {
    for (exp in src) {
      substitueIn(exp, subs);
    }
  }

  static function substitueTP(tp : TypeParam, subs : Array<{field : String, expr : Expr }>) {
    switch (tp) {
      case TPType( ct ) : substitueComplexType(ct, subs);
	    case TPExpr( e ) : substitueIn(e, subs);
    }
  }
  static function substitueFunc(func : Function, subs : Array<{field : String, expr : Expr }>) {
    for (arg in func.args) {      
      substitueComplexType(arg.type, subs);
      substitueIn(arg.value, subs);
    }
    substitueIn(func.expr, subs);
    for (param in func.params) {
      for (constraint in param.constraints) {
        substitueComplexType(constraint, subs);
      }
    }
  }
  static function substitueComplexType(func : ComplexType, subs : Array<{field : String, expr : Expr }>) {
    throw "implement ";
  }
  
  static function substitueIn(src : Expr, subs : Array<{field : String, expr : Expr }>) {
    if (src == null) return;
    switch (src.expr) {
      case EConst( c ):
        switch (c) {
          case CIdent( identName ):
//            trace("Name " + identName);
            var found = subs.filter(function(p) return p.field == identName).first();
            if (found != null) {
//              trace("Substitued");
              src.expr = found.expr.expr; // substitution occurs here.
            }
          default:
        }
      case EArray( e1, e2) : substitueIn(e1, subs); substitueIn(e2, subs);
      case EBinop( op, e1, e2) : substitueIn(e1, subs); substitueIn(e2, subs);
      case EField( e, field) : substitueIn(e, subs);
      case EType( e, field) :  substitueIn(e, subs);
      case EParenthesis( e ) :  substitueIn(e, subs);
      case EObjectDecl( fields) :
        for (field in fields)
        substitueIn(field.expr, subs);
      case EArrayDecl( values) : substitueSeveral(values, subs);
      case ECall( e, params) :  substitueIn(e, subs); substitueSeveral(params, subs);
      case ENew( t, params) : substitueSeveral(params, subs);
      case EUnop( op, postFix, e ) : substitueIn(e, subs); 
      case EVars( vars):
        for (vr in vars) {
          substitueIn(vr.expr, subs); 
        }
      case EFunction( name, f) : substitueFunc(f, subs);        
      case EBlock( exprs) : substitueSeveral(exprs, subs);
      case EFor( it, expr):  substitueIn(it, subs); substitueIn(expr, subs); 
      case EIn( e1, e2) : substitueIn(e1, subs); substitueIn(e2, subs);
      case EIf( econd, eif, eelse): substitueIn(econd, subs); substitueIn(eif, subs); substitueIn(eelse, subs);
      case EWhile( econd, e, normalWhile): substitueIn(econd, subs); substitueIn(e, subs);
      case ESwitch( e, cases, edef):
        substitueIn(e, subs); 
        for (cas in cases) {
          substitueIn(cas.expr, subs); 
        }        
        substitueIn(edef, subs); 
      case ETry( e, catches):
        substitueIn(e, subs); 
        for (cat in catches) {
          substitueIn(cat.expr, subs); 
        }        
      case EReturn(e):
        substitueIn(e, subs); 
      case EBreak:
      case EContinue:
      case EUntyped( e):
        substitueIn(e, subs); 
      case EThrow( e):
        substitueIn(e, subs); 
      case ECast( e, t):
        substitueIn(e, subs);
        substitueComplexType(t, subs);
      case EDisplay( e, isCall):
        substitueIn(e, subs);
      case EDisplayNew( t ): //: TypePath 
        for (param in t.params) {
          substitueTP(param, subs);
        }

      case ETernary( econd, eif, eelse):
        substitueIn(econd, subs);
        substitueIn(eif, subs);
        substitueIn(eelse, subs);
      case ECheckType( e, t):
        substitueIn(e, subs);
        substitueComplexType(t, subs);
    }
  }
  /*
  @:macro public static function subs(exp : Expr, nameToExpressions : Expr) : Expr {
    substitueIn(exp, extractLookup(nameToExpressions));
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
    substitueIn(exp, arr);
    set(exp);
    return { expr : EBlock([]), pos : exp.pos};
  }

  @:macro public static function stagged(code : String) : Expr {    
    var identifiers = ["init", "cond", "inc", "body"];
    var mappings = "Stagged.setMappings({ " + identifiers.map(function (str) return str + " : " + str).join(", ") + " });";
    var newCode = identifiers.fold(function (id, code) return StringTools.replace(code, "$" + id, id), code);
    var c = "{" + mappings + "Stagged.make( " + newCode + "); return Stagged.get(); }";
    trace("out " + c );
    return Context.parse(c, Context.currentPos());
  }
  
}
