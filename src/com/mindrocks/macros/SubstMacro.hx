package com.mindrocks.macros;

/**
 * ...
 * @author sledorze
 */
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using Std;

class SubstMacro {

  static function extractLookup(b : Expr) : Array<{ field : String, expr : Expr }> {
    switch(b.expr) {
      case EObjectDecl(fields):
        for (field in fields) {
          trace("Field " + Std.string(field));
        }
        return fields;
      default : throw "not supported";
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
  
  @:macro public static function subs(exp : Expr, nameToExpressions : Expr) : Expr {
    trace("Dynamic " + Std.string(nameToExpressions));
    substitueIn(exp, extractLookup(nameToExpressions));
    return exp;
  }
  
  @:macro public static function for3(init : Expr) : Expr {
    
    return subs({
      function () {
        return init(1);
      }
    }, { _m_init : init } );
    
  }    
  
  @:macro public static function for2(init : Expr, cond : Expr, body : Expr, change : Expr) : Expr {
    
    // "{$init; function loop () { if ($cond) { $body; $change; loop() } }; loop (); }"
    return subs({
      var i;
      _m_init;
      function loop () {
        if (_m_cond) {
          _m_body;
          _m_change;
          loop();
        }
      };
      loop ();
    }, { _m_init : init, _m_cond : cond, _m_body : body, _m_change : change } );
    
// a = StringTools.replace(a, "$myExpression", "_m_myExpression");    
//    return Context.parse("com.mindrocks.macros.MetaMacro.moo("+a+", { _m_myExpression : myExpression })", Context.currentPos());
//    return subs(Context.parse(a, Context.currentPos()), { _m_init : init, _m_cond : cond, _m_body : body, _m_change : change } );
/*    return Context.parse(
      "com.mindrocks.macros.SubstMacro.subs(" + a + ", { _m_init : init, _m_cond : cond, _m_body : body, _m_change : change })",
      Context.currentPos()
    );*/
  }
  /*
  @:macro public static function mk(a : String) : Expr {
    a = StringTools.replace(a, "$myExpression", "_m_myExpression"); TODO; implement the substitution..!!
    return Context.parse("com.mindrocks.macros.MetaMacro.subs("+a+", { _m_myExpression : myExpression })", Context.currentPos());
  }
  */
}


/*
   @:macro public static function mk(a : String) : Expr {
    
    a = StringTools.replace(a, "$myExpression", "_m_myExpression");
    
    return Context.parse("com.mindrocks.macros.MetaMacro.subs("+a+", { _m_myExpression : myExpression })", Context.currentPos());
  }
  
  @:macro public static function for2(init : Expr, cond : Expr, body : Expr, change : Expr) : Expr {
    
    // "{$init; function loop () { if ($cond) { $body; $change; loop() } }; loop (); }"
    var a = "{
      var i;
      _m_init;
      function loop () {
        if (_m_cond) {
          _m_body;
          _m_change;
          loop();
        }
      };
      loop ();
    }";
    
    // a = StringTools.replace(a, "$myExpression", "_m_myExpression");
    
//    return Context.parse("com.mindrocks.macros.MetaMacro.moo("+a+", { _m_myExpression : myExpression })", Context.currentPos());
//    return subs(Context.parse(a, Context.currentPos()), { _m_init : init, _m_cond : cond, _m_body : body, _m_change : change } );
    return Context.parse(
      "com.mindrocks.macros.MetaMacro.subs(" + a + ", { _m_init : init, _m_cond : cond, _m_body : body, _m_change : change })",
      Context.currentPos()
    );

//    return Context.parse("com.mindrocks.macros.MetaMacro.moo("+a+", { _m_myExpression : myExpression })", Context.currentPos());
  }
 */