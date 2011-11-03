package com.mindrocks.macros;

/**
 * ...
 * @author sledorze
 */
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

#if macro
using Type;
#end
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
  
  static var onIdent : String -> Void;
  static function substitueExp(src : Expr, subs : Array<{field : String, expr : Expr }>) {
    #if macro
    if (src == null) return;
    switch (src.expr) {
      case EConst( c ):
        switch (c) {
          case CIdent( identName ):
            if (onIdent !=null)
              onIdent(identName);
            else {
              if (identName.charAt(0) == '$') {
                var name = identName.substr(1);
                for (sub in subs) {
                  if (sub.field == name) {
                    try {
                      trace("type " + Std.string(sub));                      
//                      trace("has " + vt);
                      var isExpr =
                        switch (sub.expr.typeof()) {
                          case TObject: true; // trace("has2 " + sub.expr.expr);
                          default: false;
                        };
                        
                      //var thizExp = Context.makeExpr(sub.expr, Context.currentPos());
                      //trace("Expr " + Std.string(thizExp));
                      // verifier s'il s'agit d'une expression style Enum de code ou pas.. 
                      
                      if (isExpr) { //untyped expr != 0 && sub.expr!=null && sub.expr.expr != null) { // WOW!
                        src.expr = sub.expr.expr;                        
                      } else {
                        trace("For " + Std.string(sub.expr));
                        var expr = Context.makeExpr(sub.expr, src.pos);
                        trace("done " + Std.string(expr));
                        //var expr = Context.parse(Std.string(sub.expr), Context.currentPos());
                        //trace("built exp " + Std.string(expr));                        
                        src.expr = expr.expr;
                      }
                    } catch (e : Dynamic) {
                      trace("Error " + name + " " + (sub.expr == null) + " " + Std.string(e));
                      trace("Sub.Expr " + Std.string(sub));
                    }
                    break;
                  }
                }              
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
    #end
  }
  /*
  @:macro public static function subs(exp : Expr, nameToExpressions : Expr) : Expr {
    substitueExp(exp, extractLookup(nameToExpressions));
    return exp;
  }
  */
  
  private static var mapping : Array<Dynamic> = [];
  private static var staggedRes : Array<Expr> = [];
  private static var code : Array<Expr> = [];

  public static function setMappings(m : Dynamic) {
    mapping.push(m);
  }
  public static function getMappings() : Dynamic {
    return mapping[mapping.length-1];
    //return mapping.pop();
  }

  public static function set(m : Expr) {
    staggedRes.push(m);
  }
  public static function get() : Expr {
    return staggedRes[staggedRes.length - 1];
    //return staggedRes.pop();
  }

  public static function setCode(m : Expr) {
    code.push(m);
  }
  public static function getCode() : Expr {
    return code[code.length - 1];
//    return code.pop();
  }
  
  static var initialCode : String = "";

  public static var executeNext = true;
  @:macro public static function make(exp : Expr) : Expr {
    trace("Make..");
    onIdent = null;
//    var exp = getCode();
    
    var arr = [];  
    var mapping = getMappings();
    for (field in Reflect.fields(mapping)) {
      arr.push( { field : field, expr : untyped Reflect.field(mapping, field) } );
    }
    
    substitueExp(exp, arr);
    set(exp);
    //return dummy;
    executeNext = false;
    
    // code explosion but it's at generation time, so maybe worst the burden..
    return Context.parse('{if (Stagged.executeNext==true) {
      Stagged.stagged("'+initialCode+'");
    } else { Stagged.executeNext = true; }; } ', Context.currentPos());    
  }
  
  #if macro
  /*
  static function copy(d: Dynamic, shallow: Bool = true): Dynamic {
    var res = { };
    return copyTo(d, res, shallow);
    return res;
  }

  static function copyTyped<T>(d: T, shallow: Bool = true): T {
    var res = { };
    copyTo(d, res, shallow);
    return untyped res;
  }
  
  static function copyTo(src: Dynamic, dest: Dynamic, shallow: Bool = true): Dynamic {
    function safecopy(d: Dynamic): Dynamic
      return switch (d.typeof()) {
        case TObject: copy(d, shallow);
        
        default: d;
      }
    
    for (field in Reflect.fields(src)) {
      var value = Reflect.field(src, field);
      
      Reflect.setField(dest, field, if (shallow) value else safecopy(value));
    }
    
    return src;
  }

  // version without string
  @:macro public static function stagged(_code : Expr) : Expr {
    trace("stagging");
    initialCode = _code;
    var code = copy(_code, false);
    var res = 
      try {
        setCode(code);
        
        var identifiers = [];
        onIdent = function (ident : String) {
          if (ident.charAt(0) == '$') {
            if (!identifiers.has(ident))
              identifiers.push(ident);
          }
        };
        substitueExp(code, []);
        identifiers = identifiers.map(function (name) return name.substr(1)).array(); // remove the leading     
        
        var mappings = "Stagged.setMappings({ " + identifiers.map(function (str) return str + " : " + str).join(", ") + " });";
        var staggedCall = "{" + mappings + "Stagged.make(); var res = Stagged.get(); trace('toto' + Std.string(res)); res; }";
        Context.parse(staggedCall, Context.currentPos());        
      } catch (e : Dynamic) {
        trace("Error stagged " + Std.string(e)); null;
      }
    return res;
  }
  */
  @:macro public static function stagged(code : String) : Expr {
    initialCode = code;

    var r : EReg = ~/\$[a-zA-Z0-9_-]+/;
    var identifiers = [];
    var newCode = 
      r.customReplace(code, function (reg) {
        var ident = reg.matched(0).substr(1);      
        identifiers.push(ident);
        return ident;
      });
    
    var mappings = "Stagged.setMappings({ " + identifiers.map(function (str) return str + " : " + str).join(", ") + " });";
    var staggedCall = "{" + mappings + "Stagged.make( " + code + "); Stagged.get(); }";
    return Context.parse(staggedCall, Context.currentPos());
  }
  #end


}
